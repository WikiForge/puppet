class prometheus::exporter::cadvisor {
    file { '/opt/cadvisor_0.38.7+ds1-2+b7_amd64.deb':
        ensure => present,
        source => 'puppet:///modules/prometheus/packages/cadvisor_0.38.7+ds1-2+b7_amd64.deb',
    }

    package { 'cadvisor':
        ensure   => installed,
        provider => dpkg,
        source   => '/opt/cadvisor_0.38.7+ds1-2+b7_amd64.deb',
        require  => File['/opt/cadvisor_0.38.7+ds1-2+b7_amd64.deb'],
    }

    systemd::service { 'cadvisor':
        content   => init_template('cadvisor', 'systemd_override'),
        override  => true,
        restart   => true,
        subscribe => Package['cadvisor'],
    }

    $firewall_rules_str = join(
        query_facts("networking.domain='${facts['networking']['domain']}' and Class[Role::Prometheus] or Class[Role::Grafana]", ['networking'])
        .map |$key, $value| {
            "${value['networking']['ip']} ${value['networking']['ip6']}"
        }
        .flatten()
        .unique()
        .sort(),
        ' '
    )
    ferm::service { 'prometheus cadvisor_exporter':
        proto  => 'tcp',
        port   => '4194',
        srange => "(${firewall_rules_str})",
    }
}
