# role: postgresql
class role::postgresql {

    class { '::postgresql::master':
        root_dir => lookup('postgresql::root_dir', {'default_value' => '/srv/postgres'}),
        use_ssl  => lookup('postgresql::ssl', {'default_value' => false}),
    }

    motd::role { 'role::postgresql':
        description => 'hosting postgresql server',
    }
}
