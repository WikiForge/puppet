# === Class ssl::web
class ssl::web {
    include ssl::nginx

    ensure_packages('python3-filelock')

    file { '/usr/local/bin/renew-ssl':
        ensure => present,
        source => 'puppet:///modules/ssl/wikiforgerenewssl.py',
        mode   => '0755',
    }

    cron { 'check_renew_ssl':
        ensure  => present,
        command => '/usr/local/bin/renew-ssl',
        user    => 'root',
        minute  => '0',
        hour    => '0',
        month   => '*',
        weekday => [ '7' ],
    }
}
