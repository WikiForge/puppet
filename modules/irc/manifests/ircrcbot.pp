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
        ensure  => present,
        content => template('irc/ircrcbot.py'),
        mode    => '0755',
        notify  => Service['ircrcbot'],
    }

    systemd::service { 'ircrcbot':
        ensure  => present,
        content => systemd_template('ircrcbot'),
        restart => true,
    }
}
