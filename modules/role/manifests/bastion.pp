class role::bastion {
    motd::role { 'role::bastion':
        description => 'network bastion'
    }

    ferm::service { 'bastion-ssh-public':
        proto => 'tcp',
        port  => '22',
    }
}
