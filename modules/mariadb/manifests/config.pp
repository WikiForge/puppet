# class: mariadb::config
class mariadb::config(
    String            $config                       = undef,
    String            $password                     = undef,
    String            $datadir                      = '/srv/mariadb',
    String            $tmpdir                       = '/tmp',
    String            $innodb_buffer_pool_size      = '500M',
    Integer           $max_connections              = 500,
    Enum['10.5']      $version                      = lookup('mariadb::version', {'default_value' => '10.5'}),
    Optional[Integer] $server_id                    = undef,
) {
    $mariadb_replica_password = lookup('passwords::mariadb_replica_password')

    file { '/etc/my.cnf':
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => template($config),
    }

    file { '/etc/mysql':
        ensure => directory,
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
    }

    file { '/etc/mysql/my.cnf':
        ensure  => link,
        target  => '/etc/my.cnf',
        require => File['/etc/mysql'],
    }

    file { '/etc/mysql/debian.cnf':
        owner   => 'mysql',
        group   => 'mysql',
        mode    => '0400',
        require => File['/etc/mysql'],
    }

    file { $datadir:
        ensure  => directory,
        owner   => 'mysql',
        group   => 'mysql',
        mode    => '0755',
        require => Package["mariadb-server-${version}"],
    }

    if $tmpdir != '/tmp' {
        file { $tmpdir:
            ensure  => directory,
            owner   => 'mysql',
            group   => 'mysql',
            mode    => '0775',
            require => Package["mariadb-server-${version}"],
        }
    }

    file { '/etc/mysql/wikiforge':
        ensure  => directory,
        owner   => 'mysql',
        group   => 'mysql',
        mode    => '0750',
        require => Package["mariadb-server-${version}"],
    }

    file { '/etc/mysql/wikiforge/default-grants.sql':
        ensure  => present,
        content => template('mariadb/grants/default-grants.sql.erb'),
        require => File['/etc/mysql/wikiforge'],
    }

    file { '/root/.my.cnf':
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => template('mariadb/config/root.my.cnf.erb'),
    }

    file { '/var/tmp/mariadb':
        ensure  => directory,
        owner   => 'mysql',
        group   => 'mysql',
        mode    => '0644',
        require => Package["mariadb-server-${version}"],
    }

    logrotate::conf { 'mysql-server':
        ensure  => present,
        source  => 'puppet:///modules/mariadb/mysql-server.logrotate.conf',
        require => Package["mariadb-server-${version}"],
    }

    systemd::unit { 'mariadb.service':
        ensure   => present,
        content  => template('mariadb/mariadb-systemd-override.conf.erb'),
        override => true,
        restart  => false,
    }

    rsyslog::input::file { 'mysql':
        path              => '/var/log/mysql/mysql-error.log',
        syslog_tag_prefix => '',
        use_udp           => true,
    }
}
