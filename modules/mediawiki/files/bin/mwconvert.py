#! /usr/bin/python3

import paramiko
import sys

# SSH connection parameters
hostname = 'thumb-lb.wikiforge.net'
username = 'mwconvert'
private_key_path = '/home/mwconvert/.ssh/id_ed25519'

# Main script arguments
args = sys.argv[1:]  # Exclude the script name itself

# Construct the command
remote_script = '/usr/bin/convert'
command = f'{remote_script} {" ".join(args)}'

# Create SSH client
client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())

try:
    # Load private key
    private_key = paramiko.Ed25519Key.from_private_key_file(private_key_path)

    # Connect to the remote server
    client.connect(hostname, username=username, pkey=private_key)

    # Execute the script remotely
    client.exec_command(command)
finally:
    # Close the SSH connection
    client.close()
