# === Class blesta
class blesta {
    include blesta::nginx
    file { [
        '/srv/blesta',
    ]:
        ensure => 'directory',
        owner  => 'www-data',
        group  => 'www-data',
        mode   => '0755',
    }
}