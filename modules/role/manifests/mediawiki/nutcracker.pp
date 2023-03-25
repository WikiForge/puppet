# === Class role::mediawiki::nutcracker
class role::mediawiki::nutcracker (
    Array[Variant[Stdlib::Host,String]] $memcached_servers = lookup('memcached_servers', {'default_value' => []}),
) {

    if $memcached_servers != [] {
        $nutcracker_pools = {
            'memcached'     => {
                auto_eject_hosts     => false,
                distribution         => 'ketama',
                hash                 => 'md5',
                listen               => '127.0.0.1:11212',
                preconnect           => true,
                server_connections   => 1,
                timeout              => 1000,    # milliseconds
                servers              => $memcached_servers,
            },
        }

        # Ship a tmpfiles.d configuration to create /run/nutcracker
        systemd::tmpfile { 'nutcracker':
            content => 'd /run/nutcracker 0755 nutcracker nutcracker - -'
        }

        class { '::nutcracker':
            mbuf_size => '64k',
            pools     => $nutcracker_pools,
        }

        systemd::unit { 'nutcracker':
            content  => "[Service]\nCPUAccounting=yes\n",
            override => true,
        }

        ferm::rule { 'skip_nutcracker_conntrack_out':
            desc  => 'Skip outgoing connection tracking for Nutcracker',
            table => 'raw',
            chain => 'OUTPUT',
            rule  => 'proto tcp sport (6378:6382 11212) NOTRACK;',
        }

        ferm::rule { 'skip_nutcracker_conntrack_in':
            desc  => 'Skip incoming connection tracking for Nutcracker',
            table => 'raw',
            chain => 'PREROUTING',
            rule  => 'proto tcp dport (6378:6382 11212) NOTRACK;',
        }
    }
}
