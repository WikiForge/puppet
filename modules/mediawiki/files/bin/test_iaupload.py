import argparse
import unittest
import tempfile
import os
from datetime import datetime, timedelta
from unittest.mock import MagicMock, patch
from iaupload import ArchiveUploader


class TestArchiveUploader(unittest.TestCase):
    def setUp(self):
        self.uploader = ArchiveUploader()
        self.uploader.parser = argparse.ArgumentParser(
            description='Uploads a file to archive.org.')
        self.uploader.parser.add_argument(
            '--title', dest='title', required=True,
            help='The title of the file to be used on archive.org. Will be both the title and identifier. Required.')
        self.uploader.parser.add_argument(
            '--description', dest='description', default='',
            help='The description of the file to be used on archive.org. Optional. Default: empty')
        self.uploader.parser.add_argument(
            '--mediatype', dest='mediatype', default='web',
            help='The media type of the file to be used on archive.org. Optional. Default: web')
        self.uploader.parser.add_argument(
            '--subject', dest='subject', default='wikiforge;wikiteam',
            help='Subject (topics) of the file for archive.org. Multiple topics can be separated by a semicolon. Optional. Default: wikiforge;wikiteam')
        self.uploader.parser.add_argument(
            '--collection', dest='collection', default='opensource',
            help='The name of the collection to use on archive.org. Optional. Default: opensource')
        self.uploader.parser.add_argument(
            '--file', dest='file', required=True,
            help='The local path to the file to be uploaded to archive.org. Required.')

    def test_args(self):
        args = self.uploader.parser.parse_args(['--title', 'test_title', '--file', '/path/to/test_file'])
        self.assertEqual(args.title, 'test_title')
        self.assertEqual(args.file, '/path/to/test_file')
        self.assertEqual(args.collection, 'opensource')
        self.assertEqual(args.description, '')
        self.assertEqual(args.mediatype, 'web')
        self.assertEqual(args.subject, 'wikiforge;wikiteam')

    @patch('internetarchive.get_item')
    def test_upload(self, mock_get_item):
        with tempfile.NamedTemporaryFile(delete=False) as f:
            f.write(b'test data')

        mock_item = MagicMock()
        mock_get_item.return_value = mock_item

        now = datetime.now()
        mtime = (now - timedelta(days=1)).timestamp()
        os.utime(f.name, (mtime, mtime))

        self.uploader.parser.parse_args(['--title', 'test_title', '--file', f.name])
        self.uploader.upload()

        mock_item.upload.assert_called_once_with(f.name, metadata={
            'collection': 'opensource',
            'date': now.strftime('%Y-%m-%d'),
            'description': '',
            'mediatype': 'web',
            'subject': 'wikiforge;wikiteam',
            'title': 'test_title',
        }, verbose=True, queue_derive=False)

        os.remove(f.name)


if __name__ == '__main__':
    unittest.main()
