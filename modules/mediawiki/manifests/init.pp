# === Class mediawiki
class mediawiki {
    include mediawiki::cgroup
    include mediawiki::favicons
    include mediawiki::nginx
    include mediawiki::packages
    include mediawiki::logging
    include mediawiki::php
    include mediawiki::monitoring

    if lookup(mediawiki::use_staging) {
        include mediawiki::deploy
    } else {
        include mediawiki::rsync
    }

    include mediawiki::multiversion

    if lookup(mediawiki::use_shellbox) {
        include mediawiki::shellbox
    }

    if !lookup('jobrunner::intensive', {'default_value' => false}) {
        cron { 'clean-tmp-files':
            ensure  => absent,
            command => 'find /tmp/ -user www-data -amin +30 \( -iname "transform_*" -or -iname "lci_*" -or -iname "svg_* -or -iname "localcopy_*" \) -delete',
            user    => 'www-data',
            special => 'hourly',
        }
    }

    if lookup('jobrunner::intensive', {'default_value' => false}) {
        stdlib::ensure_packages(['python3-internetarchive'])

        file { '/usr/local/bin/iaupload':
            ensure => present,
            mode   => '0755',
            source => 'puppet:///modules/mediawiki/bin/iaupload.py',
        }
    }

    git::clone { '3d2png':
        ensure             => 'latest',
        directory          => '/srv/3d2png',
        origin             => 'https://github.com/WikiForge/3d2png-deploy',
        branch             => 'master',
        owner              => 'www-data',
        group              => 'www-data',
        mode               => '0755',
        recurse_submodules => true,
        require            => Package['libjpeg-dev'],
    }

    file { [
        '/srv/mediawiki',
        '/srv/mediawiki/config',
        '/srv/mediawiki/cache',
        '/srv/mediawiki/stopforumspam',
    ]:
        ensure => 'directory',
        owner  => 'www-data',
        group  => 'www-data',
        mode   => '0755',
    }

    file { '/srv/mediawiki/robots.php':
        ensure  => 'present',
        source  => 'puppet:///modules/mediawiki/robots.php',
        require => File['/srv/mediawiki'],
    }

    file { '/srv/mediawiki/favicon.php':
        ensure  => 'present',
        source  => 'puppet:///modules/mediawiki/favicon.php',
        require => File['/srv/mediawiki'],
    }

    file { '/srv/mediawiki/touch.php':
        ensure  => 'present',
        source  => 'puppet:///modules/mediawiki/touch.php',
        require => File['/srv/mediawiki'],
    }

    file { '/srv/mediawiki/healthcheck.php':
        ensure  => 'present',
        source  => 'puppet:///modules/mediawiki/healthcheck.php',
        require => File['/srv/mediawiki'],
    }

    file { '/srv/mediawiki/sitemap.php':
        ensure  => 'present',
        source  => 'puppet:///modules/mediawiki/sitemap.php',
        require => File['/srv/mediawiki'],
    }

    $wikiadmin_password       = lookup('passwords::db::wikiadmin')
    $mediawiki_password       = lookup('passwords::db::mediawiki')
    $redis_password           = lookup('passwords::redis::master')
    $ldap_password            = lookup('profile::openldap::admin_password')
    $noreply_password         = lookup('passwords::mail::noreply')
    $mediawiki_upgradekey     = lookup('passwords::mediawiki::upgradekey')
    $mediawiki_secretkey      = lookup('passwords::mediawiki::wikiforge::secretkey')
    $hcaptcha_secretkey       = lookup('passwords::hcaptcha::secretkey')
    $shellbox_secretkey       = lookup('passwords::shellbox::secretkey')
    $swift_password           = lookup('mediawiki::swift_password')
    $aws_s3_access_key        = lookup('mediawiki::aws_s3_access_key')
    $aws_s3_access_secret_key = lookup('mediawiki::aws_s3_access_secret_key')

    file { '/srv/mediawiki/config/PrivateSettings.php':
        ensure  => 'present',
        content => template('mediawiki/PrivateSettings.php'),
        require => File['/srv/mediawiki/config'],
    }

    file { '/usr/local/bin/fileLockScript.sh':
        ensure => 'present',
        mode   => '0755',
        source => 'puppet:///modules/mediawiki/bin/fileLockScript.sh',
    }

    file { '/usr/local/bin/foreachwikiindblist':
        ensure => 'present',
        mode   => '0755',
        source => 'puppet:///modules/mediawiki/bin/foreachwikiindblist',
    }

    file { '/usr/local/bin/getMWVersion':
        ensure => 'present',
        mode   => '0755',
        source => 'puppet:///modules/mediawiki/bin/getMWVersion.php',
    }

    file { '/usr/local/bin/getMWVersions':
        ensure => 'present',
        mode   => '0755',
        source => 'puppet:///modules/mediawiki/bin/getMWVersions.php',
    }

    file { '/usr/local/bin/mwscript':
        ensure => 'present',
        mode   => '0755',
        source => 'puppet:///modules/mediawiki/bin/mwscript.py',
    }

    $cookbooks = ['disable-puppet', 'enable-puppet', 'cycle-puppet', 'check-read-only']
    $cookbooks.each |$cookbook| {
        file {"/usr/local/bin/${cookbook}":
            ensure => 'present',
            mode   => '0755',
            source => "puppet:///modules/mediawiki/cookbooks/${cookbook}.py",
        }
    }

    file { '/srv/mediawiki/config/OAuth2.key':
        ensure  => present,
        mode    => '0755',
        source  => 'puppet:///private/mediawiki/OAuth2.key',
        require => File['/srv/mediawiki/config'],
    }

    file { '/srv/mediawiki/stopforumspam/listed_ip_90_ipv46_all.txt':
        ensure    => present,
        mode      => '0755',
        source    => 'puppet:///private/mediawiki/listed_ip_90_ipv46_all.txt',
        show_diff => false,
        require   => File['/srv/mediawiki/stopforumspam'],
    }

    sudo::user { 'www-data_sudo_itself':
        user       => 'www-data',
        privileges => [
            'ALL = (www-data) NOPASSWD: ALL',
        ],
    }

    file { '/etc/swift-env.sh':
        ensure  => 'present',
        content => template('mediawiki/swift-env.sh.erb'),
        mode    => '0755',
    }

    tidy { '/tmp':
        matches => [ '*.png', '*.jpg', '*.gif', 'EasyTimeline.*', 'gs_*', 'localcopy_*', 'transform_*', 'vips-*.v', 'php*', 'shellbox-*' ],
        age     => '2h',
        type    => 'atime',
        backup  => false,
        recurse => 1,
    }
}
