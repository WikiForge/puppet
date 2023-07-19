# === Class mediawiki::favicons
class mediawiki::favicons {
    file { '/srv/mediawiki/favicons':
        ensure  => directory,
        owner   => 'www-data',
        group   => 'www-data',
        mode    => '0755',
        require => File['/srv/mediawiki'],
    }

    file { '/srv/mediawiki/favicons/default-wikiforge.ico':
        ensure  => present,
        source  => 'puppet:///modules/mediawiki/favicons/default-wikiforge.ico',
        require => File['/srv/mediawiki/favicons'],
    }

    file { '/srv/mediawiki/favicons/default-wikitide.ico':
        ensure  => present,
        source  => 'puppet:///modules/mediawiki/favicons/default-wikitide.ico',
        require => File['/srv/mediawiki/favicons'],
    }
    
    file { '/srv/mediawiki/favicons/apple-touch-icon-default-wikiforge.png':
        ensure  => present,
        source  => 'puppet:///modules/mediawiki/favicons/apple-touch-icon-default-wikiforge.png',
        require => File['/srv/mediawiki/favicons'],
    }
   file { '/srv/mediawiki/favicons/apple-touch-icon-default-wikitide.png':
        ensure  => present,
        source  => 'puppet:///modules/mediawiki/favicons/apple-touch-icon-default-wikitide.png',
        require => File['/srv/mediawiki/favicons'],
    }
}
