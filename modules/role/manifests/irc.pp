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

    $firewall_all_rules_str = join(
        query_facts('Class[Base]', ['ipaddress', 'ipaddress6'])
        .map |$key, $value| {
            "${value['ipaddress']} ${value['ipaddress6']}"
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
