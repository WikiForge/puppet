# class base::puppet
class base::puppet (
    Optional[String] $puppet_cron_time = lookup('puppet_cron_time', {'default_value' => undef}),
    Integer $puppet_major_version = lookup('puppet_major_version', {'default_value' => 7}),
    String $puppetserver_hostname = lookup('puppetserver_hostname', {'default_value' => 'puppet1.wikiforge.net'}),
) {
    $crontime = fqdn_rand(60, 'puppet-params-crontime')

    $architecture = $facts['os']['architecture']

    if $architecture == 'aarch64' {
        # ARM64 architecture, use Puppet
        package { 'puppet':
            ensure  => present,
        }

        $puppet_package = 'puppet'
    } else {
        # Other architecture, use Puppet agent

        file { '/etc/apt/trusted.gpg.d/puppetlabs.gpg':
            ensure => present,
            source => 'puppet:///modules/base/puppet/puppetlabs.gpg',
        }

        apt::source { 'puppetlabs':
            location => 'http://apt.puppetlabs.com',
            repos    => "puppet${puppet_major_version}",
            require  => File['/etc/apt/trusted.gpg.d/puppetlabs.gpg'],
            notify   => Exec['apt_update_puppetlabs'],
        }

        exec {'apt_update_puppetlabs':
            command     => '/usr/bin/apt-get update',
            refreshonly => true,
            logoutput   => true,
        }

        package { 'puppet-agent':
            ensure  => present,
            require => Apt::Source['puppetlabs'],
        }

        $puppet_package = 'puppet-agent'
    }

    # facter needs this for proper "virtual"/"is_virtual" resolution
    ensure_packages('virt-what')

    file { '/usr/bin/facter':
        ensure  => link,
        target  => '/opt/puppetlabs/bin/facter',
        require => Package[$puppet_package],
    }

    file { '/usr/bin/hiera':
        ensure  => link,
        target  => '/opt/puppetlabs/bin/hiera',
        require => Package[$puppet_package],
    }

    file { '/usr/bin/puppet':
        ensure  => 'link',
        target  => '/opt/puppetlabs/bin/puppet',
        require => Package[$puppet_package],
    }

    file { '/var/log/puppet':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0750',
    }

    file { '/usr/local/sbin/puppet-run':
        mode    => '0555',
        owner   => 'root',
        group   => 'root',
        content => template('base/puppet/puppet-run.erb'),
        require => File['/var/log/puppet'],
    }

    file { '/etc/cron.d/puppet':
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => template('base/puppet/puppet.cron.erb'),
        require => File['/usr/local/sbin/puppet-run'],
    }

    logrotate::conf { 'puppet':
        ensure => present,
        source => 'puppet:///modules/base/puppet/puppetlabs.puppet.logrotate.conf',
    }

    if !lookup('puppetserver') {
        file { '/etc/puppetlabs/puppet/puppet.conf':
            ensure  => present,
            content => template('base/puppet/puppet.conf.erb'),
            mode    => '0444',
            require => Package[$puppet_package],
        }
    }

    service { 'puppet':
        ensure => stopped,
        enable => false,
    }

    file { '/usr/local/bin/puppet-enabled':
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/base/puppet/puppet-enabled',
    }

    motd::script { 'last-puppet-run':
        ensure   => present,
        priority => 97,
        source   => 'puppet:///modules/base/puppet/97-last-puppet-run',
    }
}
