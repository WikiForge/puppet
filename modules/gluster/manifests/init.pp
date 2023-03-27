# == Class: glusters

class gluster {
    include gluster::apt

    ssl::wildcard { 'gluster wildcard': }

    package { 'glusterfs-server':
        ensure  => installed,
        require => Class['gluster::apt'],
    }

    if !defined(File['glusterfs.pem']) {
        file { 'glusterfs.pem':
            ensure => 'present',
            source => 'puppet:///ssl/certificates/wildcard.wikiforge.net.crt',
            path   => '/usr/lib/ssl/glusterfs.pem',
            owner  => 'root',
            group  => 'root',
        }
    }

    if !defined(File['glusterfs.key']) {
        file { 'glusterfs.key':
            ensure => 'present',
            source => 'puppet:///ssl-keys/wildcard.wikiforge.net.key',
            path   => '/usr/lib/ssl/glusterfs.key',
            owner  => 'root',
            group  => 'root',
            mode   => '0660',
        }
    }

    if !defined(File['glusterfs.ca']) {
        file { 'glusterfs.ca':
            ensure => 'present',
            source => 'puppet:///ssl/ca/LetsEncrypt.crt',
            path   => '/usr/lib/ssl/glusterfs.ca',
            owner  => 'root',
            group  => 'root',
        }
    }

    if !defined(File['/var/lib/glusterd/secure-access']) {
        file { '/var/lib/glusterd/secure-access':
            ensure  => present,
            source  => 'puppet:///modules/gluster/secure-access',
            require => Package['glusterfs-server'],
        }
    }

    service { 'glusterd':
        ensure     => running,
        enable     => true,
        hasrestart => true,
        hasstatus  => true,
        require    => [
            File['/var/lib/glusterd/secure-access'],
        ],
    }

    if lookup('gluster_client', {'default_value' => false}) {
        if !defined(Gluster::Mount['/mnt/mediawiki-static']) {
            gluster::mount { '/mnt/mediawiki-static':
              ensure => mounted,
              volume => lookup('gluster_volume', {'default_value' => 'gluster1.wikiforge.net:/static'}),
            }
        }
    }

    rsyslog::input::file { 'glusterd':
        path              => '/var/log/glusterfs/glusterd.log',
        syslog_tag_prefix => '',
        use_udp           => true,
    }

    logrotate::conf { 'glusterfs-common':
        ensure => present,
        source => 'puppet:///modules/gluster/glusterfs-common.logrotate.conf',
    }
}
