# === Class services

class services {
    ensure_packages(['nodejs', 'npm', 'make', 'g++'])

    file { '/etc/mediawiki':
        ensure => directory,
    }
}
