# class: phorge
class phorge (
  Integer $request_timeout = lookup('phorge::php::request_timeout', {'default_value' => 60}),
) {
    ensure_packages(['python3-pygments', 'subversion'])

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
    }

    $core_extensions =  [
        'curl',
        'gd',
        'gmp',
        'intl',
        'mbstring',
        'ldap',
        'zip',
    ]

    $php_version = lookup('php::php_version', {'default_value' => '7.4'})

    # Install the runtime
    class { '::php':
        ensure         => present,
        version        => $php_version,
        sapis          => ['cli', 'fpm'],
        config_by_sapi => {
            'fpm' => $fpm_config,
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

    $password = lookup('passwords::irc::wikiforgebots')

    nginx::site { 'support.wikiforge.net':
        ensure  => present,
        source  => 'puppet:///modules/phorge/support.wikiforge.net.conf',
    }

    ssl::wildcard { 'phorge wildcard': }

    file { '/srv/phorge':
        ensure => directory,
    }

    git::clone { 'arcanist':
        ensure    => present,
        directory => '/srv/phorge/arcanist',
        origin    => 'https://github.com/phacility/arcanist.git',
        require   => File['/srv/phorge'],
    }

    git::clone { 'phorge':
        ensure    => present,
        directory => '/srv/phorge/phorge',
        origin    => 'https://we.phorge.it/source/phorge.git',
        require   => File['/srv/phorge'],
    }

    git::clone { 'phorge-extensions':
        ensure    => latest,
        directory => '/srv/phorge/phorge/src/extensions',
        origin    => 'https://github.com/WikiForge/phorge-extensions.git',
        require   => File['/srv/phorge'],
    }

    file { '/srv/phorge/repos':
        ensure => directory,
        mode   => '0755',
        owner  => 'www-data',
        group  => 'www-data',
    }

    file { '/srv/phorge/images':
        ensure => directory,
        mode   => '0755',
        owner  => 'www-data',
        group  => 'www-data',
    }

    $module_path = get_module_path($module_name)
    $phorge_yaml = loadyaml("${module_path}/data/config.yaml")
    $phorge_private = {
        'mysql.pass' => lookup('passwords::db::phorge'),
    }

    $phorge_setting = {
        # smtp
        'cluster.mailers'      => [
            {
                'key'          => 'wikiforge-smtp',
                'type'         => 'smtp',
                'options'      => {
                    'host'     => 'email-smtp.us-east-1.amazonaws.com',
                    'port'     => 587,
                    'user'     => 'noreply',
                    'password' => lookup('passwords::mail::noreply'),
                    'protocol' => 'tls',
                },
            },
        ],
    }

    $phorge_settings = merge($phorge_yaml, $phorge_private, $phorge_setting)

    file { '/srv/phorge/phorge/conf/local/local.json':
        ensure  => present,
        content => template('phorge/local.json.erb'),
        notify  => Service['phd'],
        require => Git::Clone['phorge'],
    }

    systemd::service { 'phd':
        ensure  => present,
        content => systemd_template('phd'),
        restart => true,
        require => File['/srv/phorge/phorge/conf/local/local.json'],
    }
}
