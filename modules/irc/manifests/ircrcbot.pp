# class: irc::ircrcbot
class irc::ircrcbot(
    $nickname     = undef,
    $network      = undef,
    $network_port = '6697',
    $channel      = undef,
    $udp_port     = '5070',
) {
    include ::irc

    $wikiforgebots_password = lookup('passwords::irc::wikiforgebots')

    file { '/usr/local/bin/ircrcbot.py':
        ensure  => absent,
        content => template('irc/ircrcbot.py'),
        mode    => '0755',
    }

    systemd::service { 'ircrcbot':
        ensure  => absent,
        content => systemd_template('ircrcbot'),
    }
}
