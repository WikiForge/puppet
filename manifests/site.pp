# servers

node 'cloud1.wikiforge.net' {
    include base
    include role::cloud
}

node /^cp[123]\.wikiforge\.net$/ {
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

node 'jobrunner1.wikiforge.net' {
    include base
    include role::mediawiki
    include role::irc
}

node 'jobrunner2.wikiforge.net' {
    include base
    include role::mediawiki
}

node 'misc1.wikiforge.net' {
    include base
    include role::mail
    include role::openldap
    include role::roundcubemail
}

node 'mem1.wikiforge.net' {
    include base
    include role::memcached
}

node /^mw[12345]\.wikiforge\.net$/ {
    include base
    include role::mediawiki
}

node /^mw([12345]|11)\.wikiforge\.net$/ {
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
