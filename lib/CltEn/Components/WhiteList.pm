package CltEn::Components::WhiteList;

use base qw(DBIx::Class);


# TODO let the class specify which column holds the whitelist

sub add_to_whitelist {
    my ($self, $item) = @_;
    $item = $item->id if ref $item;

    my @items = @{$self->whitelist};
    for my $existing_item (@items) {
        return if $item == $existing_item;
    }
    push @items, $item;
    $self->update({whitelist => \@items});
}

sub remove_from_whitelist {
    my ($self, $item) = @_;
    $item = $item->id if ref $item;

    my @items = @{$self->whitelist};
    my @new_items = ();

    for my $existing_item (@items) {
        push @new_items, $existing_item if $existing_item != $item;
    }
    $self->update({whitelist => \@new_items});
}

sub is_in_whitelist {
    my ($self, $item) = @_;
    $item = $item->id if ref $item;

    my @items = @{$self->whitelist};
    for my $existing_item (@items) {
        return 1 if $item == $existing_item;
    }
    return 0;
}

1;
