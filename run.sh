#! /bin/ash

set -e
git clone $(cat /run/secrets/github_uri) /src 
ruby app.rb