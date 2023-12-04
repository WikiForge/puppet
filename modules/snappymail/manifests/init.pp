class snappymail {
    $config_cli = {
        'include_path'           => '".:/usr/share/php"',
        'error_log'              => 'syslog',
        'pcre.backtrack_limit'   => 5000000,
        'date.timezone'          => 'UTC',
        'display_errors'         => 'stderr',
        'memory_limit'           => lookup('php::cli::memory_limit', {'default_value' => '400M'}),
        'error_reporting'        => 'E_ALL & ~E_STRICT',
        'mysql'                  => { 'connect_timeout' => 3 },
        'default_socket_timeout' => 60,
    }

    $config_fpm = {
        'memory_limit' => lookup('php::fpm::memory_limit', {'default_value' => '512M'}),
        'display_errors' => 'Off',
        'session.upload_progress.enabled' => 0,
        'enable_dl' => 0,
        'opcache' => {
            'enable' => 1,
            'interned_strings_buffer' => 30,
            'memory_consumption' => 112,
            'max_accelerated_files' => 20000,
            'max_wasted_percentage' => 10,
            'validate_timestamps' => 1,
            'revalidate_freq' => 10,
        },
        'max_execution_time' => 60,
        'post_max_size' => '60M',
        'track_errors' => 'Off',
        'upload_max_filesize' => '100M',
    }

    $core_extensions =  [
        'curl',
        'gd',
        'gmp',
        'intl',
        'mbstring',
        'ldap',
    ]

    $php_version = lookup('php::php_version', {'default_value' => '8.2'})

    # Install the runtime
    class { 'php':
        ensure         => present,
        version        => $php_version,
        sapis          => ['cli', 'fpm'],
        config_by_sapi => {
            'cli' => $config_cli,
            'fpm' => merge($config_cli, $config_fpm),
        },
    }

    $core_extensions.each |$extension| {
        php::extension { $extension:
            package_name => "php${php_version}-${extension}",
            sapis        => ['cli', 'fpm'],
        }
    }

    class { 'php::fpm':
        ensure => present,
        config => {
            'emergency_restart_interval'  => '60s',
            'emergency_restart_threshold' => $facts['processors']['count'],
            'process.priority'            => -19,
        },
    }

    # Extensions that require configuration.
    php::extension {
        default:
            sapis        => ['cli', 'fpm'];
        'mysqlnd':
            package_name => '',
            priority     => 10;
        'mysqli':
            package_name => "php${php_version}-mysql";
        'pdo_mysql':
            package_name => '';
        'xml':
            package_name => "php${php_version}-xml",
            priority     => 15;
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

    $fpm_workers_multiplier = lookup('php::fpm::fpm_workers_multiplier', {'default_value' => 1.5})
    $fpm_min_child = lookup('php::fpm::fpm_min_child', {'default_value' => 4})

    # This will add an fpm pool
    # We want a minimum of $fpm_min_child workers
    $num_workers = max(floor($facts['processors']['count'] * $fpm_workers_multiplier), $fpm_min_child)
    php::fpm::pool { 'www':
        config => {
            'pm'                        => 'static',
            'pm.max_children'           => $num_workers,
            'request_terminate_timeout' => '60',
            'request_slowlog_timeout'   => 15,
        }
    }

    stdlib::ensure_packages([
        "php${php_version}-pspell",
        'composer',
        'nodejs',
    ])

    file { '/usr/share/snappymail/include.php':
        ensure  => present,
        source => 'puppet:///modules/snappymail/include.php',
        owner   => 'www-data',
        group   => 'www-data',
    }

    ssl::wildcard { 'snappymail wildcard': }

    nginx::site { 'mail':
        ensure => present,
        source => 'puppet:///modules/snappymail/mail.wikiforge.net.conf',
    }

    nginx::site { 'snappymail':
        ensure => present,
        source => 'puppet:///modules/snappymail/snappymail.conf',
    }

    file { '/var/lib/snappymail':
        ensure => directory,
        owner  => 'www-data',
        group  => 'www-data',
        mode   => '0640',
    }

    file { '/var/log/snappymail':
        ensure  => directory,
        owner   => 'www-data',
        group   => 'www-data',
        mode    => '0640',
        require => Package['nginx'],
    }

    logrotate::conf { 'snappymail':
        ensure  => present,
        source  => 'puppet:///modules/snappymail/snappymail.logrotate.conf',
        require => File['/var/log/snappymail'],
    }

    monitoring::services { 'webmail.inside.wf HTTPS':
        check_command => 'check_http',
        vars          => {
            http_ssl   => true,
            http_vhost => 'webmail.inside.wf',
        },
    }
}
