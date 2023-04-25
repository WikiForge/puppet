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
        config   => 'mariadb/config/mw.cnf.erb',
        password => lookup('passwords::db::root'),
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
        query_facts('Class[Role::Db] or Class[Role::Mediawiki] or Class[Role::Phorge]', ['ipaddress', 'ipaddress6'])
        .map |$key, $value| {
            "${value['ipaddress']} ${value['ipaddress6']}"
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
    /*users::user { 'dbcopy':
        ensure   => present,
        uid      => 3000,
        ssh_keys => [
            ''
        ],
    }*/

    motd::role { 'role::db':
        description => 'general database server',
    }

    cron { 'backups-sql':
        ensure   => present,
        command  => '/usr/local/bin/wikiforge-backup backup sql > /var/log/sql-backup.log 2>&1',
        user     => 'root',
        minute   => '0',
        hour     => '3',
        monthday => [fqdn_rand(13, 'db-backups') + 1, fqdn_rand(13, 'db-backups') + 15],
    }

    $weekly_misc.each |String $db| {
        cron { "backups-${db}":
            ensure  => present,
            command => "/usr/local/bin/wikiforge-backup backup sql --database=${db} > /var/log/sql-${db}-backup-weekly.log 2>&1",
            user    => 'root',
            minute  => '0',
            hour    => '5',
            weekday => '0',
        }
    }

    $fortnightly_misc.each |String $db| {
        cron { "backups-${db}":
            ensure   => present,
            command  => "/usr/local/bin/wikiforge-backup backup sql --database=${db} > /var/log/sql-${db}-backup-fortnightly.log 2>&1",
            user     => 'root',
            minute   => '0',
            hour     => '5',
            monthday => ['1', '15'],
        }
    }

    $monthly_misc.each |String $db| {
        cron { "backups-${db}":
            ensure   => present,
            command  => "/usr/local/bin/wikiforge-backup backup sql --database=${db} > /var/log/sql-${db}-backup-monthly.log 2>&1",
            user     => 'root',
            minute   => '0',
            hour     => '5',
            monthday => ['24'],
        }
    }
}
