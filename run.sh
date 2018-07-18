#! /bin/ash

set -e

REPOSRC=$( cat /run/secrets/github_uri )
LOCALREPO=/src

# We do it this way so that we can abstract if from just git later on
LOCALREPO_VC_DIR=$LOCALREPO/.git

if [ ! -d $LOCALREPO_VC_DIR ]
then
    git clone $REPOSRC $LOCALREPO
else
    cd $LOCALREPO
    git pull $REPOSRC
fi

cd /app

ruby app.rb