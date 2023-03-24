#! /usr/bin/python3

import os
import requests
import sys
canary = 'mw1'
serverlist = 'mw1'


def check_up(server: str) -> bool:
    headers = {'X-WikiForge-Debug': f'{server}.meta.wikiforge.netwikiforge.net'}
    req = requests.get('https://meta.wikiforge.net/w/api.php?action=query&meta=siteinfo&formatversion=2&format=json', headers=headers)
    if req.status_code == 200 and 'wikiforge' in req.text and server in req.headers['X-Served-By']:
        return True
    return False


print('Welcome to the MediaWiki Upgrade tool!')
input('Please confirm you are running this script on the canary server: (press enter)')
if sys.argv[1] == 'prep':
    print('Starting staging update')
    input('Press enter when branch updated in puppet: ')
    os.system('sudo -u www-data rm -rf /srv/mediawiki-staging/w')
    os.system('sudo puppet agent -tv')
    print('Will now check mediawiki branch')
    os.system('git -C /srv/mediawiki-staging/w rev-parse --abbrev-ref HEAD')
    input('Confirm: ')
    print('Will now deploy to canary server')
    os.system(f'deploy-mediawiki --world --l10n --force --ignore-time --extension-list --servers={canary}')
    if check_up(canary):
        print('Canary deploy done')
    else:
        print('Canary is not online')
    print('Deployment done, run with "fleet" to rollout')
if sys.argv[1] == 'fleet':
    input('Press enter when all servers pooled: ')
    input('Confirm mass rolout:')
    os.system(f'deploy-mediawiki --world --l10n --force --ignore-time --extension-list --servers={serverlist}')
    print('Deployment done')
