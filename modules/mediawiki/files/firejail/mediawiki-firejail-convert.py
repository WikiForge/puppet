#! /usr/bin/python3

import subprocess
import sys
subprocess.call(
    [
        '/usr/bin/firejail',
        '--profile=/etc/firejail/mediawiki-converters.profile',
        '/usr/bin/convert',
    ]
    + sys.argv[1:],
)
