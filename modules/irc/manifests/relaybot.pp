# class: irc::relaybot
class irc::relaybot {
    $install_path = '/srv/relaybot'

    $bot_token = lookup('passwords::irc::relaybot::bot_token')
    $irc_password = lookup('passwords::irc::relaybot::irc_password')

    file { '/opt/packages-microsoft-prod.deb':
        ensure => present,
        source => 'puppet:///modules/irc/relaybot/packages-microsoft-prod.deb',
    }

    package { 'packages-microsoft-prod':
        ensure   => installed,
        provider => dpkg,
        source   => '/opt/packages-microsoft-prod.deb',
        require  => File['/opt/packages-microsoft-prod.deb'],
    }

    exec { 'apt_update_relaybot':
        command     => '/usr/bin/apt update',
        refreshonly => true,
        logoutput   => true,
        subscribe   => Package['packages-microsoft-prod'],
    }

    package { 'dotnet-sdk-6.0':
        ensure  => installed,
        require => Exec['apt_update_relaybot'],
    }

    file { $install_path:
        ensure => 'directory',
        owner  => 'irc',
        group  => 'irc',
        mode   => '0755',
    }

    git::clone { 'IRC-Discord-Relay':
        ensure    => latest,
        origin    => 'https://github.com/WikiForge/IRC-Discord-Relay',
        directory => $install_path,
        owner     => 'irc',
        group     => 'irc',
        mode      => '0755',
        require   => File[$install_path],
    }

    file { "${install_path}/config.ini":
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => template('irc/relaybot/config.ini.erb'),
        require => Git::Clone['IRC-Discord-Relay'],
        notify  => Service['relaybot'],
    }

    systemd::service { 'relaybot':
        ensure  => present,
        content => systemd_template('relaybot'),
        restart => true,
        require => [
            Git::Clone['IRC-Discord-Relay'],
            Package['dotnet-sdk-6.0'],
            File["${install_path}/config.ini"],
        ],
    }
}
