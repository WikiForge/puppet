# role: irc
class role::irc {
    include irc::irclogbot
    include irc::relaybot

    class { 'irc::irclogserverbot':
        nickname     => 'WikiForgeLSBot',
        network      => 'irc.libera.chat',
        network_port => '6697',
        channel      => '#wikiforge-sre',
        udp_port     => '5071',
    }

$firewall_irc_rules_str = join(
        query_facts('Class[Role::Mediawiki]', ['networking'])
        .map |$key, $value| {
            if ( $value['networking']['interfaces']['ens18'] and $value['networking']['interfaces']['ens19'] ) {
                "${value['networking']['interfaces']['ens18']['ip']} ${value['networking']['interfaces']['ens19']['ip']} ${value['networking']['interfaces']['ens19']['ip6']}"
            } elsif ( $value['networking']['interfaces']['ens18'] ) {
                "${value['networking']['interfaces']['ens18']['ip']}"
            } else {
                "${value['networking']['ip']} ${value['networking']['ip6']}"
            }
        }
        .flatten()
        .unique()
        .sort(),
        ' '
    )
    ferm::service { 'ircrcbot':
        proto  => 'udp',
        port   => '5070',
        srange => "(${firewall_irc_rules_str})",
    }

    $firewall_all_rules_str = join(
        query_facts('Class[Base]', ['networking'])
        .map |$key, $value| {
            if ( $value['networking']['interfaces']['ens18'] and $value['networking']['interfaces']['ens19'] ) {
                "${value['networking']['interfaces']['ens18']['ip']} ${value['networking']['interfaces']['ens19']['ip']} ${value['networking']['interfaces']['ens19']['ip6']}"
            } elsif ( $value['networking']['interfaces']['ens18'] ) {
                "${value['networking']['interfaces']['ens18']['ip']}"
            } else {
                "${value['networking']['ip']} ${value['networking']['ip6']}"
            }
        }
        .flatten()
        .unique()
        .sort(),
        ' '
    )
    ferm::service { 'irclogserverbot':
        proto  => 'udp',
        port   => '5071',
        srange => "(${firewall_all_rules_str})",
    }

    motd::role { 'role::irc':
        description => 'IRC bots server',
    }
}
