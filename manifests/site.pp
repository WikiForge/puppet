# servers

node /^cp[123456]\.wikiforge\.net$/ {
    include base
    include role::varnish
}

node /^db[12]\.wikiforge\.net$/ {
    include base
    include role::db
}

node 'jobchron1.wikiforge.net' {
    include base
    include role::redis
    include mediawiki::jobqueue::chron
}


node /^jobrunner[12]\.wikiforge\.net$/ {
    include base
    include role::mediawiki
}

node 'mem1.wikiforge.net' {
    include base
    include role::memcached
}

node /^mw[123456]\.wikiforge\.net$/ {
    include base
    include role::mediawiki
}

node /^ns[12]\.wikiforge\.net$/ {
    include base
    include role::dns
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

node 'services1.wikiforge.net' {
    include base
    include role::services
}

node 'test1.wikiforge.net' {
    include base
    include role::mediawiki
}

# ensures all servers have basic class if puppet runs
node default {
    include base
}
