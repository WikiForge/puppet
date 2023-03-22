# servers

# puppet1
node 'ec2-3-16-47-25.us-east-2.compute.amazonaws.com' {
    include base
    include role::postgresql
    include puppetdb::database
    include role::puppetserver
    include role::salt
    include role::ssl
}

# mw1
node 'ec2-18-221-90-68.us-east-2.compute.amazonaws.com' {
    include base
    include role::mediawiki
}

# ensures all servers have basic class if puppet runs
node default {
    include base
}
