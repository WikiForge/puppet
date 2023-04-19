# class base::dns
class base::dns {
    package { 'pdns-recursor':
        ensure => present,
    }

    file { '/etc/powerdns/recursor.conf':
        mode   => '0444',
        owner  => 'pdns',
        group  => 'pdns',
        notify => Service['pdns-recursor'],
        source => 'puppet:///modules/base/dns/recursor.conf',
    }

    service { 'pdns-recursor':
        ensure  => running,
        require => Package['pdns-recursor'],
    }

    file { '/etc/resolv.conf':
        source  => 'puppet:///modules/base/dns/resolv.conf',
        require => Package['pdns-recursor'],
    }
}
