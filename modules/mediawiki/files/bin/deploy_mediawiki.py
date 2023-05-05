#! /usr/bin/python3

import argparse
from typing import Optional, TypedDict
import os
import time
import requests
import socket
import json
from sys import exit
from langcodes import tag_is_valid

mw_versions = os.popen('getMWVersions').read().strip()
versions = {'version': 'version'}
if mw_versions:
    versions = json.loads(mw_versions)
repos = {**versions, 'config': 'config', 'errorpages': 'ErrorPages', 'landing': 'landing'}

del mw_versions

DEPLOYUSER = 'www-data'


class Environment(TypedDict):
    wikidbname: str
    wikiurl: str
    servers: list


class EnvironmentList(TypedDict):
    prod: Environment
    test: Environment


prod: Environment = {
    'wikidbname': 'metawiki',
    'wikiurl': 'meta.wikiforge.net',
    'servers': ['mw2', 'mw1'],
}
test: Environment = {
    'wikidbname': 'test1wiki',
    'wikiurl': 'test1.wikiforge.net',
    'servers': ['test1'],
}
ENVIRONMENTS: EnvironmentList = {
    'prod': prod,
    'test': test,
}
del prod
del test
HOSTNAME = socket.gethostname().split('.')[0]


def get_environment_info() -> Environment:
    if HOSTNAME.startswith('test'):
        return ENVIRONMENTS['test']
    return ENVIRONMENTS['prod']


def get_valid_extensions(versions: list[str]) -> list:
    valid_extensions = []
    for version in versions:
        extensions_path = f'/srv/mediawiki-staging/{version}/extensions/'
        with os.scandir(extensions_path) as extensions:
            valid_extensions += [extension.name for extension in extensions if extension.is_dir()]
    return valid_extensions


def get_valid_skins(versions: list[str]) -> list:
    valid_skins = []
    for version in versions:
        skins_path = f'/srv/mediawiki-staging/{version}/skins/'
        with os.scandir(skins_path) as skins:
            valid_skins += [skin.name for skin in skins if skin.is_dir()]
    return valid_skins


def get_extensions_in_pack(pack_name: str) -> list[str]:
    packs = {
        'bundled': ['AbuseFilter', 'CategoryTree', 'Cite', 'CiteThisPage', 'CodeEditor', 'ConfirmEdit', 'DiscussionTools', 'Echo', 'Gadgets', 'ImageMap', 'InputBox', 'Interwiki', 'Linter', 'LoginNotify', 'Math', 'MultimediaViewer', 'Nuke', 'OATHAuth', 'PageImages', 'ParserFunctions', 'PdfHandler', 'Poem', 'ReplaceText', 'Scribunto', 'SpamBlacklist', 'SyntaxHighlight_GeSHi', 'TemplateData', 'TextExtracts', 'Thanks', 'TitleBlacklist', 'VisualEditor', 'WikiEditor'],
        'miraheze': ['CreateWiki', 'DataDump', 'GlobalNewFiles', 'ImportDump', 'IncidentReporting', 'ManageWiki', 'PDFEmbed', 'RemovePII', 'RottenLinks', 'SpriteSheet', 'WikiDiscover', 'YouTube'],
        'mleb': ['Babel', 'cldr', 'CleanChanges', 'Translate', 'UniversalLanguageSelector'],
        'wikiforge': ['WikiForgeMagic'],
    }
    return packs.get(pack_name, [])


def get_skins_in_pack(pack_name: str) -> list[str]:
    packs = {
        'bundled': ['MinervaNeue', 'MonoBook', 'Timeless', 'Vector'],
    }
    return packs.get(pack_name, [])


def run_command(cmd: str) -> int:
    start = time.time()
    print(f'Execute: {cmd}')
    ec = os.system(cmd)
    print(f'Completed ({ec}) in {str(int(time.time() - start))}s!')
    return ec


def non_zero_code(ec: list[int], nolog: bool = True, leave: bool = True) -> bool:
    for code in ec:
        if code != 0:
            if not nolog:
                os.system('/usr/local/bin/logsalmsg DEPLOY ABORTED: Non-Zero Exit Code in prep, see output.')
            if leave:
                print('Exiting due to non-zero status.')
                exit(1)
            return True
    return False


def check_up(nolog: bool, Debug: Optional[str] = None, Host: Optional[str] = None, domain: str = 'meta.wikiforge.net', verify: bool = True, force: bool = False, port: int = 443) -> bool:
    if verify is False:
        os.environ['PYTHONWARNINGS'] = 'ignore:Unverified HTTPS request'
    if not Debug and not Host:
        raise Exception('Host or Debug must be specified')
    if Debug:
        server = f'{Debug}.wikiforge.net'
        headers = {'X-WikiForge-Debug': server}
        location = f'{domain}@{server}'
    else:
        os.environ['NO_PROXY'] = 'localhost'
        domain = 'localhost'
        headers = {'host': f'{Host}'}
        location = f'{Host}@{domain}'
    up = False
    if port == 443:
        proto = 'https://'
    else:
        proto = 'http://'
    req = requests.get(f'{proto}{domain}:{port}/w/api.php?action=query&meta=siteinfo&formatversion=2&format=json', headers=headers, verify=verify)
    if req.status_code == 200 and 'wikiforge' in req.text and (Debug is None or Debug in req.headers['X-Served-By']):
        up = True
    if not up:
        print(f'Status: {req.status_code}')
        print(f'Text: {"wikiforge" in req.text} \n {req.text}')
        if 'X-Served-By' not in req.headers:
            req.headers['X-Served-By'] = 'None'
        print(f'Debug: {(Debug is None or Debug in req.headers["X-Served-By"])}')
        if force:
            print(f'Ignoring canary check error on {location} due to --force')
        else:
            print(f'Canary check failed for {location}. Aborting... - use --force to proceed')
            message = f'/usr/local/bin/logsalmsg DEPLOY ABORTED: Canary check failed for {location}'
            if nolog:
                print(message)
            else:
                os.system(message)
            exit(3)
    return up


def remote_sync_file(time: str, serverlist: list[str], path: str, envinfo: Environment, nolog: bool, recursive: bool = True, force: bool = False) -> int:
    print(f'Start {path} deploys.')
    for server in serverlist:
        if HOSTNAME != server.split('.')[0]:
            print(f'Deploying {path} to {server}.')
            ec = run_command(_construct_rsync_command(time=time, local=False, dest=path, server=server, recursive=recursive))
            check_up(Debug=server, force=force, domain=envinfo['wikiurl'], nolog=nolog)
            print(f'Deployed {path} to {server}.')
        else:
            return 0
    print(f'Finished {path} deploys.')
    return ec


def _get_staging_path(repo: str, version: str = '') -> str:
    if version and ('extensions/' in repo or 'skins/' in repo):
        return f'/srv/mediawiki-staging/{version}/{repo}'

    return f'/srv/mediawiki-staging/{repos[repo]}/'


def _get_deployed_path(repo: str) -> str:
    return f'/srv/mediawiki/{repos[repo]}/'


def _construct_rsync_command(time: str, dest: str, recursive: bool = True, local: bool = True, location: Optional[str] = None, server: Optional[str] = None) -> str:
    if time:
        params = '--inplace'
    else:
        params = '--update'
    if recursive:
        params = params + ' -r --delete'
    if local:
        if location is None:
            raise Exception('Location must be specified for local rsync.')
        return f'sudo -u {DEPLOYUSER} rsync {params} --exclude=".*" {location} {dest}'
    if location is None:
        location = dest
    if location == dest and server:  # ignore location if not specified, if given must equal dest.
        return f'sudo -u {DEPLOYUSER} rsync {params} -e "ssh -i /srv/mediawiki-staging/deploykey" {dest} {DEPLOYUSER}@{server}.wikiforge.net:{dest}'
    # a return None here would be dangerous - except and ignore R503 as return after Exception is not reachable
    raise Exception(f'Error constructing command. Either server was missing or {location} != {dest}')


def _construct_git_pull(repo: str, branch: Optional[str] = None, version: str = '') -> str:
    extrap = ' '
    if branch:
        extrap += f'origin {branch} '

    return f'sudo -u {DEPLOYUSER} git -C {_get_staging_path(repo, version)} pull{extrap}--quiet'


def _construct_upgrade_mediawiki_rm_staging(version: str) -> str:
    return f'sudo -u {DEPLOYUSER} rm -rf {_get_staging_path(version)}'


def _construct_upgrade_mediawiki_run_puppet() -> str:
    return 'sudo puppet agent -tv'


def run(args: argparse.Namespace, start: float) -> None:
    if args.upgrade_world and not args.reset_world:
        args.world = True
        args.pull = 'world'
        args.upgrade_extensions = get_valid_extensions(args.versions)
        args.upgrade_skins = get_valid_skins(args.versions)
    run_process(args=args, start=start)
    if args.world or args.l10n or args.extension_list or args.reset_world or args.upgrade_extensions or args.upgrade_skins:
        for version in args.versions:
            run_process(args=args, start=start, version=version)


def run_process(args: argparse.Namespace, start: float, version: str = '') -> None:
    envinfo = get_environment_info()
    options = {'config': args.config and not version, 'world': args.world and version, 'landing': args.landing and not version, 'errorpages': args.errorpages and not version}
    exitcodes = []
    loginfo = {}
    rsyncpaths = []
    rsyncfiles = []
    rsync = []
    rebuild = []
    postinstall = []
    stage = []

    for arg in vars(args).items():
        if arg[1] is not None and arg[1] is not False:
            loginfo[arg[0]] = arg[1]
    synced = loginfo['servers']
    if HOSTNAME in args.servers:
        del loginfo['servers']
        text = f'starting deploy of "{str(loginfo)}" to {synced}'
        if not args.nolog:
            os.system(f'/usr/local/bin/logsalmsg {text}')
        else:
            print(text)

        if version and args.reset_world:
            stage.append(_construct_upgrade_mediawiki_rm_staging(version))
            stage.append(_construct_upgrade_mediawiki_run_puppet())

        pull = []
        if args.pull:
            pull = str(args.pull).split(',')
        if pull:
            for repo in pull:
                try:
                    if repo == 'world':
                        if version:
                            repo = version
                        else:
                            continue
                    stage.append(_construct_git_pull(repo, branch=args.branch))
                except KeyError:
                    print(f'Failed to pull {repo} due to invalid name')

        if version:
            if args.upgrade_extensions:
                for extension in args.upgrade_extensions:
                    stage.append(_construct_git_pull(f'extensions/{extension}', version=version))
                    rsync.append(_construct_rsync_command(time=args.ignoretime, location=f'/srv/mediawiki-staging/{version}/extensions/{extension}/*', dest=f'/srv/mediawiki/{version}/extensions/{extension}/'))
                    rsyncpaths.append(f'/srv/mediawiki/{version}/extensions/{extension}/')

            if args.upgrade_skins:
                for skin in args.upgrade_skins:
                    stage.append(_construct_git_pull(f'skins/{skin}', version=version))
                    rsync.append(_construct_rsync_command(time=args.ignoretime, location=f'/srv/mediawiki-staging/{version}/skins/{skin}/*', dest=f'/srv/mediawiki/{version}/skins/{skin}/'))
                    rsyncpaths.append(f'/srv/mediawiki/{version}/skins/{skin}/')

        for cmd in stage:  # setup env, git pull etc
            exitcodes.append(run_command(cmd))
        non_zero_code(exitcodes, nolog=args.nolog)
        for option in options:  # configure rsync & custom data for repos
            if options[option]:
                if option == 'world':  # install steps for world
                    option = version
                    os.chdir(_get_staging_path(version))
                    exitcodes.append(run_command(f'sudo -u {DEPLOYUSER} composer install --no-dev --quiet'))
                    rebuild.append(f'sudo -u {DEPLOYUSER} MW_INSTALL_PATH=/srv/mediawiki-staging/{version} php /srv/mediawiki-staging/{version}/extensions/WikiForgeMagic/maintenance/rebuildVersionCache.php --save-gitinfo --version={version} --wiki={envinfo["wikidbname"]} --conf=/srv/mediawiki-staging/config/LocalSettings.php')
                    rsyncpaths.append(f'/srv/mediawiki/cache/{version}/gitinfo/')
                rsync.append(_construct_rsync_command(time=args.ignoretime, location=f'{_get_staging_path(option)}*', dest=_get_deployed_path(option)))
        non_zero_code(exitcodes, nolog=args.nolog)
        if args.files and not version:  # specfic extra files
            files = str(args.files).split(',')
            for file in files:
                rsync.append(_construct_rsync_command(time=args.ignoretime, recursive=False, location=f'/srv/mediawiki-staging/{file}', dest=f'/srv/mediawiki/{file}'))
        if args.folders and not version:  # specfic extra folders
            folders = str(args.folders).split(',')
            for folder in folders:
                rsync.append(_construct_rsync_command(time=args.ignoretime, location=f'/srv/mediawiki-staging/{folder}/*', dest=f'/srv/mediawiki/{folder}/'))

        if args.extension_list and version:  # when adding skins/exts
            rebuild.append(f'sudo -u {DEPLOYUSER} php /srv/mediawiki/{version}/extensions/CreateWiki/maintenance/rebuildExtensionListCache.php --wiki={envinfo["wikidbname"]} --cachedir=/srv/mediawiki/cache/{version}')

        for cmd in rsync:  # move staged content to live
            exitcodes.append(run_command(cmd))
        non_zero_code(exitcodes)
        if args.l10n and version:  # setup l10n
            if args.lang:
                lang = f'--lang={args.lang}'
            else:
                lang = ''

            postinstall.append(f'sudo -u {DEPLOYUSER} php /srv/mediawiki/{version}/maintenance/mergeMessageFileList.php --quiet --wiki={envinfo["wikidbname"]} --output /srv/mediawiki/config/ExtensionMessageFiles.php')
            rebuild.append(f'sudo -u {DEPLOYUSER} php /srv/mediawiki/{version}/maintenance/rebuildLocalisationCache.php {lang} --quiet --wiki={envinfo["wikidbname"]}')

        for cmd in postinstall:  # cmds to run after rsync & install (like mergemessage)
            exitcodes.append(run_command(cmd))
        non_zero_code(exitcodes, nolog=args.nolog)
        for cmd in rebuild:  # update ext list + l10n
            exitcodes.append(run_command(cmd))
        non_zero_code(exitcodes, nolog=args.nolog)

        # see if we are online - exit code 3 if not
        if args.port:
            check_up(Debug=None, Host=envinfo['wikiurl'], verify=False, force=args.force, nolog=args.nolog, port=args.port)
        else:
            check_up(Debug=None, Host=envinfo['wikiurl'], verify=False, force=args.force, nolog=args.nolog)

    # actually set remote lists
    for option in options:
        if options[option]:
            if option == 'world':
                option = version
            rsyncpaths.append(_get_deployed_path(option))
    if args.files and not version:
        for file in str(args.files).split(','):
            rsyncfiles.append(f'/srv/mediawiki/{file}')
    if args.folders and not version:
        for folder in str(args.folders).split(','):
            rsyncpaths.append(f'/srv/mediawiki/{folder}/')
    if args.extension_list and version:
        rsyncfiles.append(f'/srv/mediawiki/cache/{version}/extension-list.json')
    if args.l10n and version:
        rsyncpaths.append(f'/srv/mediawiki/cache/{version}/l10n/')

    for path in rsyncpaths:
        exitcodes.append(remote_sync_file(time=args.ignoretime, serverlist=args.servers, path=path, force=args.force, envinfo=envinfo, nolog=args.nolog))
    for file in rsyncfiles:
        exitcodes.append(remote_sync_file(time=args.ignoretime, serverlist=args.servers, path=file, recursive=False, force=args.force, envinfo=envinfo, nolog=args.nolog))

    fintext = f'finished deploy of "{str(loginfo)}" to {synced}'

    failed = non_zero_code(ec=exitcodes, leave=False)
    if failed:
        fintext += f' - FAIL: {exitcodes}'
    else:
        fintext += ' - SUCCESS'
    fintext += f' in {str(int(time.time() - start))}s'
    if not args.nolog:
        os.system(f'/usr/local/bin/logsalmsg {fintext}')
    else:
        print(fintext)
    if failed:
        exit(1)


class UpgradeExtensionsAction(argparse.Action):
    def __call__(self, parser, namespace, values, option_string=None):  # noqa: U100
        versions = getattr(namespace, 'versions', None)
        if not versions:
            parser.error('--versions is required when using --upgrade-extensions (--versions must come before --upgrade-extensions)')
        input_extensions = values.split(',')
        valid_extensions = get_valid_extensions(versions)
        if 'all' in input_extensions:
            input_extensions = valid_extensions
        invalid_extensions = set(input_extensions) - set(valid_extensions)
        if invalid_extensions:
            parser.error(f'invalid extension choice(s): {", ".join(invalid_extensions)}')
        setattr(namespace, self.dest, input_extensions)


class UpgradeSkinsAction(argparse.Action):
    def __call__(self, parser, namespace, values, option_string=None):  # noqa: U100
        versions = getattr(namespace, 'versions', None)
        if not versions:
            parser.error('--versions is required when using --upgrade-skins (--versions must come before --upgrade-skins)')
        input_skins = values.split(',')
        valid_skins = get_valid_skins(versions)
        if 'all' in input_skins:
            input_skins = valid_skins
        invalid_skins = set(input_skins) - set(valid_skins)
        if invalid_skins:
            parser.error(f'invalid skin choice(s): {", ".join(invalid_skins)}')
        setattr(namespace, self.dest, input_skins)


class UpgradePackAction(argparse.Action):
    def __call__(self, parser, namespace, value, option_string=None):  # noqa: U100
        extensions_in_pack = get_extensions_in_pack(value)
        skins_in_pack = get_skins_in_pack(value)
        setattr(namespace, 'upgrade_extensions', extensions_in_pack)
        setattr(namespace, 'upgrade_skins', skins_in_pack)


class LangAction(argparse.Action):
    def __call__(self, parser, namespace, values, option_string=None):  # noqa: U100
        if not getattr(namespace, 'l10n', False):
            parser.error('--lang can not be used without --l10n (--l10n must come before --lang)')
        invalid_langs = []
        for language in values.split(','):
            if not tag_is_valid(language):
                invalid_langs.append(language)
        if invalid_langs:
            parser.error(f'invalid language choice(s): {", ".join(invalid_langs)}')


class VersionsAction(argparse.Action):
    def __call__(self, parser, namespace, values, option_string=None):  # noqa: U100
        input_versions = values.split(',')
        valid_versions = [version for version in versions.values() if os.path.exists(f'/srv/mediawiki-staging/{version}')]
        if 'all' in input_versions:
            input_versions = valid_versions
        invalid_versions = set(input_versions) - set(valid_versions)
        if invalid_versions:
            parser.error(f'invalid version choice(s): {", ".join(invalid_versions)}')
        setattr(namespace, self.dest, input_versions)


class ServersAction(argparse.Action):
    def __call__(self, parser, namespace, values, option_string=None):  # noqa: U100
        input_servers = values.split(',')
        valid_servers = get_environment_info()['servers']
        if 'all' in input_servers:
            input_servers = valid_servers
        invalid_servers = set(input_servers) - set(valid_servers)
        if invalid_servers:
            parser.error(f'invalid server choice(s): {", ".join(invalid_servers)}')
        setattr(namespace, self.dest, input_servers)


if __name__ == '__main__':
    start = time.time()
    parser = argparse.ArgumentParser(description='Process some integers.')
    parser.add_argument('--pull', dest='pull')
    parser.add_argument('--branch', dest='branch')
    parser.add_argument('--reset-world', dest='reset_world', action='store_true')
    parser.add_argument('--upgrade-world', dest='upgrade_world', action='store_true')
    parser.add_argument('--config', dest='config', action='store_true')
    parser.add_argument('--world', dest='world', action='store_true')
    parser.add_argument('--landing', dest='landing', action='store_true')
    parser.add_argument('--errorpages', dest='errorpages', action='store_true')
    parser.add_argument('--l10n', dest='l10n', action='store_true')
    parser.add_argument('--extension-list', dest='extension_list', action='store_true')
    parser.add_argument('--no-log', dest='nolog', action='store_true')
    parser.add_argument('--force', dest='force', action='store_true')
    parser.add_argument('--files', dest='files')
    parser.add_argument('--folders', dest='folders')
    parser.add_argument('--lang', dest='lang', action=LangAction, help='l10n language(s) to rebuild, defaults to all')
    parser.add_argument('--versions', dest='versions', action=VersionsAction, default=[os.popen(f'getMWVersion {get_environment_info()["wikidbname"]}').read().strip()], help='version(s) to deploy')
    parser.add_argument('--upgrade-extensions', dest='upgrade_extensions', action=UpgradeExtensionsAction, help='extension(s) to upgrade')
    parser.add_argument('--upgrade-skins', dest='upgrade_skins', action=UpgradeSkinsAction, help='skin(s) to upgrade')
    parser.add_argument('--upgrade-pack', dest='upgrade_pack', action=UpgradePackAction, choices=['bundled', 'miraheze', 'mleb', 'wikiforge'], help='pack of extensions/skins to upgrade')
    parser.add_argument('--servers', dest='servers', action=ServersAction, required=True, help='server(s) to deploy to')
    parser.add_argument('--ignore-time', dest='ignoretime', action='store_true')
    parser.add_argument('--port', dest='port')

    run(parser.parse_args(), start)