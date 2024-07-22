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

    if !defined(File["${ssl_cert_path}/wikiforge.net.crt"]) {
        file { "${ssl_cert_path}/wikiforge.net.crt":
            ensure => 'present',
            source => 'puppet:///ssl/certificates/wikiforge.net.crt',
            notify => $restart_nginx,
        }
    }

    if !defined(File["${ssl_cert_key_private_path}/wikiforge.net.key"]) {
        file { "${ssl_cert_key_private_path}/wikiforge.net.key":
            ensure    => 'present',
            source    => 'puppet:///ssl-keys/wikiforge.net.key',
            owner     => 'root',
            group     => $ssl_cert_key_private_group,
            mode      => '0660',
            show_diff => false,
            notify    => $restart_nginx,
        }
    }

    if !defined(File["${ssl_cert_path}/wikiforge.xyz.crt"]) {
        file { "${ssl_cert_path}/wikiforge.xyz.crt":
            ensure => 'present',
            source => 'puppet:///ssl/certificates/wikiforge.xyz.crt',
            notify => $restart_nginx,
        }
    }

    if !defined(File["${ssl_cert_key_private_path}/wikiforge.xyz.key"]) {
        file { "${ssl_cert_key_private_path}/wikiforge.xyz.key":
            ensure    => 'present',
            source    => 'puppet:///ssl-keys/wikiforge.xyz.key',
            owner     => 'root',
            group     => $ssl_cert_key_private_group,
            mode      => '0660',
            show_diff => false,
            notify    => $restart_nginx,
        }
    }

    if !defined(File["${ssl_cert_path}/inside.wf.crt"]) {
        file { "${ssl_cert_path}/inside.wf.crt":
            ensure => 'present',
            source => 'puppet:///ssl/certificates/inside.wf.crt',
            notify => $restart_nginx,
        }
    }

    if !defined(File["${ssl_cert_key_private_path}/inside.wf.key"]) {
        file { "${ssl_cert_key_private_path}/inside.wf.key":
            ensure    => 'present',
            source    => 'puppet:///ssl-keys/inside.wf.key',
            owner     => 'root',
            group     => $ssl_cert_key_private_group,
            mode      => '0660',
            show_diff => false,
            notify    => $restart_nginx,
        }
    }

    if !defined(File["${ssl_cert_path}/your.wf.crt"]) {
        file { "${ssl_cert_path}/your.wf.crt":
            ensure => 'present',
            source => 'puppet:///ssl/certificates/your.wf.crt',
            notify => $restart_nginx,
        }
    }

    if !defined(File["${ssl_cert_key_private_path}/your.wf.key"]) {
        file { "${ssl_cert_key_private_path}/your.wf.key":
            ensure    => 'present',
            source    => 'puppet:///ssl-keys/your.wf.key',
            owner     => 'root',
            group     => $ssl_cert_key_private_group,
            mode      => '0660',
            show_diff => false,
            notify    => $restart_nginx,
        }
    }
}
