# === Class mediawiki::jobqueue::chron
#
# JobQueue Chron runner on redis masters only
class mediawiki::jobqueue::chron {
    include mediawiki::php
    include mediawiki::jobqueue::shared

    systemd::service { 'jobchron':
        ensure    => present,
        content   => systemd_template('jobchron'),
        subscribe => File['/srv/jobrunner/jobrunner.json'],
        restart   => true,
    }
}
