# servers

node 'bots1.wikiforge.net' {
    include base
    include role::irc
}

node 'cp1.wikiforge.net' {
    include base
    include role::varnish
}

node 'db1.wikiforge.net' {
    include base
    include role::db
}

node 'jobchron1.wikiforge.net' {
    include base
    include role::redis
    include mediawiki::jobqueue::chron
}

node 'mem1.wikiforge.net' {
    include base
    include role::memcached
}

node /^mw[12]\.wikiforge\.net$/ {
    include base
    include role::mediawiki
}

node 'phorge1.wikiforge.net' {
    include base
    include role::phorge
}

node 'puppet1.wikiforge.net' {
    include base
    include role::postgresql
    include puppetdb::database
    include role::puppetserver
    include role::salt
    include role::ssl
}

node 'test1.wikiforge.net' {
    include base
    include role::mediawiki
}

# ensures all servers have basic class if puppet runs
node default {
    include base
}
