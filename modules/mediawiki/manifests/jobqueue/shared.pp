# === Class mediawiki::jobqueue::shared
#
# JobQueue resources for both runner & chron
class mediawiki::jobqueue::shared (
    String $version,
) {
    $runner = ''
    if versioncmp($version, '1.40') >= 0 {
        $runner = "/srv/mediawiki/${version}/maintenance/run.php "
    }

    git::clone { 'JobRunner':
        ensure    => latest,
        directory => '/srv/jobrunner',
        origin    => 'https://github.com/WikiForge/jobrunner-service',
    }

    $redis_password = lookup('passwords::redis::master')
    $redis_server_ip = lookup('mediawiki::jobqueue::runner::redis_ip', {'default_value' => false})

    if lookup('jobrunner::intensive', {'default_value' => false}) {
        $config = 'jobrunner-hi.json.erb'
    } else {
        $config = 'jobrunner.json.erb'
    }

    file { '/srv/jobrunner/jobrunner.json':
        ensure  => present,
        content => template("mediawiki/${config}"),
        require => Git::Clone['JobRunner'],
    }
}
