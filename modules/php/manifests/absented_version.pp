define php::absented_version() {
    ensure_packages(
        "php${title}-common",
        {
            ensure => purged,
        },
    )

    file { "cleanup_php${title}_files":
        ensure  => absent,
        recurse => true,
        force   => true,
        path    => [
            "/etc/php/${title}",
            "/usr/lib/${title}",
            "/usr/share/php/${title}",
            "/var/log/php${title}-fpm",
            "/var/log/php${title}-fpm-shellbox-slowlog.log",
            "/var/log/php${title}-fpm-www-slowlog.log",
            "/var/log/php${title}-fpm.log",
        ],
    }
}
