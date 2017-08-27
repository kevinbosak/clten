package CltEn::Manager;

use warnings;
use 5.020;
use Moo;
use Log::Any;
use CltEn::Util qw(:all);
use Data::Dumper;
use JSON;
use Try::Tiny;

has 'schema' => (
    is => 'ro',
);

has 'groupme' => ( # GroupMe object
    is => 'ro',
    required => 0,
);

has 'logger' => (
    is => 'ro',
    default => sub {Log::Any->get_logger },
);

sub add_user_to_group {
    my ($self, $user, $room_id, $groupme_args) = @_;

    $self->logger->debug('Adding user ' . $user->id . " to room $room_id");
    my $access = $user->join_room($room_id);
    return 0 unless $access;

    my $room = $access->room;
    $groupme_args ||= {};
    $groupme_args->{nickname} = build_user_chat_name($user);
    if ($user->groupme_id) {
        $groupme_args->{user_id} = $user->groupme_id;
    }

    my $guid = $self->groupme->add_member($room->groupme_id, $groupme_args); 
    #FIXME HACK: wait a second, then check response
    sleep(1);
    my $members = $self->groupme->check_add_member($room->groupme_id, $guid);
    return 0 unless $members;

    if (!$user->groupme_id) {
        $user->update({ groupme_id => $members->[0]->{user_id} });
    }
    $access->update({ group_user_id => $members->[0]->{id} });

    return 1;
}

sub remove_user_from_group {
    my ($self, $user, $room_id) = @_;

    $self->logger->debug('Removing user ' . $user->id . " from room $room_id");
    my $access = $self->schema->resultset('RoomAccess')->find({
                room_id => $room_id,
                agent_id => $user->id,
            }, {
                prefetch => 'room',
                key => 'agent_room_access_key',
            });

    if ($access && $access->is_member) {
        my $membership_id = $access->group_user_id;
        if (!$membership_id) {
            $membership_id = $self->get_membership_id($user, $access->room->groupme_id);
        }
        die "Could not get membership ID" unless $membership_id;

        if ($self->groupme->remove_member($access->room->groupme_id, $membership_id)) {
            $access->update({is_member => 0});
            return 1;
        } else {
            $self->logger->warning('Could not remove member ' . $user->id . " from room $room_id");
        }
    }
    return 0;
}

sub meet_user { # ID 1 is the initiating user
    my ($self, $initiator_id, $target_agent_id) = @_;
    my $initiator = $self->schema->resultset('Agent')->find($initiator_id);
    my $target_agent = $self->schema->resultset('Agent')->find($target_agent_id);
    die "Could not find user $initiator_id" unless $initiator;
    die "Could not find user $target_agent_id" unless $target_agent;

    my $meeting = $initiator->meet_agent($target_agent_id);
    return $meeting;
}

sub get_membership_id {
    my ($self, $user, $group_id) = @_;
    die "Valid user required" unless $user && $user->groupme_id;
    die "Must give group ID" unless $group_id;

    my @members = $self->groupme->get_members($group_id);
    for my $member (@members) {
        return $member->{id} if $user->groupme_id == $member->{user_id};
    }
    return 0;
}

sub create_room {
    my $self = shift;
    my $args = shift;

    my $group_name = $args->{group_name} or die "Must specify group name";
    my $is_moderated = $args->{is_moderated} ? 1 : 0;
    my $topic = $args->{topic} || '';
    my $access_level_id = $args->{access_level_id} or die "Must give access level ID";

    my $group_id = $self->groupme->create_group({name => $group_name, topic => $topic});
    $self->logger->info("Created GM Group with ID $group_id");

    if ($args->{image_path} && -e $args->{image_path} && !$args->{image_url}) {
        my $url = $self->groupme->upload_pic($args->{image_path});
        $args->{image_url} = $url;
    }

    my $room = $self->schema->resultset('Room')->create({
        name => $group_name,
        groupme_id => $group_id,
        access_level_id => $access_level_id,
        image_url => $args->{image_url} || '',
        is_visible => $args->{is_visible} || 0,
        topic => $topic || '',
        is_moderated => $is_moderated,
    });
    return $room;
}

sub update_room {
    my ($self, $room_id, $args) = @_;

    my $room = $self->schema->resultset('Room')->find($room_id);
    die "Room not found with ID $room_id" unless $room;

    if ($self->groupme->update_group($room->groupme_id, $args)) {
        $room->update($args);
    }
}

sub delete_room {
    my ($self, $room_id) = @_;

    my $room = $self->schema->resultset('Room')->find($room_id);
    die "Room not found with ID $room_id" unless $room;

    # Delete from GM first
    $self->logger->info("Deleting GM group '" . $room->name . "' (GM ID: " . $room->groupme_id . ')');
    $self->groupme->delete_group($room->groupme_id);

    $self->logger->info('Deleting DB room, ID ' . $room->id);
    $room->delete();
}

sub create_bot {
    my ($self, $args) = @_;

    my $room;
    if (my $room_id = $args->{room_id}) {
        $room = $self->schema->resultset('Room')->find($room_id);

    } elsif (my $groupme_id = $args->{groupme_id}) {
        $room = $self->schema->resultset('Room')->search({groupme_id => $groupme_id})->first();

    } else {
        die "Must specify a GroupMe or DB ID for the room";
    }
    die "Invalid room ID" unless $room;
    die "Must specify a callback url" unless $args->{callback_url};

    my $params = {
        name => $args->{name} || 'Bot',
        avatar_url => $args->{avatar_url} || '',
        callback_url => $args->{callback_url},
    };
    my $bot_id = $self->groupme->create_bot($room->groupme_id, $params);
    if ($bot_id) {
        $room->update({bot_id => $bot_id});
    }
    return $bot_id;
}

# process messages for bot commands and logging

sub process_message {
    my ($self, $message) = @_;

    if ($message->{message_type} eq 'incoming_groupme') {
        # First log
        $self->logger->debug('Logging GroupMe message');
        $self->log_message($message->{message_content});

        # Then see if its a system message
        if (!$message->{message_content}->{user_id}) {
            try {
                $self->process_system_message($message->{message_content});
            } catch {
                $self->logger->warning('Processing system message failed: "' . $message->{message_content} . '", ERROR: ' . $_);
            };
        }

        my $groupme_id = $message->{message_content}->{group_id};
        my $room = $self->schema->resultset('Room')->find({
                    groupme_id => $groupme_id,
                }, {
                    key => 'room_groupme_id_key',
            });
        # FIXME this is only temporary during the chat changes
#        if ($room && $room->id <= 23 && ($room->bot_id ne $message->{message_content}->{user_id})) {
#            $self->groupme->create_message($room->groupme_id, "This chat is no longer in use.  We have new chats available, which you can reach by going to http://clten.com");
#        }


        if ($message->{message_content}->{text} && $message->{message_content}->{text} =~ m/^!/) {
#            $self->logger->debug('Processing bot command');
#            $self->bot_command($message->{bot}, $message->{message_content}) ;

            try {
                $self->process_bot_command($message->{message_content});
            } catch {
                $self->logger->warning('Processing bot command failed: "' . $message->{message_content} . '", ERROR: ' . $_);
            };
        }
    }
}

#{"user_id": "13729522", "name": "Marc (digitlgrfx L14)", "source_guid": "android-05874055-d45a-42fc-a1fc-6b08c2dcd2ce", "text": "Old Pineville and Archdale ", "created_at": 1413649072, "sender_id": "13729522", "system": false, "sender_type": "user", "favorited_by": [], "avatar_url": "https://i.groupme.com/900x900.jpeg.d9ecf1d0463f01316ea322000a638017", "group_id": "6598978", "id": "141364907275733840", "attachments": []}

sub process_bot_command {
    my ($self, $message) = @_;

    my $text = $message->{message_content}->{text};
    my $groupme_id = $message->{message_content}->{group_id};

    my $room = $self->schema->resultset('Room')->find({
                groupme_id => $groupme_id,
            }, {
                key => 'room_groupme_id_key',
        });
    die "Room for GroupMe ID $groupme_id not found" unless $room;

    return unless $room->bot_id; # really this should always have a bot id

    # ignore if this message was sent by the bot/manager account
    my $bot_id = $room->bot_id;
    return if $bot_id eq $message->{user_id};

    # Parse the text
    $text =~ s/^!(\w+)\s+//;
    my $command_string = $1;
    return unless $command_string;

#    my $command = $room->search_related('bot_command', {
#    });
    return;
}

# Processes system message from GroupMe, ie. user was added/removed, etc.
sub process_system_message {
    my ($self, $message) = @_;

    my $text = $message->{text};
    my $groupme_id = $message->{group_id};

    my $room = $self->schema->resultset('Room')->find({
                groupme_id => $groupme_id,
            }, {
                key => 'room_groupme_id_key',
        });
    die "Room for GroupMe ID $groupme_id not found" unless $room;

    for ($text) {
        when (m/(added|joined)/) {
            $self->logger->debug("Checking group members");
            try {
                $self->check_room_members($room);
            } catch {
                $self->logger->error("Could not check room members for GroupMe ID $groupme_id: " . $_);
                return 0;
            };
        } 
        when ($text =~ m/avatar/) {
            $self->logger->debug("Setting Group Avatar back");
            if (! $self->groupme->update_group($room->groupme_id, {image_url => $room->image_url})) {
                $self->logger->error("Could not update group ($groupme_id) image to: " . $room->image_url);
                return 0;
            }
        }
        when ($text =~ m/topic to:(.*)$/) {
            $self->logger->debug("Setting Group Topic back");
            return if $1 eq $room->topic;
            if (! $self->groupme->update_group($room->groupme_id, {topic => $room->topic} || '')) {
                $self->logger->error("Could not update group ($groupme_id) topic: " . $room->topic);
                return 0;
            }
        }
        when ($text =~ m/changed the group.* name to (.*)/) {
            $self->logger->debug("Setting Group Name back");
            return if $1 eq $room->name;
            if (! $self->groupme->update_group($room->groupme_id, {name => $room->name} || '')) {
                $self->logger->error("Could not update group ($groupme_id) name: " . $room->name);
                return 0;
            }
        }
        when ($text =~ m/has left|removed/) {
            $self->logger->debug("Updating DB for user leaving group");
            try {
                $self->check_room_members($room);
            } catch {
                $self->logger->error("Could not check room members for GroupMe ID $groupme_id: " . $_);
                return 0;
            };
        }
    }
    return 1;
}

sub check_room_members {
    my ($self, $room_id) = @_;
    my $room;

    if (ref $room_id) {
        $room = $room_id;

    } else {
        $room = $self->schema->resultset('Room')->find($room_id);
        die "Room with ID $room_id does not exist" unless $room;
    }

    my $group_info = $self->groupme->get_group($room->groupme_id);
    my $member_hash = {};

    # First find members of the group and make sure they have access to the group
    for my $member (@{ $group_info->{members} }) {
        $member_hash->{$member->{user_id}} = $member;

        my $agent = $self->schema->resultset('Agent')->find({
                    groupme_id => $member->{user_id},
                }, {
                    key => 'agent_groupme_id_key',
                    prefetch => 'access_level',
            });

        my $access = $room->search_related('room_access', {
            is_member => 0,
            agent_id => $agent->id,
        }) if $agent;

        if (!has_access($agent, $room)) {
            $self->logger->debug("Removing member ", $member->{user_id});
            $self->groupme->remove_member($room->groupme_id, $member->{id});

        } else {
            if ($access) {
                $access->update({is_member => 1});

            } else {
                $room->create_related('room_access', {
                    agent_id => $agent->id,
                    is_member => 1,
                });
            }
        }

#        if (!$agent || ($agent->access_level->value < $room->access_level->value) || $agent->status ne 'active') {
#            $self->logger->debug("Removing member ", $member->{user_id});
#            $self->groupme->remove_member($room->groupme_id, $member->{id});
#        }

        # Also make sure the DB shows them as a member
#        my $access = $room->search_related('room_access', {
#            is_member => 0,
#            agent_id => $agent->id,
#        });
#        if ($access) {
#            $access->update({is_member => 1});
#        }
    }

    # Next look for who we show as being in the group but isn't
    my $access_list = $room->search_related('room_access', {
                is_member => 1,
            }, {
                prefetch => 'agent',
        });
    while (my $access = $access_list->next) {
        if (!$member_hash->{$access->agent->groupme_id}) {
            $access->update({is_member => 0});
        }
    }
}

# log the message to db
sub log_message {
    my ($self, $message_json) = @_;

    $self->logger->debug(Dumper $message_json);
    $self->logger->debug($message_json->{group_id});
    my $room = $self->schema->resultset('Room')->find({
                groupme_id => $message_json->{group_id},
            }, {
                key => 'room_groupme_id_key',
        });
    if (!$room) {
        $self->logger->warning("Could not find room with ID '$message_json->{group_id}'");
        return 0;
    }

    # First check that the message hasn't been stored
    my $message = $self->schema->resultset('ChatLog')->find({
                message_id => $message_json->{id},
                room_id => $room->id,
            }, {
                key => 'room_message_key',
        });
    return 1 if $message;

    my $agent = $self->schema->resultset('Agent')->find({
                groupme_id => $message_json->{user_id},
            }, {
                key => 'agent_groupme_id_key',
        });
    if (!$agent) {
        $self->logger->error('Could not find user with GroupMe ID: ' . $message_json->{user_id});
        return 0;
    }
    # FIXME : filter out or deal with system messages

    # Process date
    my $dt = convert_groupme_date($message_json->{created_at});

    # Process attachments
#    my $attachments = encode_json($message_json->{attachments});
    my $attachments = $message_json->{attachments} || [];

    $self->schema->resultset('ChatLog')->create({
        agent_id => $agent->id,
        room_id => $room->id,
        message => $message_json->{text} || '',
        message_id => $message_json->{id},
        avatar_url => $message_json->{avatar_url},
        attachments => $attachments,
        message_time => $dt->ymd . ' ' . $dt->hms,
    });

    return 1;
}

1;
