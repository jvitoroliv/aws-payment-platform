#!/bin/bash -xe

sudo hostnamectl set-hostname ${ctms_hostname}
### make /tmp executable

sudo mount -o exec -o remount /tmp
##Install ansible
sudo amazon-linux-extras install ansible2 -y

# define current OS
os=$(uname -r)

# install requirements
if [[ $os == *"amzn2"* ]]; then
sudo yum install python3 -y
  sudo yum install -y python-pip
  pip install boto3==1.9.56
sudo  pip3 install virtualenv boto3==1.9.56
sudo  amazon-linux-extras install epel -y
elif [[ $os == *"amzn1"* ]]; then
  pip install boto3==1.9.56
  sudo yum install -y git
fi

# setup ansible environment
mkdir -p /tmp/ansible && cd /tmp/ansible && touch ansible.log

# get ansible for application: control-m
aws s3 sync s3://finserv-devops-automation/ansible/coreplatform/controlm/ .

# get ansible roles
#aws s3 sync s3://finserv-coreplatform-artifacts-us-east-1/ansible/roles/ ./roles/

# get python requirements
#aws s3 cp s3://finserv-coreplatform-artifacts-us-east-1/ansible/automation/requirements.txt ./requirements.txt
#aws s3 cp s3://finserv-coreplatform-artifacts-us-east-1/ansible/automation/ansible.cfg ./ansible.cfg

# install python requirements in virtualenv
if [[ $os == *"amzn2"* ]]; then
  python3 -m venv .venv && .venv/bin/pip install -r requirements.txt
elif [[ $os == *"amzn1"* ]]; then
  virtualenv .venv && .venv/bin/pip install -r requirements.txt
fi

sleep 600
# run ec2 bootstrap playbook
ansible-playbook ctm_secondary.yml --extra-vars "env=${environment} target=localhost"
# # run middleware install playbook
# .venv/bin/ansible-playbook install-middleware.yml \
#   -i "localhost," \
#   --extra-vars "env=${environment} application=control-m target=localhost"

# # run deploy playbook
# .venv/bin/ansible-playbook deploy.yml \
#   -i "localhost," \
#   --extra-vars "env=${environment} target=localhost"
echo "Adding Splunk application"
echo " "
echo " "
 
echo "Remove any old forwarders"
echo " "
service splunk stop
rpm -qa | grep splunk
rpm -evv `rpm -qa | grep splunk`
rm -rf /opt/splunkforwarder
echo "Old Splunk forwarder uninstalled"
 
echo "Download new Splunk Universal Forwarder"
echo " "
cd /opt/
wget -O splunkforwarder-latest.rpm 'https://s3.amazonaws.com/finserv-splunk-universal-forwarder/splunkforwarder-latest.rpm'
 
echo "Install new forwarder"
echo " "
rpm -ivh splunkforwarder-latest.rpm
 
echo "Install/write user-seed.conf, file is destructively consumed after subsequent restart of splunkd"
echo " "
touch /opt/splunkforwarder/etc/system/local/user-seed.conf
cat << EOF | tee /opt/splunkforwarder/etc/system/local/user-seed.conf
[user_info]
USERNAME = admin
PASSWORD = ${SPLUNK_PASSWORD}
EOF
 
echo "Install/write deploymentclient.conf this wires splunk up to the global Deployment Server"
echo " "
touch /opt/splunkforwarder/etc/system/local/deploymentclient.conf
cat << EOF | tee /opt/splunkforwarder/etc/system/local/deploymentclient.conf
[target-broker:deploymentServer]
targetUri = 10.94.2.111:8089
EOF
 
echo "accept license and start"
echo " "
/opt/splunkforwarder/bin/splunk start --accept-license
 
echo "Install splunkd boot up script, must enter password specified in user-seed.conf"
echo " "
/opt/splunkforwarder/bin/splunk enable boot-start