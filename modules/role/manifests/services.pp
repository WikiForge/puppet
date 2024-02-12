# === Class role::services
#
# Sets up Citoid, Mathoid, Proton and RESTBase.
class role::services {
    include services::citoid
    include services::mathoid
    include services::proton
    include services::restbase

    $firewall_mediawiki_rules_str = join(
        query_facts("networking.domain='${facts['networking']['domain']}' and (Class[Role::Mediawiki] or Class[Role::Services])", ['networking'])
        .map |$key, $value| {
            "${value['networking']['ip']} ${value['networking']['ip6']}"
        }
        .flatten()
        .unique()
        .sort(),
        ' '
    )

    ferm::service { 'mediawiki access 443':
        proto  => 'tcp',
        port   => '443',
        srange => "(${firewall_mediawiki_rules_str})",
    }

    $firewall_rules_str = join(
        query_facts('Class[Role::Mediawiki] or Class[Role::Icinga2]', ['networking'])
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
    ferm::service { 'mathoid':
        proto   => 'tcp',
        port    => '10044',
        srange  => "(${firewall_rules_str})",
        notrack => true,
    }

    motd::role { 'role::services':
        description => 'MediaWiki services (Citoid, Mathoid, Proton, RESTbase) server',
    }
}
