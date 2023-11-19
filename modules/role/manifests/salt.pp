class role::salt {

    class { '::salt': }

    motd::role { 'role::salt':
        description => 'salt master (salt-ssh)',
    }
}
