# class base::backup
class base::backup (
    String $pca_password = lookup('private::passwords::pca')
) {
    ensure_packages(['python3-fabric', 'python3-decorator'])

    file { '/usr/local/bin/wikiforge-backup':
        mode    => '0555',
        content => template('base/backups/wikiforge-backup.py.erb'),
    }
}
