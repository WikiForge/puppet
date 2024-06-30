# === Class role::mediawiki
class role::mediawiki (
    Boolean $strict_firewall = lookup('role::mediawiki::use_strict_firewall', {'default_value' => false})
) {
    include prometheus::exporter::cadvisor

    include role::mediawiki::nutcracker
    include mediawiki

    if $strict_firewall {
        $cloudflare_ipv4 = split(file('/etc/puppetlabs/puppet/private/files/firewall/cloudflare_ipv4'), /[\r\n]/)
        $cloudflare_ipv6 = split(file('/etc/puppetlabs/puppet/private/files/firewall/cloudflare_ipv6'), /[\r\n]/)

        $firewall_rules_str = join(
            $cloudflare_ipv4 + $cloudflare_ipv6 + query_facts('Class[Role::Mediawiki] or Class[Role::Varnish] or Class[Role::Icinga2] or Class[Role::Prometheus] or Class[Role::Bastion]', ['networking'])
            .map |$key, $value| {
                if ( $value['networking']['interfaces']['en18'] and $value['networking']['interfaces']['ens19'] ) {
                    "${value['networking']['interfaces']['ens18']['ip']} ${value['networking']['interfaces']['ens19']['ip']} ${value['networking']['interfaces']['ens19']['ip6']}"
                } elsif ( $value['networking']['interfaces']['ens18'] ) {
                    "${value['networking']['interfaces']['ens18']['ip']}"
                } else {
                    "${value['networking']['ip']} ${value['networking']['ip6']}"
                }
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
