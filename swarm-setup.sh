#! /bin/sh
#
# File: swarm-setup.sh
#
# Purpose: Complete setup steps for the Jenkins worker node instance
#
# Pre-conditions:
#  slave.jar is downloaded to the user home directory
#  This script is run from the Git repo directory
#

echo 'Changing to user home directory'
cd

echo 'Installing Docker...'
wget -q -O docker-script.sh https://get.docker.com/
chmod +x docker-script.sh
./docker-script.sh

# Remove the Docker script file
rm docker-script.sh

sudo gpasswd -a $USER docker
sudo addgroup build
sudo adduser --disabled-password --system --ingroup build jenkins
sudo mkdir /home/jenkins/build
sudo chown jenkins:build /home/jenkins/build

# Install the Jenkins build agent agent code

echo 'Installing Jenkins Slave software'
sudo mkdir -p /opt/jenkins-slave
sudo mv slave.jar /opt/jenkins-slave
sudo chown -R root:root /opt/jenkins-slave

echo 'Installing Jenkins Swarm plugin client-side software'
wget -q -O swarm-client-1.24.jar \
http://maven.jenkins-ci.org/content/repositories/releases/org/jenkins-ci/plugins/swarm-client/1.24/swarm-client-1.24-jar-with-dependencies.jar
sudo mkdir -p /opt/swarm-client
sudo mv swarm-client*.jar /opt/swarm-client/
sudo chown -R root:root /opt/swarm-client

echo 'Installing Swarm init.d script'
cd
tee swarm << 'EOF' > /dev/null
#!/bin/sh
### BEGIN INIT INFO
# Provides:          swarm
# Required-Start:    $local_fs $network
# Required-Stop:     $local_fs
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: swarm
# Description:       swarm daemon
### END INIT INFO

PATH=/sbin:/usr/sbin:/bin:/usr/bin:/opt/packer

do_start () {
        # start Swarm
        exec java  -Xmx256m -Xmx256m -Dfile.encoding=UTF-8   -jar /opt/swarm-client/swarm-client-1.24.jar  -master http://jenkins-master:8080 -fsroot /home/jenkins -description 'auto' -labels 'slave' -name 'slave-auto' -executors 1 -mode exclusive
}

# stop case omitted as the instances are ephemeral
case "$1" in
  start|"")
        do_start
        ;;
  *)
        echo "Usage: swarm [start]" >&2
        exit 3
        ;;
esac
:
EOF

sudo chown root:root swarm
sudo mv swarm /etc/init.d/
sudo chmod 755 /etc/init.d/swarm
sudo update-rc.d swarm defaults

echo 'Installing UNZIP program'
cd
sudo apt-get -y -qq install unzip=6.0-8+deb7u2

echo 'Installing Packer program'
wget -q -O packer.zip https://dl.bintray.com/mitchellh/packer/packer_0.8.3_linux_amd64.zip
sudo mkdir -p /opt/packer
sudo unzip -d /opt/packer packer.zip
sudo chown root:staff /opt/packer/*

# Remove the Packer installation ZIP file
rm packer.zip

# Update gcloud SDK components
sudo gcloud components update -q

# Configure the Swarm service to start when the instance boots
sudo update-rc.d swarm defaults

# Remove the Git repository
rm -fr CPO200-Google-Container-Registry

# Remove this script
rm swarm-setup.sh

echo 'Finished with installation script'

