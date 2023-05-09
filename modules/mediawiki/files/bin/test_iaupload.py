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

    def test_args(self):
        args = self.uploader.parser.parse_args(['--title', 'test_title', '--file', '/path/to/test_file'])
        self.assertEqual(args.title, 'test_title')
        self.assertEqual(args.file, '/path/to/test_file')
        self.assertEqual(args.collection, 'opensource')
        self.assertEqual(args.description, '')
        self.assertEqual(args.mediatype, 'web')
        self.assertEqual(args.subject, 'wikiforge;wikiteam')

    @patch('iaupload.ArchiveUploader')
    @patch('internetarchive.get_item')
    def test_upload(self, mock_get_item, mock_archive_uploader):
        with tempfile.NamedTemporaryFile(delete=False) as f:
            f.write(b'test data')

        mock_item = MagicMock()
        mock_get_item.return_value = mock_item

        now = datetime.now()
        mtime = (now - timedelta(days=1)).timestamp()
        os.utime(f.name, (mtime, mtime))

        mock_archive_uploader.parser.parse_args.return_value = argparse.Namespace(
            title='test_title',
            file=f.name,
            collection='opensource',
            description='',
            mediatype='web',
            subject='wikiforge;wikiteam',
        )

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
