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
# xper_save.sh "before jump"
git add $PROJ_DIR && git commit -m "commit by $USERNAME before jump"
xper.sh modify # if you delete this, git checkout on the next line will give error and incorrectly change the reference of the target_node
git checkout ${TARGET_NODE}

OWNER=$(xper_owner.sh)
LOCKED=$(xper_ctx.sh locked)
if [[ $OWNER != $USERNAME ]]; then
	xper.sh finish
else
	xper.sh modify
fi

if [[ $FIRST -eq 1 ]]; then
	xper.sh goto -f 1
elif [[ $LAST -eq 1 ]]; then
	xper.sh goto -b 1 # TODO: fix this!
fi
