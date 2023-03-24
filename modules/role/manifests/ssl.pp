# role: ssl
class role::ssl {
    include ::ssl

    @@sshkey { 'github.com':
        ensure       => present,
        type         => 'ecdsa-sha2-nistp256',
        key          => 'AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBEmKSENjQEezOmxkZMy7opKgwFB9nkt5YRrYMjNuG5N87uRgg6CLrbo5wAdT/y6v0mKV0U2w0WZ2YB/++Tpockg=',
        host_aliases => [ 'github.com' ],
    }

    motd::role { 'role::ssl':
        description => 'SSL management server',
    }
}
