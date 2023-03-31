# === Class role::mediawiki
class role::mediawiki (
    Boolean $strict_firewall = lookup('role::mediawiki::use_strict_firewall', {'default_value' => false})
) {
    include role::mediawiki::nutcracker
    include mediawiki

    if $strict_firewall {
        $firewall_rules_str = join(
            query_facts('Class[Role::Mediawiki] or Class[Role::Varnish]', ['ipaddress', 'ipaddress6'])
            .map |$key, $value| {
                "${value['ipaddress']} ${value['ipaddress6']}"
            }
            .flatten()
            .unique()
            .sort(),
            ' '
        )

        ferm::service { 'http':
            proto   => 'tcp',
            port    => '80',
            srange  => "(${firewall_rules_str})",
            notrack => true,
        }

        ferm::service { 'https':
            proto   => 'tcp',
            port    => '443',
            srange  => "(${firewall_rules_str})",
            notrack => true,
        }
    } else {
        ferm::service { 'http':
            proto   => 'tcp',
            port    => '80',
            notrack => true,
        }

        ferm::service { 'https':
            proto   => 'tcp',
            port    => '443',
            notrack => true,
        }
    }

    file { '/opt/amazon-efs-utils-1.35.0-1_all.deb':
        ensure => present,
        source => 'puppet:///modules/role/mediawiki/packages/amazon-efs-utils-1.35.0-1_all.deb',
    }

   package { 'amazon-efs-utils':
        ensure   => installed,
        provider => dpkg,
        source   => '/opt/amazon-efs-utils-1.35.0-1_all.deb',
        require  => File['/opt/amazon-efs-utils-1.35.0-1_all.deb'],
    }

    if !defined(Mount['/mnt/mediawiki-static']) {
        mount { '/mnt/mediawiki-static':
            ensure   => mounted,
            fstype   => 'efs',
            remounts => true,
            device   => 'fs-0a9cb0b1a9bf84b4a:/',
            options  => 'tls',
            require  => Package['amazon-efs-utils'],
        }
    }

    file { '/usr/local/bin/remountStatic.sh':
        ensure => present,
        mode   => '0755',
        source => 'puppet:///modules/role/mediawiki/bin/remountStatic.sh',
    }

    cron { 'check_mount':
        ensure  => present,
        command => '/bin/bash /usr/local/bin/remountStatic.sh',
        user    => 'root',
        minute  => '*/1',
        hour    => '*',
    }

    # Using fastcgi we need more local ports
    sysctl::parameters { 'raise_port_range':
        values   => { 'net.ipv4.ip_local_port_range' => '22500 65535', },
        priority => 90,
    }

    # Allow sockets in TIME_WAIT state to be re-used.
    # This helps prevent exhaustion of ephemeral port or conntrack sessions.
    # See <http://vincent.bernat.im/en/blog/2014-tcp-time-wait-state-linux.html>
    sysctl::parameters { 'tcp_tw_reuse':
        values => { 'net.ipv4.tcp_tw_reuse' => 1 },
    }

    motd::role { 'role::mediawiki':
        description => 'MediaWiki server',
    }
}
