# === Class blesta::nginx
#
# Nginx config using hiera
class blesta::nginx {
    $sslcerts = loadyaml('/etc/puppetlabs/puppet/ssl-cert/certs.yaml')
    $php_fpm_sock = 'php/fpm-www.sock'

    nginx::site { 'blesta':
        ensure  => present,
        content => template('blesta/blesta.conf.erb'),
    }

    include ssl::all_certs
}
