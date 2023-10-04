class role::bastion {
    motd::role { 'role::bastion':
        description => 'network bastion'
    }

    ferm::service { 'bastion-ssh-public':
        proto => 'tcp',
        port  => '22',
    }

    $squid_access_hosts_str = join(
        query_facts("networking.domain='${facts['networking']['domain']}'", ['networking'])
        .map |$key, $value| {
            "${value['networking']['ip']} ${value['networking']['ip6']}"
        }
        .flatten()
        .unique()
        .sort(),
        ' '
    )
}
