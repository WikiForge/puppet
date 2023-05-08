# === Class ssl::web
class ssl::web {
    include ssl::nginx

    ensure_packages('python3-filelock')

    file { '/usr/local/bin/renew-ssl':
        ensure => present,
        source => 'puppet:///modules/ssl/renewssl.py',
        mode   => '0755',
    }

    file { '/var/log/ssl':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0750',
        before => File['/usr/local/bin/renew-ssl'],
    }

    cron { 'check_renew_ssl':
        ensure  => present,
        command => '/usr/local/bin/renew-ssl --days-before-expiry=14 --only-days --no-confirm',
        user    => 'root',
        minute  => '0',
        hour    => '0',
        month   => '*',
        weekday => [ '7' ],
    }
}
