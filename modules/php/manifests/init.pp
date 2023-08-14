# == Class php
#
# Basic installation of php - only cli modules.
#
class php(
    VMlib::Php_version $version                      = lookup('php::php_version'),
    Array[VMlib::Php_version] $absented_php_versions = lookup('php::absented_php_versions', {'default_value' => []}),
    VMlib::Ensure $ensure                            = present,
    Array[Php::Sapi] $sapis                          = ['cli'],
    Hash $config_by_sapi                             = {},
    Hash $extensions                                 = {}
) {
    if $version != '7.4' and !defined(Apt::Source['php_apt']) {
        file { '/etc/apt/trusted.gpg.d/php.gpg':
            ensure => present,
            source => 'puppet:///modules/php/key/php.gpg',
        }

        apt::source { 'php_apt':
            location => 'https://packages.sury.org/php/',
            release  => $facts['os']['distro']['codename'],
            repos    => 'main',
            require  => File['/etc/apt/trusted.gpg.d/php.gpg'],
            notify   => Exec['apt_update_php'],
        }

        apt::pin { 'php_pin':
            priority => 600,
            origin   => 'packages.sury.org'
        }

        # First installs can trip without this
        exec {'apt_update_php':
            command     => '/usr/bin/apt-get update',
            refreshonly => true,
            logoutput   => true,
            require     => Apt::Pin['php_pin'],
        }
    }

    # remove all php versions we want to absent, completely.
    php::absented_version{ $absented_php_versions: }

    # We need php-common everywhere
    ensure_packages(["php${version}-common", "php${version}-opcache"])

    $config_dir = "/etc/php/${version}"

    $package_by_sapi = {
        'cli'     => "php${version}-cli",
        'fpm'     => "php${version}-fpm",
        'apache2' => "libapache2-mod-php${version}",
    }

    # Basic configuration parameters.
    # Please note all these parameters can be overridden
    $base_config = {
        'date'                   => {
            'timezone' => 'UTC',
        },
        'default_socket_timeout' => 1,
        'display_errors'         => 'On',
        'log_errors'             => 'On',
        'include_path'           => '".:/usr/share/php"',
        'max_execution_time'     => 60,
        'memory_limit'           => '100M',
        'mysql'                  => {
            'connect_timeout' => 1,
        },
        'post_max_size'         => '100M',
        'session'               => {
            'save_path' => '/tmp',
        },
        'upload_max_filesize'   => '100M',
    }

    # Let's install the packages and configure PHP for each of the selected
    # SAPIs. Please note that if you want to configure php-fpm you will have
    # to declare the php::fpm class (and possibly some php::fpm::pool defines
    # too).
    $sapis.each |$sapi| {
        package { $package_by_sapi[$sapi]:
            ensure => $ensure,
        }
        # The directory gets managed by us actively.
        # This means that rogue configurations added by
        # packages will be actively removed.
        file { "${config_dir}/${sapi}/conf.d":
            ensure  => ensure_directory($ensure),
            owner   => 'root',
            group   => 'root',
            mode    => '0755',
            recurse => true,
            purge   => true
        }
        # Merge the basic configuration with the sapi-specific one, if present.
        file { "${config_dir}/${sapi}/php.ini":
            ensure  => $ensure,
            content => php_ini($base_config, pick($config_by_sapi[$sapi], {})),
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            tag     => "php::config::${sapi}",
        }
    }

    # Configure the builtin extensions
    class { '::php::default_extensions': }

    # Install and configure the extensions provided by the user
    $ext_defaults = {'sapis' => $sapis}
    $extensions.each |$ext_name,$ext_params| {
        $parameters = merge($ext_defaults, $ext_params)
        php::extension { $ext_name:
            * => $parameters
        }
    }
}
