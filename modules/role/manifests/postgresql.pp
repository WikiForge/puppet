# role: postgresql
class role::postgresql {

    class { '::postgresql::master':
        root_dir => lookup('postgresql::root_dir', {'default_value' => '/srv/postgres'}),
        use_ssl  => lookup('postgresql::ssl', {'default_value' => false}),
    }

$query_results = query_facts('Class[Role::Puppetserver]', ['networking'])
if $query_results {
  $query_results.each |$key, $value| {
    $ip = $value['networking']['ip']
    $ip6 = $value['networking']['ip6']
    if $ip and $ip6 {
      ferm::service { "postgresql_${key}":
        proto   => 'tcp',
        port    => '5432',
        srange  => "(${ip} ${ip6})",
        notrack => true,
      }
    }
  }
}

    motd::role { 'role::postgresql':
        description => 'hosting postgresql server',
    }
}
