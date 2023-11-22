# class: irc
class irc {
    stdlib::ensure_packages([
        'python3',
        'python3-twisted',
        'python3-requests',
        'python3-requests-oauthlib',
    ])

    exec { 'install_anisse_irc':
        command => '/usr/bin/pip3 install git+https://github.com/anisse/irc',
        creates => '/usr/local/lib/python3.11/dist-packages/irc',
        require => Package['python3-pip'],
    }
}
