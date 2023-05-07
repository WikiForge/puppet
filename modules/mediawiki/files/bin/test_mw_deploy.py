import importlib
import argparse
import re
import pytest
import unittest
from unittest.mock import MagicMock, patch

deploy_mediawiki = importlib.import_module('deploy-mediawiki')

UpgradePackAction = deploy_mediawiki.UpgradePackAction
LangAction = deploy_mediawiki.LangAction
VersionsAction = deploy_mediawiki.VersionsAction
ServersAction = deploy_mediawiki.ServersAction


class TestTagFunctions(unittest.TestCase):
    def setUp(self):
        self.path = 'test/path'
        self.version = 'version'
        self.repo_dir = '/srv/mediawiki-staging/version/test/path'
        self.changed_files = ['tests/test1.js', 'resources/test1.js', 'src/main.php', 'test.sql', 'sql/test.sql', 'composer.lock', 'i18n/messages.json']
        self.expected_codechange_files = {'resources/test1.js', 'src/main.php'}
        self.expected_schema_files = {'test.sql', 'sql/test.sql'}
        self.expected_build_files = {'tests/test1.js', 'composer.lock'}
        self.expected_i18n_files = {'i18n/messages.json'}


    def test_get_change_tag_map(self):
        tag_map = deploy_mediawiki.get_change_tag_map()
        self.assertIsInstance(tag_map, dict)
        self.assertTrue(all(isinstance(pattern, type(re.compile(''))) for pattern in tag_map.keys()))
        self.assertTrue(all(isinstance(tag, str) for tag in tag_map.values()))


    @patch('os.popen')
    def test_get_changed_files(self, mock_popen):
        mock_popen.return_value.readlines.return_value = self.changed_files
        changed_files = deploy_mediawiki.get_changed_files(self.path, self.version)
        self.assertIsInstance(changed_files, list)
        self.assertCountEqual(changed_files, self.changed_files)
        mock_popen.assert_called_with(f'git -C {self.repo_dir} --no-pager --git-dir={self.repo_dir}/.git diff --name-only HEAD@{{1}} HEAD 2> /dev/null')


    def test_get_changed_files_type(self):
        codechange_files = deploy_mediawiki.get_changed_files_type(self.path, self.version, 'code change')
        schema_files = deploy_mediawiki.get_changed_files_type(self.path, self.version, 'schema change')
        build_files = deploy_mediawiki.get_changed_files_type(self.path, self.version, 'build')
        i18n_files = deploy_mediawiki.get_changed_files_type(self.path, self.version, 'i18n')
        self.assertIsInstance(codechange_files, set)
        self.assertIsInstance(schema_files, set)
        self.assertIsInstance(build_files, set)
        self.assertIsInstance(i18n_files, set)
        self.assertCountEqual(codechange_files, self.expected_codechange_files)
        self.assertCountEqual(schema_files, self.expected_schema_files)
        self.assertCountEqual(build_files, self.expected_build_files)
        self.assertCountEqual(i18n_files, self.expected_i18n_files)


    def test_get_change_tags(self):
        tags = deploy_mediawiki.get_change_tags(self.path, self.version)
        self.assertIsInstance(tags, set)
        self.assertTrue(all(isinstance(tag, str) for tag in tags))
        self.assertCountEqual(tags, {'code change', 'schema change', 'build', 'i18n'})


if __name__ == '__main__':
    unittest.main()


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
        deploy_mediawiki._construct_rsync_command(time=False, dest='/srv/mediawiki/version/')
    except Exception as e:
        assert str(e) == 'Location must be specified for local rsync.'
        failed = True
    assert failed


def test_construct_rsync_no_server_remote() -> None:
    failed = False
    try:
        deploy_mediawiki._construct_rsync_command(time=False, dest='/srv/mediawiki/version/', local=False)
    except Exception as e:
        assert str(e) == 'Error constructing command. Either server was missing or /srv/mediawiki/version/ != /srv/mediawiki/version/'
        failed = True
    assert failed


def test_construct_rsync_conflict_options_remote() -> None:
    failed = False
    try:
        deploy_mediawiki._construct_rsync_command(time=False, dest='/srv/mediawiki/version/', location='garbage', local=False, server='meta')
    except Exception as e:
        assert str(e) == 'Error constructing command. Either server was missing or garbage != /srv/mediawiki/version/'
        failed = True
    assert failed


def test_construct_rsync_conflict_options_no_server_remote() -> None:
    failed = False
    try:
        deploy_mediawiki._construct_rsync_command(time=False, dest='/srv/mediawiki/version/', location='garbage', local=False)
    except Exception as e:
        assert str(e) == 'Error constructing command. Either server was missing or garbage != /srv/mediawiki/version/'
        failed = True
    assert failed


def test_construct_rsync_local_dir_update() -> None:
    assert deploy_mediawiki._construct_rsync_command(time=False, dest='/srv/mediawiki/version/', location='/home/') == 'sudo -u www-data rsync --update -r --delete --exclude=".*" /home/ /srv/mediawiki/version/'


def test_construct_rsync_local_file_update() -> None:
    assert deploy_mediawiki._construct_rsync_command(time=False, dest='/srv/mediawiki/version/test.txt', location='/home/test.txt', recursive=False) == 'sudo -u www-data rsync --update --exclude=".*" /home/test.txt /srv/mediawiki/version/test.txt'


def test_construct_rsync_remote_dir_update() -> None:
    assert deploy_mediawiki._construct_rsync_command(time=False, dest='/srv/mediawiki/version/', local=False, server='meta') == 'sudo -u www-data rsync --update -r --delete -e "ssh -i /srv/mediawiki-staging/deploykey" /srv/mediawiki/version/ www-data@meta.wikiforge.net:/srv/mediawiki/version/'


def test_construct_rsync_remote_file_update() -> None:
    assert deploy_mediawiki._construct_rsync_command(time=False, dest='/srv/mediawiki/version/test.txt', recursive=False, local=False, server='meta') == 'sudo -u www-data rsync --update -e "ssh -i /srv/mediawiki-staging/deploykey" /srv/mediawiki/version/test.txt www-data@meta.wikiforge.net:/srv/mediawiki/version/test.txt'


def test_construct_rsync_local_dir_time() -> None:
    assert deploy_mediawiki._construct_rsync_command(time=True, dest='/srv/mediawiki/version/', location='/home/') == 'sudo -u www-data rsync --inplace -r --delete --exclude=".*" /home/ /srv/mediawiki/version/'


def test_construct_rsync_local_file_time() -> None:
    assert deploy_mediawiki._construct_rsync_command(time=True, dest='/srv/mediawiki/version/test.txt', location='/home/test.txt', recursive=False) == 'sudo -u www-data rsync --inplace --exclude=".*" /home/test.txt /srv/mediawiki/version/test.txt'


def test_construct_rsync_remote_dir_time() -> None:
    assert deploy_mediawiki._construct_rsync_command(time=True, dest='/srv/mediawiki/version/', local=False, server='meta') == 'sudo -u www-data rsync --inplace -r --delete -e "ssh -i /srv/mediawiki-staging/deploykey" /srv/mediawiki/version/ www-data@meta.wikiforge.net:/srv/mediawiki/version/'


def test_construct_rsync_remote_file_time() -> None:
    assert deploy_mediawiki._construct_rsync_command(time=True, dest='/srv/mediawiki/version/test.txt', recursive=False, local=False, server='meta') == 'sudo -u www-data rsync --inplace -e "ssh -i /srv/mediawiki-staging/deploykey" /srv/mediawiki/version/test.txt www-data@meta.wikiforge.net:/srv/mediawiki/version/test.txt'


def test_construct_git_pull() -> None:
    assert deploy_mediawiki._construct_git_pull('config') == 'sudo -u www-data git -C /srv/mediawiki-staging/config/ pull --quiet'


def test_construct_git_pull_branch() -> None:
    assert deploy_mediawiki._construct_git_pull('config', branch='myfunbranch') == 'sudo -u www-data git -C /srv/mediawiki-staging/config/ pull origin myfunbranch --quiet'


def test_construct_git_pull_skin() -> None:
    assert deploy_mediawiki._construct_git_pull('skins/Vector', version='version') == 'sudo -u www-data git -C /srv/mediawiki-staging/version/skins/Vector pull --quiet'


def test_construct_git_pull_skin_no_quiet() -> None:
    assert deploy_mediawiki._construct_git_pull('skins/Vector', quiet=False, version='version') == 'sudo -u www-data git -C /srv/mediawiki-staging/version/skins/Vector pull 2> /dev/null'


def test_construct_git_pull_extension_sm() -> None:
    assert deploy_mediawiki._construct_git_pull('extensions/VisualEditor', submodules=True, version='version') == 'sudo -u www-data git -C /srv/mediawiki-staging/version/extensions/VisualEditor pull --recurse-submodules --quiet'


def test_construct_git_pull_extension_sm_no_quiet() -> None:
    assert deploy_mediawiki._construct_git_pull('extensions/VisualEditor', submodules=True, quiet=False, version='version') == 'sudo -u www-data git -C /srv/mediawiki-staging/version/extensions/VisualEditor pull --recurse-submodules 2> /dev/null'


def test_construct_git_pull_branch_sm() -> None:
    assert deploy_mediawiki._construct_git_pull('config', submodules=True, branch='test') == 'sudo -u www-data git -C /srv/mediawiki-staging/config/ pull --recurse-submodules origin test --quiet'


def test_construct_git_pull_branch_sm_no_quiet() -> None:
    assert deploy_mediawiki._construct_git_pull('config', submodules=True, branch='test', quiet=False) == 'sudo -u www-data git -C /srv/mediawiki-staging/config/ pull --recurse-submodules origin test 2> /dev/null'


def test_construct_git_reset_revert() -> None:
    assert deploy_mediawiki._construct_git_reset_revert('extensions/VisualEditor', version='version') == 'sudo -u www-data git -C /srv/mediawiki-staging/version/extensions/VisualEditor reset --hard HEAD@{1}'


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
