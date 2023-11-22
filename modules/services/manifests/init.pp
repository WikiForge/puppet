# === Class services

class services {
    stdlib::ensure_packages(['nodejs', 'npm', 'make', 'g++'])

    file { '/etc/mediawiki':
        ensure => directory,
    }
}
