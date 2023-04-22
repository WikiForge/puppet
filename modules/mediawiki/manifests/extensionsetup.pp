# === Class mediawiki::extensionsetup
class mediawiki::extensionsetup {
    ensure_packages('composer')

    $mwpath = '/srv/mediawiki-staging/w'
    file { [
        '/srv/mediawiki/w/extensions/OAuth/.composer/cache',
        '/srv/mediawiki-staging/w/extensions/OAuth/.composer/cache',
        '/srv/mediawiki/w/extensions/OAuth/vendor/league/oauth2-server/.git',
        '/srv/mediawiki-staging/w/extensions/OAuth/vendor/league/oauth2-server/.git']:
            ensure  => absent,
            force   => true,
            recurse => true,
            require => Exec['oauth_composer'],
    }

    $module_path = get_module_path($module_name)
    $repos = loadyaml("${module_path}/data/mediawiki-repos.yaml")

    $repos.each |$name, $params| {
        git::clone { "MediaWiki ${name}":
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
                '_branch_' => lookup('mediawiki::branch'),
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
            require            => Git::Clone['MediaWiki core'],
        }

        if $params['latest'] {
            exec { "MediaWiki ${name} Sync":
                command     => "/usr/local/bin/deploy-mediawiki --folders=w/${params['path']} --servers=${lookup(mediawiki::default_sync)} --no-log",
                cwd         => '/srv/mediawiki-staging',
                refreshonly => true,
                user        => www-data,
                subscribe   => Git::Clone["MediaWiki ${name}"],
                require     => File['/usr/local/bin/deploy-mediawiki'],
            }
        }
    }

    $composer = 'composer install --no-dev'

    exec { 'vendor_psysh_composer':
        command     => 'composer require "psy/psysh:0.11.8" --update-no-dev',
        unless      => 'composer show --installed psy/psysh 0.11.8',
        cwd         => "${mwpath}/vendor",
        path        => '/usr/bin',
        environment => [
            "HOME=${mwpath}/vendor",
        ],
        user        => 'www-data',
        require     => Git::Clone['MediaWiki vendor'],
    }

    exec { 'wikibase_composer':
        command     => $composer,
        creates     => "${mwpath}/extensions/Wikibase/vendor",
        cwd         => "${mwpath}/extensions/Wikibase",
        path        => '/usr/bin',
        environment => [
            "HOME=${mwpath}/extensions/Wikibase",
        ],
        user        => 'www-data',
        require     => Git::Clone['MediaWiki Wikibase'],
    }

    exec { 'maps_composer':
        command     => $composer,
        creates     => "${mwpath}/extensions/Maps/vendor",
        cwd         => "${mwpath}/extensions/Maps",
        path        => '/usr/bin',
        environment => [
            "HOME=${mwpath}/extensions/Maps",
        ],
        user        => 'www-data',
        require     => Git::Clone['MediaWiki Maps'],
    }

    exec { 'flow_composer':
        command     => $composer,
        creates     => "${mwpath}/extensions/Flow/vendor",
        cwd         => "${mwpath}/extensions/Flow",
        path        => '/usr/bin',
        environment => [
            "HOME=${mwpath}/extensions/Flow",
        ],
        user        => 'www-data',
        require     => Git::Clone['MediaWiki Flow'],
    }
    exec { 'ipinfo_composer':
        command     => $composer,
        creates     => "${mwpath}/extensions/IPInfo/vendor",
        cwd         => "${mwpath}/extensions/IPInfo",
        path        => '/usr/bin',
        environment => [
            "HOME=${mwpath}/extensions/IPInfo",
        ],
        user        => 'www-data',
        require     => Git::Clone['MediaWiki IPInfo'],
    }

    exec { 'oauth_composer':
        command     => $composer,
        creates     => "${mwpath}/extensions/OAuth/vendor",
        cwd         => "${mwpath}/extensions/OAuth",
        path        => '/usr/bin',
        environment => [
            "HOME=${mwpath}/extensions/OAuth",
        ],
        user        => 'www-data',
        require     => Git::Clone['MediaWiki OAuth'],
    }

    exec { 'oauth_lcobucci_composer':
        command     => 'composer require "lcobucci/jwt:4.1.5" --update-no-dev',
        unless      => 'composer show --installed lcobucci/jwt 4.1.5',
        cwd         => "${mwpath}/extensions/OAuth",
        path        => '/usr/bin',
        environment => [
            "HOME=${mwpath}/extensions/OAuth",
        ],
        user        => 'www-data',
        require     => Exec['oauth_composer'],
    }

    exec { 'templatestyles_composer':
        command     => $composer,
        creates     => "${mwpath}/extensions/TemplateStyles/vendor",
        cwd         => "${mwpath}/extensions/TemplateStyles",
        path        => '/usr/bin',
        environment => [
            "HOME=${mwpath}/extensions/TemplateStyles",
        ],
        user        => 'www-data',
        require     => Git::Clone['MediaWiki TemplateStyles'],
    }

    exec { 'antispoof_composer':
        command     => $composer,
        creates     => "${mwpath}/extensions/AntiSpoof/vendor",
        cwd         => "${mwpath}/extensions/AntiSpoof",
        path        => '/usr/bin',
        environment => [
            "HOME=${mwpath}/extensions/AntiSpoof",
        ],
        user        => 'www-data',
        require     => Git::Clone['MediaWiki AntiSpoof'],
    }

    exec { 'kartographer_composer':
        command     => $composer,
        creates     => "${mwpath}/extensions/Kartographer/vendor",
        cwd         => "${mwpath}/extensions/Kartographer",
        path        => '/usr/bin',
        environment => [
            "HOME=${mwpath}/extensions/Kartographer",
        ],
        user        => 'www-data',
        require     => Git::Clone['MediaWiki Kartographer'],
    }

    exec { 'timedmediahandler_composer':
        command     => $composer,
        creates     => "${mwpath}/extensions/TimedMediaHandler/vendor",
        cwd         => "${mwpath}/extensions/TimedMediaHandler",
        path        => '/usr/bin',
        environment => [
            "HOME=${mwpath}/extensions/TimedMediaHandler",
        ],
        user        => 'www-data',
        require     => Git::Clone['MediaWiki TimedMediaHandler'],
    }

    exec { 'translate_composer':
        command     => $composer,
        creates     => "${mwpath}/extensions/Translate/vendor",
        cwd         => "${mwpath}/extensions/Translate",
        path        => '/usr/bin',
        environment => [
            "HOME=${mwpath}/extensions/Translate",
        ],
        user        => 'www-data',
        require     => Git::Clone['MediaWiki Translate'],
    }

    exec { 'oathauth_composer':
        command     => $composer,
        creates     => "${mwpath}/extensions/OATHAuth/vendor",
        cwd         => "${mwpath}/extensions/OATHAuth",
        path        => '/usr/bin',
        environment => [
            "HOME=${mwpath}/extensions/OATHAuth",
        ],
        user        => 'www-data',
        require     => Git::Clone['MediaWiki OATHAuth'],
    }

    exec { 'lingo_composer':
        command     => $composer,
        creates     => "${mwpath}/extensions/Lingo/vendor",
        cwd         => "${mwpath}/extensions/Lingo",
        path        => '/usr/bin',
        environment => [
            "HOME=${mwpath}/extensions/Lingo",
        ],
        user        => 'www-data',
        require     => Git::Clone['MediaWiki Lingo'],
    }

    exec { 'wikibasequalityconstraints_composer':
        command     => $composer,
        creates     => "${mwpath}/extensions/WikibaseQualityConstraints/vendor",
        cwd         => "${mwpath}/extensions/WikibaseQualityConstraints",
        path        => '/usr/bin',
        environment => [
            "HOME=${mwpath}/extensions/WikibaseQualityConstraints",
        ],
        user        => 'www-data',
        require     => Git::Clone['MediaWiki WikibaseQualityConstraints'],
    }

    exec { 'wikibaselexeme_composer':
        command     => $composer,
        creates     => "${mwpath}/extensions/WikibaseLexeme/vendor",
        cwd         => "${mwpath}/extensions/WikibaseLexeme",
        path        => '/usr/bin',
        environment => [
            "HOME=${mwpath}/extensions/WikibaseLexeme",
        ],
        user        => 'www-data',
        require     => Git::Clone['MediaWiki WikibaseLexeme'],
    }

    exec { 'createwiki_composer':
        command     => $composer,
        creates     => "${mwpath}/extensions/CreateWiki/vendor",
        cwd         => "${mwpath}/extensions/CreateWiki",
        path        => '/usr/bin',
        environment => [
            "HOME=${mwpath}/extensions/CreateWiki",
        ],
        user        => 'www-data',
        require     => Git::Clone['MediaWiki CreateWiki'],
    }

    exec { 'datatransfer_composer':
        command     => 'composer require phpoffice/phpspreadsheet',
        creates     => "${mwpath}/extensions/DataTransfer/vendor",
        cwd         => "${mwpath}/extensions/DataTransfer",
        path        => '/usr/bin',
        environment => [
            "HOME=${mwpath}/extensions/DataTransfer",
        ],
        user        => 'www-data',
        require     => Git::Clone['MediaWiki DataTransfer'],
    }

    exec { 'bootstrap_composer':
        command     => $composer,
        creates     => "${mwpath}/extensions/Bootstrap/vendor",
        cwd         => "${mwpath}/extensions/Bootstrap",
        path        => '/usr/bin',
        environment => [
            "HOME=${mwpath}/extensions/Bootstrap",
        ],
        user        => 'www-data',
        require     => Git::Clone['MediaWiki Bootstrap'],
    }

    exec { 'structurednavigation_composer':
        command     => $composer,
        creates     => "${mwpath}/extensions/StructuredNavigation/vendor",
        cwd         => "${mwpath}/extensions/StructuredNavigation",
        path        => '/usr/bin',
        environment => [
            "HOME=${mwpath}/extensions/StructuredNavigation",
        ],
        user        => 'www-data',
        require     => Git::Clone['MediaWiki StructuredNavigation'],
    }

    exec { 'semanticmediawiki_composer':
        command     => $composer,
        creates     => "${mwpath}/extensions/SemanticMediaWiki/vendor",
        cwd         => "${mwpath}/extensions/SemanticMediaWiki",
        path        => '/usr/bin',
        environment => [
            "HOME=${mwpath}/extensions/SemanticMediaWiki",
        ],
        user        => 'www-data',
        require     => Git::Clone['MediaWiki SemanticMediaWiki'],
    }

    exec { 'chameleon_composer':
        command     => 'composer require jeroen/file-fetcher',
        creates     => "${mwpath}/skins/chameleon/vendor",
        cwd         => "${mwpath}/skins/chameleon",
        path        => '/usr/bin',
        environment => [
            "HOME=${mwpath}/skins/chameleon",
        ],
        user        => 'www-data',
        require     => Git::Clone['MediaWiki chameleon'],
    }

    exec { 'pageproperties_composer':
        command     => $composer,
        creates     => "${mwpath}/extensions/PageProperties/vendor",
        cwd         => "${mwpath}/extensions/PageProperties",
        path        => '/usr/bin',
        environment => [
            "HOME=${mwpath}/extensions/PageProperties",
        ],
        user        => 'www-data',
        require     => Git::Clone['MediaWiki PageProperties'],
    }

    exec { 'WikibaseEdtf_composer':
        command     => $composer,
        creates     => "${mwpath}/extensions/WikibaseEdtf/vendor",
        cwd         => "${mwpath}/extensions/WikibaseEdtf",
        path        => '/usr/bin',
        environment => [
            "HOME=${mwpath}/extensions/WikibaseEdtf",
        ],
        user        => 'www-data',
        require     => Git::Clone['MediaWiki WikibaseEdtf'],
    }
}
