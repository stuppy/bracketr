#!/bin/bash

# https://dev.to/mweibel/deploying-next-js-on-aws-elasticbeanstalk-ab4

# need to install node first to be able to install yarn (as at prebuild no node is present yet)
echo "download/setup nodejs..."
sudo curl --silent --location https://rpm.nodesource.com/setup_12.x | sudo bash -
echo "yum nodejs..."
sudo yum -y install nodejs

# install yarn
echo "get yarn..."
sudo wget https://dl.yarnpkg.com/rpm/yarn.repo -O /etc/yum.repos.d/yarn.repo
echo "yum yarn..."
sudo yum -y install yarn

# install
cd /var/app/staging/

# debugging..
ls -lah

echo "yarn install..."
yarn install --prod

chown -R webapp:webapp node_modules/ || true # allow to fail
