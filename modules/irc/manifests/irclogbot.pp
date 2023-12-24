# class: irc::irclogbot
class irc::irclogbot {
    include ::irc

    file { '/etc/irclogbot':
        ensure => directory,
    }

    git::clone { 'mwclient':
        ensure    => present,
        directory => '/etc/irclogbot/mwclient',
        origin    => 'https://github.com/mwclient/mwclient',
        require   => File['/etc/irclogbot'],
    }

    $wikiforgebots_password = lookup('passwords::irc::wikiforgebots')
    $wikiforgelogbot_password = lookup('passwords::mediawiki::wikiforgelogbot')
    $wikiforgelogbot_consumer_token = lookup('passwords::mediawiki::wikiforgelogbot_consumer_token')
    $wikiforgelogbot_consumer_secret = lookup('passwords::mediawiki::wikiforgelogbot_consumer_secret')
    $wikiforgelogbot_access_token = lookup('passwords::mediawiki::wikiforgelogbot_access_token')
    $wikiforgelogbot_access_secret = lookup('passwords::mediawiki::wikiforgelogbot_access_secret')

    file { '/etc/irclogbot/adminlog.py':
        ensure => present,
        source => 'puppet:///modules/irc/logbot/adminlog.py',
        notify => Service['logbot'],
    }

    file { '/etc/irclogbot/adminlogbot.py':
        ensure => present,
        source => 'puppet:///modules/irc/logbot/adminlogbot.py',
        mode   => '0755',
        notify => Service['logbot'],
    }

    file { '/etc/irclogbot/config.py':
        ensure  => present,
        content => template('irc/logbot/config.py'),
        notify  => Service['logbot'],
    }

    systemd::service { 'logbot':
        ensure  => present,
        content => systemd_template('logbot'),
        restart => true,
    }

    monitoring::nrpe { 'IRC Log Bot':
        command => '/usr/lib/nagios/plugins/check_procs -a adminlogbot.py -c 1:1'
    }
}
