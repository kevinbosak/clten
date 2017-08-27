package CltEn::Util;
use DateTime;
use Exporter;
use JSON;

@ISA = qw(Exporter);

@EXPORT = qw();
@EXPORT_OK = qw(
        convert_groupme_date
        build_user_chat_name
        iitc_draw_to_standard
        has_access
    );
%EXPORT_TAGS = (
    all => [qw(
        convert_groupme_date
        build_user_chat_name
        iitc_draw_to_standard
        has_access
    )],
);

# Checks access to any object that has a whitelist and access levels
sub has_access {
    my $user = shift;
    $user = shift if !ref $user && $user eq __PACKAGE__;
    my $item = shift;

    # Deactivated/unapproved users have no access
    return 0 unless $user && $user->status eq 'active' && $user->agreed_to_terms;

    if ($item->is_moderated) {
        return 0 unless $item->user_in_whitelist($user->id);

    } elsif ($agent->access_level->value < $room->access_level->value) {
        return 0;
    }
    return 1;
}

sub build_user_chat_name {
    my $user = shift;
    $user = shift if !ref $user && $user eq __PACKAGE__;

    return sprintf('%s (%s L%s)', $user->first_name, $user->agent_name, $user->agent_level || '?');
}

sub convert_groupme_date {
    my $groupme_date = shift;
    $groupme_date = shift if $groupme_date eq __PACKAGE__;

    my $dt = DateTime->from_epoch(epoch => $groupme_date, time_zone => 'UTC');
    return $dt;
}

sub iitc_draw_to_standard {
    my $iitc_string = shift;
    $iitc_string = shift if $iitc_string eq __PACKAGE__;

    my $data = decode_json($iitc_string);
    my @lines = ();
    for my $item (@$data) {
        next unless $item->{type} eq 'polygon';

        my $i = 0;
        my @points = ();
        for my $point (@{ $item->{latLngs} }) {
            $i++;
            push @points, join(',',$point->{lat}, $point->{lng});
            if ($i > 1) {
                push @lines, join(',', @points);
                shift @points;
            }
        }
        if (scalar @{ $item->{latLngs} } > 2) {
            my $firstpoint = $item->{latLngs}->[0];
            my $lastpoint = $item->{latLngs}->[-1];
            push @lines, join(',', $firstpoint->{lat}, $firstpoint->{lng}, $lastpoint->{lat}, $lastpoint->{lng});
        }
    }
    return join('_',@lines);
#    [{"type":"polygon","latLngs":[{"lat":35.283702,"lng":-80.792586},{"lat":35.251926,"lng":-80.73702},{"lat":35.233065,"lng":-80.836499}],"color":"#a24ac3"},{"type":"polygon","latLngs":[{"lat":35.251926,"lng":-80.73702},{"lat":35.291691,"lng":-80.795753},{"lat":35.233065,"lng":-80.836499}],"color":"#a24ac3"},{"type":"polygon","latLngs":[{"lat":35.251926,"lng":-80.73702},{"lat":35.30045,"lng":-80.801372},{"lat":35.233065,"lng":-80.836499}],"color":"#a24ac3"},{"type":"polygon","latLngs":[{"lat":35.292083,"lng":-80.795931},{"lat":35.251926,"lng":-80.73702},{"lat":35.233065,"lng":-80.836499}],"color":"#a24ac3"},{"type":"polygon","latLngs":[{"lat":35.29413,"lng":-80.796748},{"lat":35.251926,"lng":-80.73702},{"lat":35.233065,"lng":-80.836499}],"color":"#a24ac3"},{"type":"polygon","latLngs":[{"lat":35.296987,"lng":-80.799455},{"lat":35.251926,"lng":-80.73702},{"lat":35.233065,"lng":-80.836499}],"color":"#a24ac3"},{"type":"polygon","latLngs":[{"lat":35.303795,"lng":-80.803032},{"lat":35.251926,"lng":-80.73702},{"lat":35.233065,"lng":-80.836499}],"color":"#a24ac3"},{"type":"polygon","latLngs":[{"lat":35.313238,"lng":-80.809903},{"lat":35.251926,"lng":-80.73702},{"lat":35.233065,"lng":-80.836499}],"color":"#a24ac3"},{"type":"polygon","latLngs":[{"lat":35.31359,"lng":-80.810183},{"lat":35.251926,"lng":-80.73702},{"lat":35.233065,"lng":-80.836499}],"color":"#a24ac3"},{"type":"polygon","latLngs":[{"lat":35.314198,"lng":-80.810782},{"lat":35.251926,"lng":-80.73702},{"lat":35.233065,"lng":-80.836499}],"color":"#a24ac3"}]
#        https://www.ingress.com/intel?ll=35.24975469370182,-80.80431461334229&z=14&pls=35.279584,-80.765,35.267261,-80.83912_35.267261,-80.83912,35.23276,-80.811242_35.23276,-80.811242,35.279584,-80.765_35.279584,-80.765,35.267261,-80.83912_35.267261,-80.83912,35.224328,-80.817058_35.224328,-80.817058,35.279584,-80.765_35.279584,-80.765,35.267261,-80.83912_35.267261,-80.83912,35.221394,-80.81838_35.221394,-80.81838,35.279584,-80.765_35.279584,-80.765,35.267261,-80.83912_35.267261,-80.83912,35.219099,-80.819643_35.219099,-80.819643,35.279584,-80.765_35.21691,-80.820945,35.279584,-80.765_35.279584,-80.765,35.267261,-80.83912_35.267261,-80.83912,35.21691,-80.820945
}

1;
