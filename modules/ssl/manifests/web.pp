# === Class ssl::web
class ssl::web {
    include ssl::nginx

    ensure_packages(['python3-flask', 'python3-filelock'])

    file { '/usr/local/bin/wikiforgerenewssl.py':
        ensure => present,
        source => 'puppet:///modules/ssl/wikiforgerenewssl.py',
        mode   => '0755',
        notify => Service['wikiforgerenewssl'],
    }

    systemd::service { 'wikiforgerenewssl':
        ensure  => present,
        content => systemd_template('wikiforgerenewssl'),
        restart => true,
    }
}
