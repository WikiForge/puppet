# define: ssl::wildcard
define ssl::wildcard (
    $ssl_cert_path = '/etc/ssl/localcerts',
    $ssl_cert_key_private_path = '/etc/ssl/private',
    $ssl_cert_key_private_group = 'ssl-cert',
) {

    if !defined(File[$ssl_cert_path]) {
        file { $ssl_cert_path:
            ensure  => directory,
            owner   => 'root',
            group   => $ssl_cert_key_private_group,
            mode    => '0775',
            require => Package['ssl-cert'],
        }
    }

    if defined(Service['nginx']) {
        $restart_nginx = Service['nginx']
    } else {
        $restart_nginx = undef
    }

    if !defined(File["${ssl_cert_path}/wildcard.wikiforge.net.crt"]) {
        file { "${ssl_cert_path}/wildcard.wikiforge.net.crt":
            ensure => 'present',
            source => 'puppet:///ssl/certificates/wildcard.wikiforge.net.crt',
            notify => $restart_nginx,
        }
    }

    if !defined(File["${ssl_cert_key_private_path}/wildcard.wikiforge.net.key"]) {
        file { "${ssl_cert_key_private_path}/wildcard.wikiforge.net.key":
            ensure    => 'present',
            source    => 'puppet:///ssl-keys/wildcard.wikiforge.net.key',
            owner     => 'root',
            group     => $ssl_cert_key_private_group,
            mode      => '0660',
            show_diff => false,
            notify    => $restart_nginx,
        }
    }

    if !defined(File["${ssl_cert_path}/wikiforge.work.crt"]) {
        file { "${ssl_cert_path}/wikiforge.work.crt":
            ensure => 'present',
            source => 'puppet:///ssl/certificates/wikiforge.work.crt',
            notify => $restart_nginx,
        }
    }

    if !defined(File["${ssl_cert_key_private_path}/wikiforge.work.key"]) {
        file { "${ssl_cert_key_private_path}/wikiforge.work.key":
            ensure    => 'present',
            source    => 'puppet:///ssl-keys/wikiforge.work.key',
            owner     => 'root',
            group     => $ssl_cert_key_private_group,
            mode      => '0660',
            show_diff => false,
            notify    => $restart_nginx,
        }
    }
}
