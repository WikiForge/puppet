import importlib
import argparse
import pytest
from unittest.mock import MagicMock, patch

deploy_mediawiki = importlib.import_module('deploy-mediawiki')

UpgradePackAction = deploy_mediawiki.UpgradePackAction
LangAction = deploy_mediawiki.LangAction
VersionsAction = deploy_mediawiki.VersionsAction
ServersAction = deploy_mediawiki.ServersAction


def test_get_valid_extensions():
    versions = ['version1', 'version2']
    extensions1 = ['Extension1', 'Extension2']
    extensions2 = ['Extension3', 'Extension4']

    with patch('os.scandir') as mock_scandir:
        mock_cm1 = MagicMock()
        mock_cm1.__enter__.return_value = [MagicMock(is_dir=lambda: True) for name in extensions1]
        for i, ext in enumerate(extensions1):
            setattr(mock_cm1.__enter__.return_value[i], 'name', ext)

        mock_cm2 = MagicMock()
        mock_cm2.__enter__.return_value = [MagicMock(is_dir=lambda: True) for name in extensions2]
        for i, ext in enumerate(extensions2):
            setattr(mock_cm2.__enter__.return_value[i], 'name', ext)

        mock_scandir.side_effect = [mock_cm1, mock_cm2]

        extensions = deploy_mediawiki.get_valid_extensions(versions)
        assert extensions == extensions1 + extensions2


def test_get_valid_skins():
    versions = ['version1', 'version2']
    skins1 = ['Skins1', 'Skins2']
    skins2 = ['Skins3', 'Skins4']

    with patch('os.scandir') as mock_scandir:
        mock_cm1 = MagicMock()
        mock_cm1.__enter__.return_value = [MagicMock(is_dir=lambda: True) for name in skins1]
        for i, skin in enumerate(skins1):
            setattr(mock_cm1.__enter__.return_value[i], 'name', skin)

        mock_cm2 = MagicMock()
        mock_cm2.__enter__.return_value = [MagicMock(is_dir=lambda: True) for name in skins2]
        for i, skin in enumerate(skins2):
            setattr(mock_cm2.__enter__.return_value[i], 'name', skin)

        mock_scandir.side_effect = [mock_cm1, mock_cm2]

        skins = deploy_mediawiki.get_valid_skins(versions)
        assert skins == skins1 + skins2


def test_get_extensions_in_pack():
    extensions = deploy_mediawiki.get_extensions_in_pack('mleb')
    assert extensions == ['Babel', 'cldr', 'CleanChanges', 'Translate', 'UniversalLanguageSelector']


def test_get_skins_in_pack():
    skins = deploy_mediawiki.get_skins_in_pack('bundled')
    assert skins == ['MinervaNeue', 'MonoBook', 'Timeless', 'Vector']


def test_non_zero_ec_only_one_zero() -> None:
    assert not deploy_mediawiki.non_zero_code([0], leave=False)


def test_non_zero_ec_multi_zero() -> None:
    assert not deploy_mediawiki.non_zero_code([0, 0], leave=False)


def test_non_zero_ec_zero_one() -> None:
    assert deploy_mediawiki.non_zero_code([1, 0], leave=False)


def test_non_zero_ec_one_one() -> None:
    assert deploy_mediawiki.non_zero_code([1, 1], leave=False)


def test_non_zero_ec_only_one_one() -> None:
    assert deploy_mediawiki.non_zero_code([1], leave=False)


def test_check_up_no_debug_host() -> None:
    failed = False
    try:
        deploy_mediawiki.check_up(nolog=True)
    except Exception as e:
        assert str(e) == 'Host or Debug must be specified'
        failed = True
    assert failed


def test_check_up_debug() -> None:
    assert deploy_mediawiki.check_up(nolog=True, Debug='mw1')


def test_check_up_debug_fail() -> None:
    assert not deploy_mediawiki.check_up(nolog=True, Debug='mw1', domain='httpstat.us/500', force=True)


def test_get_staging_path() -> None:
    assert deploy_mediawiki._get_staging_path('version') == '/srv/mediawiki-staging/version/'


def test_get_deployed_path() -> None:
    assert deploy_mediawiki._get_deployed_path('version') == '/srv/mediawiki/version/'


def test_construct_rsync_no_location_local() -> None:
    failed = False
    try:
        deploy_mediawiki._construct_rsync_command(time=False, dest='/srv/mediawiki/w/')
    except Exception as e:
        assert str(e) == 'Location must be specified for local rsync.'
        failed = True
    assert failed


def test_construct_rsync_no_server_remote() -> None:
    failed = False
    try:
        deploy_mediawiki._construct_rsync_command(time=False, dest='/srv/mediawiki/w/', local=False)
    except Exception as e:
        assert str(e) == 'Error constructing command. Either server was missing or /srv/mediawiki/w/ != /srv/mediawiki/w/'
        failed = True
    assert failed


def test_construct_rsync_conflict_options_remote() -> None:
    failed = False
    try:
        deploy_mediawiki._construct_rsync_command(time=False, dest='/srv/mediawiki/w/', location='garbage', local=False, server='meta')
    except Exception as e:
        assert str(e) == 'Error constructing command. Either server was missing or garbage != /srv/mediawiki/w/'
        failed = True
    assert failed


def test_construct_rsync_conflict_options_no_server_remote() -> None:
    failed = False
    try:
        deploy_mediawiki._construct_rsync_command(time=False, dest='/srv/mediawiki/w/', location='garbage', local=False)
    except Exception as e:
        assert str(e) == 'Error constructing command. Either server was missing or garbage != /srv/mediawiki/w/'
        failed = True
    assert failed


def test_construct_rsync_local_dir_update() -> None:
    assert deploy_mediawiki._construct_rsync_command(time=False, dest='/srv/mediawiki/w/', location='/home/') == 'sudo -u www-data rsync --update -r --delete --exclude=".*" /home/ /srv/mediawiki/w/'


def test_construct_rsync_local_file_update() -> None:
    assert deploy_mediawiki._construct_rsync_command(time=False, dest='/srv/mediawiki/w/test.txt', location='/home/test.txt', recursive=False) == 'sudo -u www-data rsync --update --exclude=".*" /home/test.txt /srv/mediawiki/w/test.txt'


def test_construct_rsync_remote_dir_update() -> None:
    assert deploy_mediawiki._construct_rsync_command(time=False, dest='/srv/mediawiki/w/', local=False, server='meta') == 'sudo -u www-data rsync --update -r --delete -e "ssh -i /srv/mediawiki-staging/deploykey" /srv/mediawiki/w/ www-data@meta.wikiforge.net:/srv/mediawiki/w/'


def test_construct_rsync_remote_file_update() -> None:
    assert deploy_mediawiki._construct_rsync_command(time=False, dest='/srv/mediawiki/w/test.txt', recursive=False, local=False, server='meta') == 'sudo -u www-data rsync --update -e "ssh -i /srv/mediawiki-staging/deploykey" /srv/mediawiki/w/test.txt www-data@meta.wikiforge.net:/srv/mediawiki/w/test.txt'


def test_construct_rsync_local_dir_time() -> None:
    assert deploy_mediawiki._construct_rsync_command(time=True, dest='/srv/mediawiki/w/', location='/home/') == 'sudo -u www-data rsync --inplace -r --delete --exclude=".*" /home/ /srv/mediawiki/w/'


def test_construct_rsync_local_file_time() -> None:
    assert deploy_mediawiki._construct_rsync_command(time=True, dest='/srv/mediawiki/w/test.txt', location='/home/test.txt', recursive=False) == 'sudo -u www-data rsync --inplace --exclude=".*" /home/test.txt /srv/mediawiki/w/test.txt'


def test_construct_rsync_remote_dir_time() -> None:
    assert deploy_mediawiki._construct_rsync_command(time=True, dest='/srv/mediawiki/w/', local=False, server='meta') == 'sudo -u www-data rsync --inplace -r --delete -e "ssh -i /srv/mediawiki-staging/deploykey" /srv/mediawiki/w/ www-data@meta.wikiforge.net:/srv/mediawiki/w/'


def test_construct_rsync_remote_file_time() -> None:
    assert deploy_mediawiki._construct_rsync_command(time=True, dest='/srv/mediawiki/w/test.txt', recursive=False, local=False, server='meta') == 'sudo -u www-data rsync --inplace -e "ssh -i /srv/mediawiki-staging/deploykey" /srv/mediawiki/w/test.txt www-data@meta.wikiforge.net:/srv/mediawiki/w/test.txt'


def test_construct_git_pull() -> None:
    assert deploy_mediawiki._construct_git_pull('config') == 'sudo -u www-data git -C /srv/mediawiki-staging/config/ pull --quiet'


def test_construct_git_pull_branch() -> None:
    assert deploy_mediawiki._construct_git_pull('config', branch='myfunbranch') == 'sudo -u www-data git -C /srv/mediawiki-staging/config/ pull origin myfunbranch --quiet'


def test_construct_reset_mediawiki_rm_staging() -> None:
    assert deploy_mediawiki._construct_reset_mediawiki_rm_staging('version') == 'sudo -u www-data rm -rf /srv/mediawiki-staging/version/'


def test_construct_reset_mediawiki_run_puppet() -> None:
    assert deploy_mediawiki._construct_reset_mediawiki_run_puppet() == 'sudo puppet agent -tv'


def test_UpgradePackAction():
    parser = argparse.ArgumentParser()
    parser.add_argument('--upgrade-extensions', action='store_const', const=True, default=False)
    parser.add_argument('--upgrade-skins', action='store_const', const=True, default=False)
    parser.add_argument('--versions', action='store', default=None)
    parser.add_argument('--upgrade-pack', action=UpgradePackAction)
    namespace = parser.parse_args(['--upgrade-pack', 'wikiforge'])
    assert namespace.upgrade_extensions == ['WikiForgeMagic']


def test_LangAction():
    parser = argparse.ArgumentParser()
    parser.add_argument('--l10n', action='store_const', const=True, default=False)
    parser.add_argument('--lang', action=LangAction)

    with pytest.raises(SystemExit):
        parser.parse_args(['--lang', 'invalid_tag'])

    with pytest.raises(SystemExit):
        parser.parse_args(['--lang', 'en,fr'])

    namespace = parser.parse_args(['--l10n', '--lang', 'en,fr'])
    assert namespace.lang == 'en,fr'


def test_VersionsAction():
    deploy_mediawiki.versions.clear()
    with patch('os.path.exists', return_value=True), \
         patch.dict(deploy_mediawiki.versions, {'version1': 'version1', 'version2': 'version2'}):
        parser = argparse.ArgumentParser()
        parser.add_argument('--versions', action=VersionsAction)

        with pytest.raises(SystemExit):
            parser.parse_args(['--versions', 'invalid_version'])

        namespace = parser.parse_args(['--versions', 'version1'])
        assert namespace.versions == ['version1']

        namespace = parser.parse_args(['--versions', 'all'])
        assert namespace.versions == ['version1', 'version2']


def test_ServersAction():
    parser = argparse.ArgumentParser()
    parser.add_argument('--servers', action=ServersAction)
    with pytest.raises(SystemExit):
        parser.parse_args(['--servers', 'invalid_server'])
    namespace = parser.parse_args(['--servers', 'mw1,mw2'])
    assert namespace.servers == ['mw1', 'mw2']
