#!/usr/bin/env bash
# usage: xper_goto STR_VERSION FLAG_FIRST FLAG_LAST STR_USER

VERSION=$1
USER=$2

USERNAME=$(xper_user.sh); [[ $USER == "" ]] && USER=$USERNAME
TARGET_NODE="${USER}_${VERSION}"
CURRENT_VERSION=$(xper_version.sh 1)
PROJ_DIR=$(xper_rootdir.sh)
FINISHED=$(xper_ctx.sh finished)

if [[ $VERSION == "" ]]; then
	TARGET_NODE=$USER
fi

# echo version=$VERSION first=$FIRST last=$LAST user=$USER
# xper_save.sh "before jump"
xper.sh modify --yes # if you delete this, git checkout on the next line will give error and incorrectly change the reference of the target_node
xper_ctx.sh finished $FINISHED
xper_save.sh "before jump"
git checkout ${TARGET_NODE} > /dev/null 2>&1

OWNER=$(xper_owner.sh)
LOCKED=$(xper_ctx.sh locked)
FINISHED=$(xper_ctx.sh finished)

if [[ $OWNER != $USERNAME || $FINISHED -eq 1 ]]; then
	xper.sh finish --yes
else
	xper.sh modify --yes
fi
