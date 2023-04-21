# class: role::db
class role::db {
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
}
