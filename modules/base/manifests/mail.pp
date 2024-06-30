# A class to handle GENERIC server mail internally. This will NOT work outside
# a WikiForge Mail Server.
class base::mail {
    package { 'postfix':
        ensure => present,
    }

    package { 'exim4':
        ensure => absent,
    }

    file { '/etc/postfix/main.cf':
        ensure  => present,
        owner   => 'postfix',
        group   => 'postfix',
        content => template('base/mail/main.cf'),
        require => Package['postfix'],
        notify  => Service['postfix'],
    }

    service { 'postfix':
        ensure  => running,
        require => Package['postfix'],
    }

    mailalias { 'root':
        recipient => 'root@wikiforge.xyz',
    }

    file { '/etc/mailname':
        ensure  => present,
        content => 'wikiforge.xyz',
    }
}