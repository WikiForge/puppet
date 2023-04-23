# === Class mediawiki::jobqueue::runner
#
# Defines a jobrunner process for jobrunner selected machine only.
class mediawiki::jobqueue::runner (
    String $version,
) {
    class { 'mediawiki::jobqueue::shared':
        version => $version,
    }

    $wiki = lookup('mediawiki::jobqueue::wiki')
    ensure_packages('python3-xmltodict')


    systemd::service { 'jobrunner':
        ensure    => present,
        content   => systemd_template('jobrunner'),
        subscribe => File['/srv/jobrunner/jobrunner.json'],
        restart   => true,
    }

    if lookup('mediawiki::jobqueue::runner::cron', {'default_value' => false}) {
        cron { 'purge_checkuser':
            ensure  => present,
            command => "/usr/local/bin/foreachwikiindblist /srv/mediawiki/cache/databases.json /srv/mediawiki/${version}/extensions/CheckUser/maintenance/purgeOldData.php >> /var/log/mediawiki/cron/purge_checkuser.log",
            user    => 'www-data',
            minute  => '5',
            hour    => '6',
        }

        cron { 'purge_abusefilter':
            ensure  => present,
            command => "/usr/local/bin/foreachwikiindblist /srv/mediawiki/cache/databases.json /srv/mediawiki/${version}/extensions/AbuseFilter/maintenance/PurgeOldLogIPData.php >> /var/log/mediawiki/cron/purge_abusefilter.log",
            user    => 'www-data',
            minute  => '5',
            hour    => '18',
        }

        cron { 'managewikis':
            ensure  => present,
            command => "/usr/bin/php /srv/mediawiki/${version}/extensions/CreateWiki/maintenance/manageInactiveWikis.php --wiki ${wiki} --write >> /var/log/mediawiki/cron/managewikis.log",
            user    => 'www-data',
            minute  => '5',
            hour    => '12',
        }

        cron { 'update rottenlinks on all wikis':
            ensure   => present,
            command  => "/usr/local/bin/fileLockScript.sh /tmp/rotten_links_file_lock \"/usr/bin/nice -n 15 /usr/local/bin/foreachwikiindblist /srv/mediawiki/cache/databases.json /srv/mediawiki/${version}/extensions/RottenLinks/maintenance/updateExternalLinks.php\"",
            user     => 'www-data',
            minute   => '0',
            hour     => '0',
            month    => '*',
            monthday => [ '14', '28' ],
        }

        cron { 'generate sitemaps for all wikis':
            ensure  => present,
            command => "/usr/local/bin/foreachwikiindblist /srv/mediawiki/cache/databases.json /srv/mediawiki/${version}/extensions/WikiForgeMagic/maintenance/generateWikiForgeSitemap.php",
            user    => 'www-data',
            minute  => '0',
            hour    => '0',
            month   => '*',
            weekday => [ '6' ],
        }

        if $wiki == 'metawiki' {
            cron { 'generate sitemap index':
                ensure  => present,
                command => "/usr/bin/python3 /srv/mediawiki/${version}/extensions/WikiForgeMagic/py/generateSitemapIndex.py",
                user    => 'www-data',
                minute  => '0',
                hour    => '0',
                month   => '*',
                weekday => [ '7' ],
            }

            cron { 'purge_parsercache':
                ensure  => present,
                command => "/usr/bin/php /srv/mediawiki/${version}/maintenance/purgeParserCache.php --age 432000 --msleep 200 --wiki metawiki",
                user    => 'www-data',
                special => 'daily',
            }
        }

        cron { 'update_statistics':
            ensure   => present,
            command  => "/usr/local/bin/foreachwikiindblist /srv/mediawiki/cache/databases.json /srv/mediawiki/${version}/maintenance/initSiteStats.php --update --active > /dev/null",
            user     => 'www-data',
            minute   => '0',
            hour     => '5',
            monthday => [ '1', '15' ],
        }

        cron { 'update_sites':
            ensure   => present,
            command  => "/usr/local/bin/foreachwikiindblist /srv/mediawiki/cache/databases.json /srv/mediawiki/${version}/extensions/WikiForgeMagic/maintenance/populateWikibaseSitesTable.php > /dev/null",
            user     => 'www-data',
            minute   => '0',
            hour     => '5',
            monthday => [ '5', '20' ],
        }

        cron { 'clean_gu_cache':
            ensure   => present,
            command  => "/usr/local/bin/foreachwikiindblist /srv/mediawiki/cache/databases.json /srv/mediawiki/${version}/extensions/GlobalUsage/maintenance/refreshGlobalimagelinks.php --pages=existing,nonexisting > /dev/null",
            user     => 'www-data',
            minute   => '0',
            hour     => '5',
            monthday => [ '6', '21' ],
        }
    }
}
