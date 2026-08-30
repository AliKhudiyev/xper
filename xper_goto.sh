#!/bin/bash
# usage: xper_goto STR_VERSION FLAG_FIRST FLAG_LAST STR_USER

VERSION=$1
FIRST=$2
LAST=$3
USER=$4

USERNAME=$(xper_user.sh); [[ $USER == "" ]] && USER=$USERNAME
TARGET_NODE="${USER}_${VERSION}"
CURRENT_VERSION=$(git branch --show-current)
PROJ_DIR=$(git rev-parse --show-toplevel)
MAX_VERSIONS=1000000000

if [[ $VERSION == "" ]]; then
	TARGET_NODE=$USER
fi

echo version=$VERSION first=$FIRST last=$LAST user=$USER
xper_save.sh "before jump"
# git add $PROJ_DIR && git commit -m "commit by $USERNAME before jump"
git checkout ${TARGET_NODE}

if [[ $FIRST -eq 1 ]]; then
	xper.sh goto -f 1
elif [[ $LAST -eq 1 ]]; then
	xper.sh goto -b 1 # TODO: fix this!
fi
