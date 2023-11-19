import os
import mwscript
from unittest.mock import patch


def test_get_command_simple():
    args = mwscript.get_args()
    args.script = 'test.php'
    args.arguments = ['hubwiki']
    args.version = '1.39'
    assert mwscript.get_commands(args) == {'confirm': False, 'command': 'sudo -u www-data php /srv/mediawiki/1.39/maintenance/test.php --wiki=hubwiki', 'generate': None, 'long': False, 'nolog': False}


def test_get_command_extension():
    args = mwscript.get_args()
    args.script = 'extensions/CheckUser/test.php'
    args.arguments = ['hubwiki']
    args.version = '1.39'
    assert mwscript.get_commands(args) == {'confirm': False, 'command': 'sudo -u www-data php /srv/mediawiki/1.39/extensions/CheckUser/maintenance/test.php --wiki=hubwiki', 'generate': None, 'long': False, 'nolog': False}


@patch.dict(os.environ, {'LOGNAME': 'test'})
@patch('os.getlogin')
@patch('builtins.input')
def test_get_command_extension_list(mock_input, mock_getlogin):
    mock_getlogin.return_value = 'test'
    mock_input.return_value = 'wikiforge'
    args = mwscript.get_args()
    args.script = 'test.php'
    args.extension = 'CheckUser'
    args.version = '1.39'
    assert mwscript.get_commands(args) == {
        'confirm': False,
        'command': f'sudo -u www-data /usr/local/bin/foreachwikiindblist /home/{os.environ["LOGNAME"]}/CheckUser.json /srv/mediawiki/1.39/maintenance/test.php',
        'generate': 'php /srv/mediawiki/1.39/extensions/WikiForgeMagic/maintenance/generateExtensionDatabaseList.php --wiki=hubwiki --extension=CheckUser',
        'long': True,
        'nolog': False,
    }


def test_get_command_all():
    args = mwscript.get_args()
    args.script = 'test.php'
    args.arguments = ['wikiforge']
    args.version = '1.39'
    assert mwscript.get_commands(args) == {'confirm': False, 'command': 'sudo -u www-data /usr/local/bin/foreachwikiindblist /srv/mediawiki/cache/databases-wikiforge.json /srv/mediawiki/1.39/maintenance/test.php', 'generate': None, 'long': True, 'nolog': False}


def test_get_command_args():
    args = mwscript.get_args()
    args.script = 'test.php'
    args.arguments = ['hubwiki', '--test']
    args.version = '1.39'
    assert mwscript.get_commands(args) == {'confirm': False, 'command': 'sudo -u www-data php /srv/mediawiki/1.39/maintenance/test.php --wiki=hubwiki --test', 'generate': None, 'long': False, 'nolog': False}


def test_get_command_subdir():
    args = mwscript.get_args()
    args.script = 'subdir/test.php'
    args.arguments = ['hubwiki']
    args.version = '1.39'
    assert mwscript.get_commands(args) == {'confirm': False, 'command': 'sudo -u www-data php /srv/mediawiki/1.39/maintenance/subdir/test.php --wiki=hubwiki', 'generate': None, 'long': False, 'nolog': False}


def test_get_command_simple_runner():
    args = mwscript.get_args()
    args.script = 'test.php'
    args.arguments = ['hubwiki']
    args.version = '1.40'
    assert mwscript.get_commands(args) == {'confirm': False, 'command': 'sudo -u www-data php /srv/mediawiki/1.40/maintenance/run.php /srv/mediawiki/1.40/maintenance/test.php --wiki=hubwiki', 'generate': None, 'long': False, 'nolog': False}


def test_get_command_extension_runner():
    args = mwscript.get_args()
    args.script = 'extensions/CheckUser/test.php'
    args.arguments = ['hubwiki']
    args.version = '1.40'
    assert mwscript.get_commands(args) == {'confirm': False, 'command': 'sudo -u www-data php /srv/mediawiki/1.40/maintenance/run.php /srv/mediawiki/1.40/extensions/CheckUser/maintenance/test.php --wiki=hubwiki', 'generate': None, 'long': False, 'nolog': False}


@patch.dict(os.environ, {'LOGNAME': 'test'})
@patch('os.getlogin')
@patch('builtins.input')
def test_get_command_extension_list_runner(mock_input, mock_getlogin):
    mock_getlogin.return_value = 'test'
    mock_input.return_value = 'wikiforge'
    args = mwscript.get_args()
    args.script = 'test.php'
    args.extension = 'CheckUser'
    args.version = '1.40'
    assert mwscript.get_commands(args) == {
        'confirm': False,
        'command': f'sudo -u www-data /usr/local/bin/foreachwikiindblist /home/{os.environ["LOGNAME"]}/CheckUser.json /srv/mediawiki/1.40/maintenance/run.php /srv/mediawiki/1.40/maintenance/test.php',
        'generate': 'php /srv/mediawiki/1.40/maintenance/run.php /srv/mediawiki/1.40/extensions/WikiForgeMagic/maintenance/generateExtensionDatabaseList.php --wiki=hubwiki --extension=CheckUser',
        'long': True,
        'nolog': False,
    }


def test_get_command_all_runner():
    args = mwscript.get_args()
    args.script = 'test.php'
    args.arguments = ['wikiforge']
    args.version = '1.40'
    assert mwscript.get_commands(args) == {'confirm': False, 'command': 'sudo -u www-data /usr/local/bin/foreachwikiindblist /srv/mediawiki/cache/databases-wikiforge.json /srv/mediawiki/1.40/maintenance/run.php /srv/mediawiki/1.40/maintenance/test.php', 'generate': None, 'long': True, 'nolog': False}


def test_get_command_args_runner():
    args = mwscript.get_args()
    args.script = 'test.php'
    args.arguments = ['hubwiki', '--test']
    args.version = '1.40'
    assert mwscript.get_commands(args) == {'confirm': False, 'command': 'sudo -u www-data php /srv/mediawiki/1.40/maintenance/run.php /srv/mediawiki/1.40/maintenance/test.php --wiki=hubwiki --test', 'generate': None, 'long': False, 'nolog': False}


def test_get_command_subdir_runner():
    args = mwscript.get_args()
    args.script = 'subdir/test.php'
    args.arguments = ['hubwiki']
    args.version = '1.40'
    assert mwscript.get_commands(args) == {'confirm': False, 'command': 'sudo -u www-data php /srv/mediawiki/1.40/maintenance/run.php /srv/mediawiki/1.40/maintenance/subdir/test.php --wiki=hubwiki', 'generate': None, 'long': False, 'nolog': False}


def test_get_command_class():
    args = mwscript.get_args()
    args.script = 'test'
    args.arguments = ['hubwiki', '--test']
    args.version = '1.40'
    args.confirm = True
    assert mwscript.get_commands(args) == {'confirm': True, 'command': 'sudo -u www-data php /srv/mediawiki/1.40/maintenance/run.php test --wiki=hubwiki --test', 'generate': None, 'long': False, 'nolog': False}
