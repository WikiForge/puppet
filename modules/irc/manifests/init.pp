# class: irc
class irc {
    ensure_packages([
        'python3',
        'python3-twisted',
        'python3-requests',
        'python3-requests-oauthlib',
    ])

    ensure_packages(
        'git+https://github.com/anisse/irc',
        {
            ensure   => present,
            provider => 'pip3',
            require  => Package['python3-pip'],
        },
    )
}
