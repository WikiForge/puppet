# !/bin/bash
set -e
set -u

if [ ! -d /srv/services/services/ ]; then
        cd /srv/services/ && GIT_SSH_COMMAND='ssh -o StrictHostKeyChecking=no -i /srv/services/id_ed25519 -F /dev/null' git clone git@github.com:WikiForge/services.git && cd /srv/services/services/ && git config --local core.sshCommand "ssh -o StrictHostKeyChecking=no -i /srv/services/id_ed25519 -F /dev/null"
else
        cd /srv/services/services/ && git config --local core.sshCommand "ssh -o StrictHostKeyChecking=no -i /srv/services/id_ed25519 -F /dev/null" && git reset --hard origin/master && git pull
fi

git -C /srv/services/services/ config user.email "universalomega@wikiforge.net"

git -C /srv/services/services/ config user.name "WikiForgeSSLBot"

/usr/bin/php /srv/mediawiki/1.39/extensions/WikiForgeMagic/maintenance/addWikiToServices.php --wiki=metawiki

git -C /srv/services/services/ add -A --all

git -C /srv/services/services/ commit -m "BOT: Updating services config for wikis"

git -C /srv/services/services/ push origin master

exit 0
