# === Class mediawiki::jobqueue::chron
#
# JobQueue Chron runner on redis masters only
class mediawiki::jobqueue::chron (
    Hash $versions = lookup('mediawiki::multiversion::versions'),
) {
    include mediawiki::php

    $versions.each |$version, $params| {
        if $params['default'] {
            class { 'mediawiki::jobqueue::shared':
                version => $version,
            }
        }
    }

    systemd::service { 'jobchron':
        ensure    => present,
        content   => systemd_template('jobchron'),
        subscribe => File['/srv/jobrunner/jobrunner.json'],
        restart   => true,
    }
}
