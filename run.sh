#! /bin/ash

set -e
cat /run/secrets/dockerhub_password | docker login --username $DOCKER_USERNAME --password-stdin
ruby app.rb