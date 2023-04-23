# class: base
class base {
    include apt
    include base::packages
    include base::puppet
    include base::syslog
    include base::ssl
    include base::sysctl
    include base::timezone
    include base::upgrades
    # include base::firewall
    include ssh
    include users

    if !lookup('dns') {
        include base::dns
    }

    file { '/usr/local/bin/gen_fingerprints':
        ensure => present,
        source => 'puppet:///modules/base/environment/gen_fingerprints',
        mode   => '0555',
    }

    file { '/usr/local/bin/logsalmsg':
        ensure => present,
        source => 'puppet:///modules/base/logsalmsg',
        mode   => '0555',
    }

    class { 'apt::backports':
        include => {
            'deb' => true,
            'src' => true,
        },
    }

    class { 'apt::security': }

    # Used by salt-user
    users::user { 'salt-user':
        ensure     => present,
        uid        => 3100,
        ssh_keys   => [
            'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA19+kKxtUbOfY2nnhlg7c1k+ZHQyxR2PVykYL3zQgB5 salt-user@puppet1'
        ],
        privileges => ['ALL = (ALL) NOPASSWD: ALL'],
    }

    # Global vim defaults
    file { '/etc/vim/vimrc.local':
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/base/environment/vimrc.local',
    }
}
