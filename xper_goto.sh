#!/bin/bash
# usage: xper_goto STR_VERSION FLAG_FIRST FLAG_LAST

VERSION=$1
FIRST=$2
LAST=$3

USERNAME=$(git config --global user.name | tr -d ' ')
TARGET_NODE="${USERNAME}_${VERSION}"
CURRENT_VERSION=$(git branch --show-current)
PROJ_DIR=$(git rev-parse --show-toplevel)
MAX_VERSIONS=1000000000

if [[ $VERSION == "" ]]; then
	TARGET_NODE=$USERNAME
fi

echo version=$VERSION first=$FIRST last=$LAST
git add $PROJ_DIR && git commit -m "commit by $USERNAME before jump"
git checkout ${TARGET_NODE}

if [[ $FIRST -eq 1 ]]; then
	xper.sh goto -f 1
elif [[ $LAST -eq 1 ]]; then
	xper.sh goto -b 1 # TODO: fix this!
fi
