# class: mariadb::packages
class mariadb::packages(
    VMlib::Mariadb_version $version = lookup('mariadb::version', {'default_value' => '10.11'}),
) {

    package { [
        'mydumper',
        'percona-toolkit',
    ]:
        ensure => present,
    }

    # First installs can trip without this
    exec { 'apt_update_mariadb':
        command     => '/usr/bin/apt-get update',
        refreshonly => true,
        logoutput   => true,
    }

    package { [
        'mariadb-server',
        'mariadb-backup',
        'libjemalloc2',
    ]:
        ensure  => present,
        require => Exec['apt_update_mariadb'],
    }
}
