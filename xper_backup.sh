#!/bin/bash
# usage: xper_backup.sh FLAG_GLOBAL

GLOBAL=$1

PUSHLOCKED=$(xper_locked.sh)
if [[ $PUSHLOCKED -eq 1 ]]; then
	echo "[xper_backup] you're locked"
	exit 0
fi

xper.sh update
failed=$?

if [[ $failed -ne 0 ]]; then
	echo "[xper_backup.sh] failed"
	exit $failed
fi

GIT_REPO=$(git remote -v)
USERNAME=$(xper_user.sh)
BRANCH=$(xper_version.sh 1)
PROJ_DIR=$(xper_rootdir.sh)

if [[ $GIT_REPO == "" ]]; then
	echo "no remote repository was found"
	exit 1
fi

USER=$(xper_user.sh)
MODE=$(xper_ctx.sh mode)
LOCKED=$(xper_ctx.sh locked)
TAG=$(xper_ctx.sh tag)

echo user=$USER mode=$MODE locked=$LOCKED tag=$TAG

xper_save.sh "before backup"
git push -u origin $BRANCH
# git add $PROJ_DIR && git commit -m "commit by $USERNAME" && git push -u origin $BRANCH
failed=$?

if [[ $failed -ne 0 ]]; then
	echo "[xper_backup] failed"
	exit 1
fi
