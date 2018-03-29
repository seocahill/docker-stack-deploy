#! /bin/ash

set -e
export AUTHENTICATION_SECRET=$(cat /run/secrets/basic_auth_password)
cat /run/secrets/dockerhub_password | docker login --username $DOCKER_USERNAME --password-stdin
ruby app.rb