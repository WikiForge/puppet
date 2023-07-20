# role: postgresql
class role::postgresql {

    class { '::postgresql::master':
        root_dir => lookup('postgresql::root_dir', {'default_value' => '/srv/postgres'}),
        use_ssl  => lookup('postgresql::ssl', {'default_value' => false}),
    }

    $firewall_rules = query_facts('Class[Role::Puppetserver]', ['networking'])
        .map |$key, $value| {
            { "postgresql_${key}":
                proto   => 'tcp',
                port    => '5432',
                srange  => "(${value['networking']['ip']} ${value['networking']['ip6']})",
                notrack => true,
             }
      }
      .flatten()
      .unique()

    create_resources('ferm::service', $firewall_rules)

    motd::role { 'role::postgresql':
        description => 'hosting postgresql server',
    }
}
