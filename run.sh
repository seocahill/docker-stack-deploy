#! /bin/ash

set -e
mkdir /src
git clone $APP_REPO /src
ruby app.rb