# === Class ssl::web
class ssl::web {
    include ssl::nginx

    ensure_packages(['python3-flask', 'python3-filelock'])

    file { '/usr/local/bin/mirahezerenewssl.py':
        ensure => present,
        source => 'puppet:///modules/ssl/mirahezerenewssl.py',
        mode   => '0755',
        notify => Service['mirahezerenewssl'],
    }

    systemd::service { 'mirahezerenewssl':
        ensure  => present,
        content => systemd_template('mirahezerenewssl'),
        restart => true,
    }
}
