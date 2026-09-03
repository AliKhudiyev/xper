#!/usr/bin/env bash

USERNAME=$(xper_user.sh)
BASE=${USERNAME}
GIT_REPO=$(git remote -v)
NODE=$(xper_version.sh 1)
CHILDREN=$(git branch --list "${NODE}.*" | grep -vE "${NODE}\..*\..*")
PROJ_DIR=$(xper_rootdir.sh)
ROOT_DIR=$(xper_rootdir.sh)
INDEX_FP=$ROOT_DIR/.index

if [[ $NODE != $BASE && $NODE == "$USERNAME"* ]]; then
	xper_save.sh "before deletion of $NODE"
	git checkout $BASE > /dev/null 2>&1
	git branch -D $NODE > /dev/null 2>&1
	[[ $GIT_REPO != "" ]] && git push origin -d $NODE > /dev/null 2>&1

	if [[ -e $INDEX_FP ]]; then
		sed "/$NODE/d" $INDEX_FP > $INDEX_FP.tmp && mv $INDEX_FP.tmp $INDEX_FP
	fi

	for child in $CHILDREN; do
		git checkout $child > /dev/null 2>&1
		xper_delete.sh
	done
else
	echo "[xper_delete] cannot delete $NODE (either BASE or not yours)"
fi
