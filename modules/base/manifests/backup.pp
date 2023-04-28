# class base::backup
class base::backup (
    String $pca_password = lookup('private::passwords::pca')
) {
    ensure_packages(['python3-fabric', 'python3-decorator'])
    ensure_packages(
        'py7zr',
        {
            ensure   => '0.20.5',
            provider => 'pip3',
            before   => File['/usr/local/bin/wikiforge-backup'],
            require  => Package['python3-pip'],
        },
    )

    file { '/usr/local/bin/wikiforge-backup':
        mode    => '0555',
        content => template('base/backups/wikiforge-backup.py.erb'),
    }
}
