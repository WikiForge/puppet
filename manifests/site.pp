# servers

node /^cp[1234]\.wikiforge\.net$/ {
    role(varnish)
}

node 'db1.wikiforge.net' {
    role(db)
}

node 'jobchron1.wikiforge.net' {
    role(redis)
    include mediawiki::jobqueue::chron
}

node 'jobrunner1.wikiforge.net' {
    role mediawiki, irc
}

node 'jobrunner2.wikiforge.net' {
    role(mediawiki)
}

node 'mem1.wikiforge.net' {
    role(memcached)
}

node /^mw[12]\.wikiforge\.net$/ {
    role(mediawiki)
}

node /^ns[12]\.wikiforge\.net$/ {
    role(dns)
}

node 'phorge1.wikiforge.net' {
    role(phorge)
}

node 'puppet1.wikiforge.net' {
    role postgresql, puppetserver, salt, ssl
    include puppetdb::database
}

node 'services1.wikiforge.net' {
    role(services)
}

node 'test1.wikiforge.net' {
    role(mediawiki)
}

# ensures all servers have basic class if puppet runs
node default {
    include base
}
