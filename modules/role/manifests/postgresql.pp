# role: postgresql
class role::postgresql {

    class { '::postgresql::master':
        root_dir => lookup('postgresql::root_dir', {'default_value' => '/srv/postgres'}),
        use_ssl  => lookup('postgresql::ssl', {'default_value' => false}),
    }

$firewall_rules = {}

$query_results = query_facts('Class[Role::Puppetserver]', ['networking'])
if $query_results {
  $query_results.each |$key, $value| {
    $ip = $value['networking']['ip']
    $ip6 = $value['networking']['ip6']
    if $ip and $ip6 {
      $resource_name = "postgresql_${key}"
      $firewall_rules[$resource_name] = {
        proto   => 'tcp',
        port    => '5432',
        srange  => "(${ip} ${ip6})",
        notrack => true,
      }
    }
  }
}

create_resources('ferm::service', $firewall_rules)

    motd::role { 'role::postgresql':
        description => 'hosting postgresql server',
    }
}
