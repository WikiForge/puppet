class mediawiki::multiversion (
    Hash $versions = lookup('mediawiki::multiversion::versions', {'default_value' => {}}),
) {
    file { '/srv/mediawiki/femiwiki-deploy':
        ensure => 'directory',
        owner  => 'www-data',
        group  => 'www-data',
    }

    $versions.each |$version, $params| {
        if lookup(mediawiki::use_staging) {
            class { 'mediawiki::deploy':
                branch  => $params['branch'],
                version => $version,
            }
        }

        # Create mediawiki directory for each version
        file { "/srv/mediawiki/${version}":
            ensure => 'directory',
            owner  => 'www-data',
            group  => 'www-data',
        }

        git::clone { "femiwiki-deploy-${version}":
            ensure    => 'latest',
            directory => "/srv/mediawiki/femiwiki-deploy/${version}",
            origin    => 'https://github.com/miraheze/femiwiki-deploy',
            branch    => $params['branch'],
            owner     => 'www-data',
            group     => 'www-data',
            mode      => '0755',
            require   => File['/srv/mediawiki/femiwiki-deploy'],
        }

        # Create symbolic links for shared files using version's configuration
        file { "/srv/mediawiki/${version}/skins/Femiwiki/node_modules":
            ensure  => 'link',
            target  => "/srv/mediawiki/femiwiki-deploy/${version}/node_modules",
            owner   => 'www-data',
            group   => 'www-data',
            require => [
                Git::Clone["femiwiki-deploy-${version}"],
                File["/srv/mediawiki/${version}"],
            ],
        }

        file { "/srv/mediawiki/${version}/LocalSettings.php":
            ensure  => 'link',
            target  => "/srv/mediawiki/config/LocalSettings.php",
            owner   => 'www-data',
            group   => 'www-data',
            require => [
                File["/srv/mediawiki/${version}"],
                File['/srv/mediawiki/config'],
            ],
        }
    }
}
