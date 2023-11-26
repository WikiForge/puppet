# === Class blesta::php
class blesta::php (
    Float $fpm_workers_multiplier      = lookup('blesta::php::fpm::fpm_workers_multiplier', {'default_value' => 1.5}),
    Integer $fpm_min_child             = lookup('blesta::php::fpm::fpm_min_child', {'default_value' => 4}),
    Integer $request_timeout           = lookup('blesta::php::request_timeout', {'default_value' => 60}),
    VMlib::Php_version $php_version    = lookup('php::php_version'),
    Boolean $enable_fpm                = lookup('blesta::php::enable_fpm', {'default_value' => true}),
    Boolean $enable_request_profiling  = lookup('blesta::php::enable_request_profiling', {'default_value' => false}),
    String $memory_limit               = lookup('blesta::php::memory_limit', {'default_value' => '256M'}),
    Optional[Hash] $fpm_config         = lookup('blesta::php::fpm_config', {default_value => undef}),
) {

    $config_cli = {
        'include_path'           => '".:/usr/share/php"',
        'error_log'              => 'syslog',
        'pcre.backtrack_limit'   => 5000000,
        'date.timezone'          => 'UTC',
        'display_errors'         => 'stderr',
        'memory_limit'           => $memory_limit,
        'error_reporting'        => 'E_ALL & ~E_STRICT',
        'mysql'                  => { 'connect_timeout' => 3 },
        'default_socket_timeout' => 60,
    }

    $config_opcache = {
        'opcache.enable'                  => 1,
        'opcache.enable_cli'              => 1,
        'opcache.interned_strings_buffer' => 50,
        'opcache.memory_consumption'      => 300,
        'opcache.max_accelerated_files'   => 24000,
        'opcache.max_wasted_percentage'   => 10,
        'opcache.validate_timestamps'     => 1,
        'opcache.revalidate_freq'         => 10,
        'opcache.jit_buffer_size'         => '256M',
    }

    # Custom config for php-fpm
    $base_config_fpm = {
        'display_errors'                  => 0,
        'session.upload_progress.enabled' => 0,
        'enable_dl'                       => 0,
        'rlimit_core'                     => 0,
        'apc.shm_size'                    => '256M',
    }

    if $enable_fpm {
        $_sapis = ['cli', 'fpm']
        $_config = {
            'cli' => merge($config_cli, $config_opcache),
            'fpm' => merge($config_cli, $config_opcache, $base_config_fpm, $fpm_config)
        }
        # Add systemd override for php-fpm, that should prevent a reload
        # if the fpm config files are broken.
        systemd::unit { "php${php_version}-fpm.service":
            ensure   => present,
            content  => init_template('php-fpm', 'systemd_override'),
            override => true,
            restart  => false,
        }
    } else {
        $_sapis = ['cli']
        $_config = {
            'cli' => $config_cli,
        }
    }
    # Install the runtime
    class { 'php':
        ensure         => present,
        version        => $php_version,
        sapis          => $_sapis,
        config_by_sapi => $_config,
    }

    # Extensions that need no custom settings

    # First, extensions provided as core extensions; these are version-specific
    # and are provided as php$version-$extension
    $core_extensions =  [
        'bcmath',
        'bz2',
        'curl',
        'gd',
        'gmp',
        'intl',
        'ldap',
        'mbstring',
        'zip',
    ]

    $core_extensions.each |$extension| {
        php::extension { $extension:
            package_name => "php${php_version}-${extension}"
        }
    }
    # Extensions that are installed with package-name php-$extension and, based
    # on the php version selected above, will install the proper extension
    # version based on apt priorities.
    # php-luasandbox and  php-wikidiff2 are special cases as the package is *not*
    # compatible with all supported PHP versions.
    # Technically, it would be needed to inject ensure => latest in the packages,
    # but we prefer to handle the transitions with other tools than puppet.
    php::extension { [
        'apcu',
        'msgpack',
        'redis',
        'yaml',
    ]:
        ensure => present
    }

    php::extension{ [
        'luasandbox',
        'wikidiff2',
    ]:
        ensure       => present,
        package_name => '',
    }

    # Extensions that require configuration.
    php::extension {
        'xml':
            package_name => "php${php_version}-xml",
            priority     => 15;
        'memcached':
            priority => 25,
            config   => {
                'extension'                   => 'memcached.so',
                'memcached.serializer'        => 'php',
                'memcached.store_retry_count' => '0'
            };
        'igbinary':
            config   => {
                'extension'                => 'igbinary.so',
                'igbinary.compact_strings' => 'Off',
            };
        'mysqli':
            package_name => "php${php_version}-mysql",
            config       => {
                'extension'                 => 'mysqli.so',
                'mysqli.allow_local_infile' => 'Off',
            }
            ;

        'dba':
            package_name => "php${php_version}-dba",
    }

    # Additional config files are needed by some extensions, add them
    # MySQL
    php::extension {
        default:
            package_name => '',;
        'pdo_mysql':
            ;
        'mysqlnd':
            priority => 10,
    }
    # XML
    php::extension{ [
        'dom',
        'simplexml',
        'xmlreader',
        'xmlwriter',
        'xsl',
    ]:
        package_name => '',
    }

    ### FPM configuration
    # You can check all configuration options at
    # http://php.net/manual/en/install.fpm.configuration.php
    if $enable_fpm {
        class { 'php::fpm':
            ensure => present,
            config => {
                'emergency_restart_interval'  => '60s',
                'emergency_restart_threshold' => $facts['processors']['count'],
                'process.priority'            => -19,
            }
        }

        # This will add an fpm pool
        # We want a minimum of $fpm_min_child workers
        $num_workers = max(floor($facts['processors']['count'] * $fpm_workers_multiplier), $fpm_min_child)
        php::fpm::pool { 'www':
            config => {
                'pm'                        => 'static',
                'pm.max_children'           => $num_workers,
                'request_terminate_timeout' => $request_timeout,
                'request_slowlog_timeout'   => 15,
            }
        }

        # Send logs locally to /var/log/php8.x-fpm/error.log
        # Please note: this replaces the logrotate rule coming from the package,
        # because we use syslog-based logging. This will also prevent an fpm reload
        # for every logrotate run.
        systemd::syslog { "php${php_version}-fpm":
            base_dir     => '/var/log',
            owner        => 'www-data',
            group        => 'www-data',
            readable_by  => 'group',
            log_filename => 'error.log'
        }
    }

    # Set the default interpreter to php8
    $cli_path = "/usr/bin/php${php_version}"
    $pkg = "php${php_version}-cli"
    alternatives::select { 'php':
        path    => $cli_path,
        require => Package[$pkg],
    }
}