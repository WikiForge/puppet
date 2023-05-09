#! /usr/bin/python3

# Upload files to archive.org directly
# from the command line.
#
# Universal Omega 2022

import argparse
import internetarchive
import os
from datetime import datetime


class ArchiveUploader:
    def __init__(self):
        self.parser = argparse.ArgumentParser(
            description='Uploads a file to archive.org.')
        self.parser.add_argument(
            '--title', dest='title', required=True,
            help='The title of the file to be used on archive.org. Will be both the title and identifier. Required.')
        self.parser.add_argument(
            '--description', dest='description', default='',
            help='The description of the file to be used on archive.org. Optional. Default: empty')
        self.parser.add_argument(
            '--mediatype', dest='mediatype', default='web',
            help='The media type of the file to be used on archive.org. Optional. Default: web')
        self.parser.add_argument(
            '--subject', dest='subject', default='wikiforge;wikiteam',
            help='Subject (topics) of the file for archive.org. Multiple topics can be separated by a semicolon. Optional. Default: wikiforge;wikiteam')
        self.parser.add_argument(
            '--collection', dest='collection', default='opensource',
            help='The name of the collection to use on archive.org. Optional. Default: opensource')
        self.parser.add_argument(
            '--file', dest='file', required=True,
            help='The local path to the file to be uploaded to archive.org. Required.')

    def upload(self):
        args = self.parser.parse_args()

        item = internetarchive.get_item(args.title)

        # get last modification time from file to use as the publication date in archive.org
        mtime = os.path.getmtime(args.file)
        dt = datetime.fromtimestamp(mtime)
        date = datetime.strftime(dt, '%Y-%m-%d')

        # set metadata
        # see https://archive.org/developers/metadata-schema for valid options
        md = {
            'collection': args.collection,
            'date': date,
            'description': args.description,
            'mediatype': args.mediatype,
            'subject': args.subject,
            'title': args.title,
        }

        # actually upload the file
        item.upload(args.file, metadata=md, verbose=True, queue_derive=False)


if __name__ == '__main__':
    uploader = ArchiveUploader()
    uploader.upload()
