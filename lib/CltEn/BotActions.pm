package CltEn::BotActions;
use warnings;
use strict;
use Try::Tiny;

our $BOT_ACTIONS = {
    'user' => {
        'set_access_level' => { },
        'get_access_level' => { },
        'set_status' => { },
        'get_status' => { },
        'kick_from_group' => {},
    },
    'group' => {
        'set_topic' => { },
    },
    'misc' => {
        'random' => {
            'params' => {
                'pattern' => {type => 'str', required => 1},
            },
            outputs => {
                'random_pattern' => {type => 'str'},
            },
        },
    },
    scoring => {
        mu_needed => {
            params => {
                score1 => {type => 'int', required => 1},
                score2 => {type => 'int', required => 1},
            }
            outputs => {
                mu_needed => {type => 'int'},
            },
        },
        'cycle_info' => {
            params => {},
            outputs => {
                cps_remaining => {type => 'int'},
                last_cp => {type => 'datetime'},
            },
        },
        cp_info => {
            params => {
                count => {type => 'int', required => 0, default => 5},
            },
            outputs => {
                'cp_numbers' => {type => 'array'},
                'cp_times' => {type => 'array'},
                'count' => {type => 'int'},
            },
        },
    },
};

sub run_action {
    my ($category, $action, $args) = @_;

    my $category_actions = $BOT_ACTIONS->{$category};
    return {error =>  'Invalid category'} unless $category_actions;

    my $action_info = $category_actions->{$action};
    return {error => 'Invalid action'} unless $action_info;

    # check params
    my $params_info = $action_info->{params} || {};
    my $param_errors = [];

    for my $param_name (keys %$params_info) {
        $param_info = $params_info->{param_name};
        if ($param_info->{required} && ! $args->{$param_name}) {
            return {error => "Param $param_name is required"};
        }

        for ($param_info->{type}) {
            when ('int') {
                return {error => "Param $param_name must be an Int" unless $args->{$param_name} =~ m/^\d+$/;
            }
#            when ('str') {
#                return {error => "Param $param_name must be an Int" unless $args->{$param_name} =~ m/^.+$/;
#            }
        }
    }

    my $full_action = join('_', $category, $action);
    my $results;
    try {
        eval "\$results = $full_action(\$args)";
        die $@ if $@;
    } catch {
        return {error => $_};
    };
}

1;
