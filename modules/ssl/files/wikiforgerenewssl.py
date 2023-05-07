import os
import argparse
import subprocess
from datetime import datetime, timedelta


def get_ssl_domains(ssl_dir):
    """Returns a list of all SSL domains in the specified directory"""
    ssl_domains = []
    for dirpath, dirnames, filenames in os.walk(ssl_dir):
        if 'cert.pem' in filenames:
            ssl_domains.append(os.path.basename(dirpath))
    return ssl_domains


def get_cert_expiry_date(domain):
    """Returns the expiry date of the SSL certificate for the specified domain"""
    cert_path = f'/etc/letsencrypt/live/{domain}/cert.pem'
    cert_expiry_date = subprocess.check_output(['openssl', 'x509', '-enddate', '-noout', '-in', cert_path])
    cert_expiry_date = cert_expiry_date.decode('utf-8').strip()[9:]
    cert_expiry_date = datetime.strptime(cert_expiry_date, '%b %d %H:%M:%S %Y %Z')
    return cert_expiry_date


def days_until_expiry(expiry_date):
    """Returns the number of days until the specified expiry date"""
    days_until_expiry = (expiry_date - datetime.now()).days
    return days_until_expiry


def should_renew(domain, days_left, no_confirm):
    """Returns True if the SSL certificate should be renewed"""
    if days_left <= 15 or no_confirm:
        return True
    else:
        answer = input(f'The SSL certificate for {domain} is due to expire in {days_left} days. Do you want to renew it now? (y/n): ')
        return answer.lower() in ('y', 'yes')


class SSLRenewer:
    def __init__(self, ssl_dir, no_confirm):
        self.ssl_dir = ssl_dir
        self.days_before_expiry = days_before_expiry
        self.no_confirm = no_confirm

    def run(self):
        """Main function that loops through all SSL domains and renews the certificates if necessary"""
        for domain in get_ssl_domains(self.ssl_dir):
            expiry_date = get_cert_expiry_date(domain)
            days_left = days_until_expiry(expiry_date)
            if should_renew(domain, days_left, self.no_confirm):
                subprocess.call(['/root/ssl-certificate', '-d', domain])


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Renews LetsEncrypt SSL certificates')
    parser.add_argument('--no-confirm', action='store_true', help='Renew certificates without asking for confirmation')
    args = parser.parse_args()
    ssl_renewer = SSLRenewer('/etc/letsencrypt/live', args.no_confirm)
    ssl_renewer.run()
