# dns
class dns {
    package { 'gdnsd':
        ensure  => installed,
    }

    git::clone { 'dns':
        ensure    => latest,
        directory => '/etc/gdnsd',
        origin    => 'https://github.com/WikiForge/dns',
        owner     => 'root',
        group     => 'root',
        before    => Package['gdnsd'],
        notify    => Exec['gdnsd-syntax'],
    }

    file { '/usr/share/GeoIP':
        ensure => directory,
        mode   => '0444',
    }

    file { '/usr/share/GeoIP/GeoLite2-Country.mmdb':
        ensure  => present,
        source  => 'puppet:///private/geoip/GeoLite2-Country.mmdb',
        mode    => '0444',
        require => File['/usr/share/GeoIP'],
        notify  => Exec['gdnsd-syntax'],
    }

    exec { 'gdnsd-syntax':
        command     => '/usr/sbin/gdnsd checkconf',
        notify      => Service['gdnsd'],
        refreshonly => true,
    }

    service { 'gdnsd':
        ensure     => running,
        hasrestart => true,
        hasstatus  => true,
        require    => [ Package['gdnsd'], Exec['gdnsd-syntax'] ],
    }
}
