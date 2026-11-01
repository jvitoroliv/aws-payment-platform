#!/bin/bash

# sftp-server-init.sh
# sftp-server-init shell script

set -e

echo ' 												    ' &&
echo '   ___ ___ _____ ___   ___                        ' &&
echo '  / __| __|_   _| _ \ / __| ___ _ ___ _____ _ _   ' &&
echo '  \__ \ _|  | | |  _/ \__ \/ -_) |_\ V / -_) |_|  ' &&
echo '  |___/_|   |_| |_|   |___/\___|_|  \_/\___|_|    ' &&
echo ' 												    ' &&
echo '                                                  ' &&

echo 'Begin SFTP work...' &&

echo 'Update and install OpenSSH and UFW...' &&
apt-get update && apt-get install -y openssh-server &&
echo 'Run mkdir...' &&
mkdir -p /var/run/sshd &&
echo 'Change root password...' &&
echo 'root:root' | chpasswd &&
echo 'Add sftpuser...' &&
id -u sftpuser &>/dev/null || useradd -m -p /home/sftpuser -s /bin/bash sftpuser &&
echo 'sftpuser:sftp' | chpasswd &&
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config &&
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config &&
mkdir -p /home/sftpuser/upload &&
chown sftpuser:sftpuser /home/sftpuser/upload &&
/usr/sbin/sshd -D -e