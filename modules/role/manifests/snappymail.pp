# = Class: role::snappymail
#
# Sets up a web based mail server.
#
class role::snappymail {
    include snappymail

    $cloudflare_ipv4 = split(file('/etc/puppetlabs/puppet/private/files/firewall/cloudflare_ipv4'), /[\r\n]/)
    $cloudflare_ipv6 = split(file('/etc/puppetlabs/puppet/private/files/firewall/cloudflare_ipv6'), /[\r\n]/)

    $firewall_rules_str = join(
        $cloudflare_ipv4 + $cloudflare_ipv6 + query_facts("networking.domain='${facts['networking']['domain']}' and Class[Role::Varnish] or Class[Role::Icinga2]", ['networking'])
        .map |$key, $value| {
            "${value['networking']['ip']} ${value['networking']['ip6']}"
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

    motd::role { 'snappymail':
        description => 'webmail (Snappymail) host',
    }
}
