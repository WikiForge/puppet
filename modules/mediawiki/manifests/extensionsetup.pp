# === Define mediawiki::extensionsetup
define mediawiki::extensionsetup (
    String $branch,
    String $version,
) {
    ensure_packages('composer')

    $mwpath = "/srv/mediawiki-staging/${version}"

    file { [
        "/srv/mediawiki/${version}/extensions/OAuth/.composer/cache",
        "/srv/mediawiki-staging/${version}/extensions/OAuth/.composer/cache",
        "/srv/mediawiki/${version}/extensions/OAuth/vendor/league/oauth2-server/.git",
        "/srv/mediawiki-staging/${version}/extensions/OAuth/vendor/league/oauth2-server/.git"]:
            ensure  => absent,
            force   => true,
            recurse => true,
            require => Exec["OAuth-${branch} composer"],
    }

    $module_path = get_module_path($module_name)
    $repos = loadyaml("${module_path}/data/mediawiki-repos.yaml")

    $repos.each |$name, $params| {
        git::clone { "MediaWiki-${branch} ${name}":
            ensure             => $params['removed'] ? {
                true    => absent,
                default => $params['latest'] ? {
                    true    => latest,
                    default => present,
                },
            },
            directory          => "${mwpath}/${params['path']}",
            origin             => $params['repo_url'],
            branch             => $params['branch'] ? {
                '_branch_' => $branch == 'master' ? {
                    true => $params['alpha_branch'] ? {
                        undef   => $branch,
                        default => $params['alpha_branch'],
                    },
                    default => $branch,
                },
                default    => $params['branch'],
            },
            owner              => 'www-data',
            group              => 'www-data',
            mode               => '0755',
            depth              => '5',
            recurse_submodules => true,
            shallow_submodules => $params['shallow_submodules'] ? {
                true    => true,
                default => false,
            },
            require            => Git::Clone["MediaWiki-${branch} core"],
        }

        if $params['composer'] {
            exec { "${name}-${branch} composer":
                command     => 'composer install --no-dev',
                creates     => "${mwpath}/${params['path']}/vendor",
                cwd         => "${mwpath}/${params['path']}",
                path        => '/usr/bin',
                environment => "HOME=${mwpath}/${params['path']}",
                user        => 'www-data',
                require     => Git::Clone["MediaWiki-${branch} ${name}"],
            }
        }

        if $params['latest'] {
            exec { "MediaWiki-${branch} ${name} Sync":
                command     => "/usr/local/bin/mwdeploy --folders=${version}/${params['path']} --servers=${lookup(mediawiki::default_sync)} --no-log",
                cwd         => '/srv/mediawiki-staging',
                refreshonly => true,
                user        => 'www-data',
                subscribe   => Git::Clone["MediaWiki-${branch} ${name}"],
                require     => File['/usr/local/bin/mwdeploy'],
            }
        }
    }

    file { "${mwpath}/composer.local.json":
        ensure  => present,
        owner   => 'www-data',
        group   => 'www-data',
        mode    => '0664',
        source  => 'puppet:///modules/mediawiki/composer.local.json',
        require => Git::Clone["MediaWiki-${branch} core"],
    }
}
