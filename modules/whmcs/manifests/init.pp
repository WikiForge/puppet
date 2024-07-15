# === Class whmcs
class whmcs (
    Integer $request_timeout = lookup('phorge::php::request_timeout', {'default_value' => 60}),
) {
    stdlib::ensure_packages(['mariadb-client', 'python3-pygments', 'subversion'])

        $fpm_config = {
        'include_path'                    => '".:/usr/share/php"',
        'error_log'                       => 'syslog',
        'pcre.backtrack_limit'            => 5000000,
        'date.timezone'                   => 'UTC',
        'display_errors'                  => 0,
        'error_reporting'                 => 'E_ALL & ~E_STRICT',
        'mysql'                           => { 'connect_timeout' => 3 },
        'default_socket_timeout'          => 60,
        'session.upload_progress.enabled' => 0,
        'enable_dl'                       => 0,
        'opcache' => {
                'enable' => 1,
                'interned_strings_buffer' => 40,
                'memory_consumption' => 256,
                'max_accelerated_files' => 20000,
                'max_wasted_percentage' => 10,
                'validate_timestamps' => 1,
                'revalidate_freq' => 10,
        },
        'max_execution_time' => 230,
        'post_max_size' => '10M',
        'track_errors' => 'Off',
        'upload_max_filesize' => '10M',
        'zend_extension' => '/usr/local/ioncube/ioncube_loader_lin_8.2.so',
    }

    $cli_config = {
        'zend_extension' => '/usr/local/ioncube/ioncube_loader_lin_8.2.so',
    }

    $core_extensions =  [
        'curl',
        'gd',
        'gmp',
        'imap',
        'intl',
        'mbstring',
        'ldap',
        'pdo_mysql',
        'zip',
    ]

    $php_version = lookup('php::php_version')

    # Install the runtime
    class { '::php':
        ensure         => present,
        version        => $php_version,
        sapis          => ['cli', 'fpm'],
        config_by_sapi => {
            'fpm' => $fpm_config,
            'cli' => $cli_config,
        },
    }

    $core_extensions.each |$extension| {
        php::extension { $extension:
            package_name => "php${php_version}-${extension}",
            sapis        => ['cli', 'fpm'],
        }
    }

    class { '::php::fpm':
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
        'apcu':
            ;
        'mailparse':
            priority     => 21;
        'mysqlnd':
            package_name => '',
            priority     => 10;
        'xml':
            package_name => "php${php_version}-xml",
            priority     => 15;
        'mysqli':
            package_name => "php${php_version}-mysql";
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

    $num_workers = max(floor($facts['processors']['count'] * $fpm_workers_multiplier), $fpm_min_child)
    php::fpm::pool { 'www':
        config => {
            'pm'                        => 'static',
            'pm.max_children'           => $num_workers,
            'request_terminate_timeout' => $request_timeout,
            'request_slowlog_timeout'   => 15,
        }
    }

    nginx::site { 'my.wikiforge.xyz':
        ensure => present,
        source => 'puppet:///modules/whmcs/my.wikiforge.xyz.conf',
    }

    ssl::wildcard { 'phorge wildcard': }

    file { [
        '/srv/whmcs',
        '/usr/local/ioncube',
    ]:
        ensure => 'directory',
        owner  => 'www-data',
        group  => 'www-data',
        mode   => '0755',
    }

    monitoring::services { 'my.wikiforge.xyz HTTPS':
        check_command => 'check_http',
        vars          => {
            http_ssl   => true,
            http_vhost => 'my.wikiforge.xyz',
        },
    }
}
