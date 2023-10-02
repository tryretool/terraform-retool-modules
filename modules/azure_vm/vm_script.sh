#!/bin/bash

#make an easy to find directory
mkdir /retool
cd /retool

# Clone Retool repository
git clone https://github.com/tryretool/retool-onpremise.git
cd retool-onpremise

# Rewrite Dockerfile
echo FROM tryretool/backend:${version_number} > Dockerfile
echo CMD ./docker_scripts/start_api.sh >> Dockerfile

# Initialize Docker and Retool Installation
./install.sh

# Run services
docker-compose up -d

# exit code for success in terraform
exit 0