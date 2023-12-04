# servers

node 'cloud1.inside.wf' {
    include base
    include role::cloud
}

node 'bast1.inside.wf' {
    include base
    include role::bastion
}

node 'db1.inside.wf' {
    include base
    include role::db
}

node 'jobchron1.inside.wf' {
    include base
    include role::poolcounter
    include role::redis
    include mediawiki::jobqueue::chron
}

node 'graylog1.inside.wf' {
    include base
    include role::graylog
}

node 'jobrunner1.inside.wf' {
    include base
    include role::mediawiki
    include role::irc
}

node 'ldap1.inside.wf' {
    include base
    include role::openldap
}

node 'mail1.inside.wf' {
    include base
    include role::mail
    include role::snappymail
}

node 'mem1.inside.wf' {
    include base
    include role::memcached
}

node 'mon1.inside.wf' {
    include base
    include role::grafana
    include role::icinga2
}

node /^mw[123]\.inside\.wf$/ {
    include base
    include role::mediawiki
}

node 'ns1.inside.wf' {
    include base
    include role::dns
}

node 'os1.inside.wf' {
    include base
    include role::opensearch
}

node 'phorge1.inside.wf' {
    include base
    include role::phorge
}

node 'prometheus1.inside.wf' {
    include base
    include role::prometheus
}

node 'puppet1.inside.wf' {
    include base
    include role::postgresql
    include puppetdb::database
    include role::puppetserver
    include role::salt
    include role::ssl
}

node 'services1.inside.wf' {
    include base
    include role::services
}

node 'test1.inside.wf' {
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
