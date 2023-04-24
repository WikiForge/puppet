#! /usr/bin/python3

import argparse
import os


def run(args: argparse.Namespace) -> None:
    longscripts = ('compressOld.php', 'deleteBatch.php', 'importDump.php', 'importImages.php', 'nukeNS.php', 'rebuildall.php', 'rebuildImages.php', 'refreshLinks.php', 'runJobs.php', 'purgeList.php', 'cargoRecreateData.php')
    long = False

    if not args.version:
        args.version = os.popen(f'getMWVersion {args.wiki}').read().strip()

    script = args.script
    scriptsplit = script.split('/')
    if script in longscripts:
        long = True
    if len(scriptsplit) == 1:
        script = f'/srv/mediawiki/{args.version}/maintenance/{script}'
    elif len(scriptsplit) == 2:
        script = f'/srv/mediawiki/{args.version}/maintenance/{scriptsplit[0]}/{scriptsplit[1]}'
        if scriptsplit[1] in longscripts:
            long = True
    else:
        script = f'/srv/mediawiki/{args.version}/{scriptsplit[0]}/{scriptsplit[1]}/maintenance/{scriptsplit[2]}'
        if scriptsplit[2] in longscripts:
            long = True

    wiki = args.wiki
    validDBLists = ('active')
    if wiki == 'all':
        long = True
        command = f'sudo -u www-data /usr/local/bin/foreachwikiindblist /srv/mediawiki/cache/databases.json {script}'
    elif wiki in validDBLists:
        long = True
        command = f'sudo -u www-data /usr/local/bin/foreachwikiindblist /srv/mediawiki/cache/{wiki}.json {script}'
    elif args.extension:
        long = True
        generate = f'php /srv/mediawiki/{args.version}/extensions/WikiForgeMagic/maintenance/generateExtensionDatabaseList.php --wiki=metawiki --extension={args.extension}'
        command = f'sudo -u www-data /usr/local/bin/foreachwikiindblist /home/{os.getlogin()}/{args.extension}.json {script}'
    else:
        command = f'sudo -u www-data php {script} --wiki={wiki}'
    if args.arguments:
        command += ' ' + ' '.join(args.arguments)
    logcommand = f'/usr/local/bin/logsalmsg "{command}'
    print('Will execute:')
    if 'generate' in locals():
        print(generate)
    print(command)
    if args.confirm or input("Type 'Y' to confirm: ").upper() == 'Y':
        if long and not args.nolog:
            os.system(f'{logcommand} (START)"')
        if 'generate' in locals():
            os.system(generate)
        return_value = os.system(command)
        logcommand += f' (END - exit={str(return_value)})"'
        if not args.nolog:
            print(f'Logging via {logcommand}')
            os.system(logcommand)
        print('Done!')
    else:
        print('Aborted!')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Process some integers.')
    parser.add_argument('script')
    parser.add_argument('wiki')
    parser.add_argument('arguments', nargs='*', default=[])
    parser.add_argument('--version', dest='version')
    parser.add_argument('--extension', '--skin', dest='extension')
    parser.add_argument('--no-log', dest='nolog', action='store_true')
    parser.add_argument('--confirm', '--yes', '-y', dest='confirm', action='store_true')

    args = parser.parse_known_args()[0]
    args.arguments += parser.parse_known_args()[1]

    run(args)
