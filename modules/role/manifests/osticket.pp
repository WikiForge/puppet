# role: osticket
class role::osticket {
    include osticket

    $firewall_rules_str = join(
        query_facts('Class[Role::Varnish] or Class[Role::Icinga2]', ['networking'])
        .map |$key, $value| {
            if ( $value['networking']['interfaces']['ens18'] and $value['networking']['interfaces']['ens19'] ) {
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


    motd::role { 'role::osticket':
        description => 'OSTicket Support instance',
    }
}
