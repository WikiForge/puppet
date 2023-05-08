import os
import re
import argparse
import subprocess
import logging
from filelock import FileLock
from datetime import datetime

logging.basicConfig(filename='/var/log/ssl/wikiforge-renewal.log', format='%(asctime)s - %(message)s', level=logging.INFO, force=True)


def get_ssl_domains(ssl_dir):
    """Returns a list of all SSL domains in the specified directory"""
    ssl_domains = []
    for dirpath, dirnames, filenames in os.walk(ssl_dir):
        if 'cert.pem' in filenames:
            ssl_domains.append(os.path.basename(dirpath))
    return ssl_domains


def get_secondary_domains(ssl_dir, domain):
    """Returns a list of all SSL secondary domains that is also for the same certificate"""
    cert_path = os.path.join(ssl_dir, domain, 'cert.pem')
    output = subprocess.check_output(['openssl', 'x509', '-in', cert_path, '-noout', '-text'])
    output = output.decode('utf-8')
    secondary_domains = re.findall(r'DNS:([^,\n]*)', output)
    if domain in secondary_domains:
        secondary_domains.remove(domain)
    return secondary_domains


def get_cert_expiry_date(domain):
    """Returns the expiry date of the SSL certificate for the specified domain"""
    cert_path = f'/etc/letsencrypt/live/{domain}/cert.pem'
    cert_expiry_date = subprocess.check_output(['openssl', 'x509', '-enddate', '-noout', '-in', cert_path])
    cert_expiry_date = cert_expiry_date.decode('utf-8').strip()[9:]
    return datetime.strptime(cert_expiry_date, '%b %d %H:%M:%S %Y %Z')


def days_until_expiry(expiry_date):
    """Returns the number of days until the specified expiry date"""
    return (expiry_date - datetime.now()).days


def should_renew(domain, days_left, no_confirm):
    """Returns True if the SSL certificate should be renewed"""
    if days_left <= 15 or no_confirm:
        return True
    answer = input(f'The SSL certificate for {domain} is due to expire in {days_left} days. Do you want to renew it now? (y/n): ')
    return answer.lower() in ('y', 'yes')


class SSLRenewer:
    def __init__(self, ssl_dir, no_confirm):
        self.ssl_dir = ssl_dir
        self.no_confirm = no_confirm

    def run(self):
        """Main function that loops through all SSL domains and renews the certificates if necessary"""
        for domain in get_ssl_domains(self.ssl_dir):
            expiry_date = get_cert_expiry_date(domain)
            days_left = days_until_expiry(expiry_date)
            if should_renew(domain, days_left, self.no_confirm):
                filename = '/tmp/tmp_file.lock'
                lock = FileLock(filename)
                lock_acquired = False
                while not lock_acquired:
                    with lock:
                        lock.acquire()
                        try:
                            secondary_domains = []
                            secondary_domains = ['--secondary', ' '.join(get_secondary_domains(self.ssl_dir, domain))]
                            # subprocess.call(['sudo', '/root/ssl-certificate', '--domain', domain, '--renew', '--private', '--overwrite'] + secondary_domains)
                            print(' '.join(['sudo', '/root/ssl-certificate', '--domain', domain, '--renew', '--private', '--overwrite'] + secondary_domains))
                            logging.info(f'Renewed SSL certificate: {domain}')
                            lock_acquired = True
                        finally:
                            lock.release()


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Renews LetsEncrypt SSL certificates')
    parser.add_argument('--no-confirm', action='store_true', help='Renew certificates without asking for confirmation')
    args = parser.parse_args()

    ssl_renewer = SSLRenewer('/etc/letsencrypt/live', args.no_confirm)
    ssl_renewer.run()
