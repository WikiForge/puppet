# class: role::db
class role::db (
    Optional[Array[String]] $weekly_misc = lookup('role::db::weekly_misc', {'default_value' => []}),
    Optional[Array[String]] $fortnightly_misc = lookup('role::db::fornightly_misc', {'default_value' => []}),
    Optional[Array[String]] $monthly_misc = lookup('role::db::monthly_misc', {'default_value' => []})
) {
    include mariadb::packages

    $mediawiki_password = lookup('passwords::db::mediawiki')
    $wikiadmin_password = lookup('passwords::db::wikiadmin')
    $phorge_password = lookup('passwords::db::phorge')

    ssl::wildcard { 'db wildcard':
        ssl_cert_key_private_group => 'mysql',
    }

    file { '/etc/ssl/private':
        ensure => directory,
        owner  => 'root',
        group  => 'mysql',
        mode   => '0750'
    }

    class { 'mariadb::config':
        config          => 'mariadb/config/mw.cnf.erb',
        icinga_password => lookup('passwords::db::icinga'),
        password        => lookup('passwords::db::root'),
    }

    file { '/etc/mysql/wikiforge/mediawiki-grants.sql':
        ensure  => present,
        content => template('mariadb/grants/mediawiki-grants.sql.erb'),
    }

    file { '/etc/mysql/wikiforge/phorge-grants.sql':
        ensure  => present,
        content => template('mariadb/grants/phorge-grants.sql.erb'),
    }

    $firewall_rules_str = join(
        query_facts("networking.domain='${facts['networking']['domain']}' and Class[Role::Db] or Class[Role::Mediawiki] or Class[Role::Icinga2] or Class[Role::Roundcubemail] or Class[Role::Phorge] or Class[Role::Matomo]", ['networking'])
        .map |$key, $value| {
            "${value['networking']['ip']} ${value['networking']['ip6']}"
        }
        .flatten()
        .unique()
        .sort(),
        ' '
    )
    ferm::service { 'mariadb':
        proto   => 'tcp',
        port    => '3306',
        srange  => "(${firewall_rules_str})",
        notrack => true,
    }

    # Create a user to allow db transfers between servers
    file { '/home/dbcopy/.ssh':
        ensure  => directory,
        mode    => '0700',
        owner   => 'dbcopy',
        group   => 'dbcopy',
        require => User['dbcopy'],
    }

    file { '/home/dbcopy/.ssh/id_ed25519':
        source    => 'puppet:///private/mariadb/dbcopy-ssh-key',
        owner     => 'dbcopy',
        group     => 'dbcopy',
        mode      => '0400',
        show_diff => false,
        require   => File['/home/dbcopy/.ssh'],
    }

    users::user { 'dbcopy':
        ensure   => present,
        uid      => 3000,
        ssh_keys => [
            'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIaNnvqGzsVpXQr9jWHmdjJfnSyZYFVWMzdAh2VwFdSD dbcopy'
        ],
    }

    motd::role { 'role::db':
        description => 'MySQL server',
    }

    # Backups
    file { '/srv/backups':
        ensure => directory,
    }

    # Logs for the backups
    file { '/var/log/backup-logs':
        ensure => directory,
    }
    cron { 'backups-sql':
        ensure   => present,
        command  => '/usr/local/bin/wikiforge-backup backup sql > /var/log/backup-logs/sql-backup.log 2>&1',
        user     => 'root',
        minute   => '0',
        hour     => '3',
        monthday => [fqdn_rand(13, 'db-backups') + 1, fqdn_rand(13, 'db-backups') + 15],
    }

    monitoring::nrpe { 'Backups SQL':
        command  => '/usr/lib/nagios/plugins/check_file_age -w 864000 -c 1209600 -f /var/log/backup-logs/sql-backup.log',
        docs     => 'https://tech.wikiforge.net/wiki/Backups#General_backup_Schedules',
        critical => true
    }

    $weekly_misc.each |String $db| {
        cron { "backups-${db}":
            ensure  => present,
            command => "/usr/local/bin/wikiforge-backup backup sql --database=${db} > /var/log/backup-logs/sql-${db}-backup-weekly.log 2>&1",
            user    => 'root',
            minute  => '0',
            hour    => '5',
            weekday => '0',
        }

        monitoring::nrpe { "Backups SQL ${db}":
            command  => "/usr/lib/nagios/plugins/check_file_age -w 864000 -c 1209600 -f /var/log/backup-logs/sql-${db}-backup-weekly.log",
            docs     => 'https://tech.wikiforge.net/wiki/Backups#General_backup_Schedules',
            critical => true
        }
    }

    $fortnightly_misc.each |String $db| {
        cron { "backups-${db}":
            ensure   => present,
            command  => "/usr/local/bin/wikiforge-backup backup sql --database=${db} > /var/log/backup-logs/sql-${db}-backup-fortnightly.log 2>&1",
            user     => 'root',
            minute   => '0',
            hour     => '5',
            monthday => ['1', '15'],
        }

        monitoring::nrpe { "Backups SQL ${db}":
            command  => "/usr/lib/nagios/plugins/check_file_age -w 1555200 -c 1814400 -f /var/log/backup-logs/sql-${db}-backup-fortnightly.log",
            docs     => 'https://tech.wikiforge.net/wiki/Backups#General_backup_Schedules',
            critical => true
        }
    }

    $monthly_misc.each |String $db| {
        cron { "backups-${db}":
            ensure   => present,
            command  => "/usr/local/bin/wikiforge-backup backup sql --database=${db} > /var/log/backup-logs/sql-${db}-backup-monthly.log 2>&1",
            user     => 'root',
            minute   => '0',
            hour     => '5',
            monthday => ['24'],
        }

        monitoring::nrpe { "Backups SQL ${db}":
            command  => "/usr/lib/nagios/plugins/check_file_age -w 3024000 -c 3456000 -f /var/log/backup-logs/sql-${db}-backup-monthly.log",
            docs     => 'https://tech.wikiforge.net/wiki/Backups#General_backup_Schedules',
            critical => true
        }
    }
}
