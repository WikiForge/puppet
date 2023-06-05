# === Class role::services
#
# Sets up Citoid, Proton and RESTBase.
class role::services {
    include services::citoid
    include services::proton
    include services::restbase

    $firewall_mediawiki_rules_str = join(
        query_facts('Class[Role::Mediawiki] or Class[Role::Services]', ['ipaddress', 'ipaddress6'])
        .map |$key, $value| {
            "${value['ipaddress']} ${value['ipaddress6']}"
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

    motd::role { 'role::services':
        description => 'Hosting MediaWiki services (citoid, proton, restbase)',
    }
}
