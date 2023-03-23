# servers

node 'puppet1.wikiforge.net' {
    include base
    # include role::postgresql
    include puppetdb::database
    include role::puppetserver
    include role::salt
    # include role::ssl
}

node 'mw1.wikiforge.net' {
    include base
    include role::mediawiki
}

# ensures all servers have basic class if puppet runs
node default {
    include base
}
