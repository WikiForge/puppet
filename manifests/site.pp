# servers

node 'cloud2.inside.wf' {
    include base
    include role::cloud
}

node 'bast21.inside.wf' {
    include base
    include role::bastion
}

node 'bots21.inside.wf' {
    include base
    include role::irc
}

node /^cp[1-6]\.inside\.wf$/ {
    include base
    include role::varnish
}

node 'db21.inside.wf' {
    include base
    include role::db
}

node 'jobchron21.inside.wf' {
    include base
    include role::poolcounter
    include role::redis
    include mediawiki::jobqueue::chron
}

node 'graylog21.inside.wf' {
    include base
    include role::graylog
}

node 'mwtask21.inside.wf' {
    include base
    include role::mediawiki
}

node 'mem21.inside.wf' {
    include base
    include role::memcached
}

node 'mon21.inside.wf' {
    include base
    include role::grafana
    include role::icinga2
}

node /^mw(?:dedi[1-9][1-9]|[1-9][1-9])\.inside\.wf$/ {
    include base
    include role::mediawiki
}

node /^ns[12]\.inside\.wf$/ {
    include base
    include role::dns
}

node 'os21.inside.wf' {
    include base
    include role::opensearch
}

node 'phorge21.inside.wf' {
    include base
    include role::phorge
}

node 'prometheus21.inside.wf' {
    include base
    include role::prometheus
}

node 'puppet21.inside.wf' {
    include base
    include role::postgresql
    include puppetdb::database
    include role::puppetserver
    include role::salt
    include role::ssl
}

node 'services21.inside.wf' {
    include base
    include role::services
}

node 'swiftac21.inside.wf' {
    include base
    include role::swift
}

node 'swiftobject21.inside.wf' {
    include base
    include role::swift
}

node 'swiftproxy21.inside.wf' {
    include base
    include role::swift
}

node 'swiftac1.inside.wf' {
    include base
    include role::swift
}

node 'swiftobject1.inside.wf' {
    include base
    include role::swift
}

node 'swiftproxy1.inside.wf' {
    include base
    include role::swift
}

node 'staging21.inside.wf' {
    include base
    include role::mediawiki
    include role::memcached
    include role::poolcounter
    include role::redis
    include mediawiki::jobqueue::chron
}

# ensures all servers have basic class if puppet runs
node default {
    include base
}
