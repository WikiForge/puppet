# === Class mediawiki::jobqueue::chron
#
# JobQueue Chron runner on redis masters only
class mediawiki::jobqueue::chron (
    String $version,
) {
    include mediawiki::php

    class { 'mediawiki::jobqueue::shared':
        version => $version,
    }

    systemd::service { 'jobchron':
        ensure    => present,
        content   => systemd_template('jobchron'),
        subscribe => File['/srv/jobrunner/jobrunner.json'],
        restart   => true,
    }
}
