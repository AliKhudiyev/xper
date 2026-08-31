#!/bin/bash

USERNAME=$(xper_user.sh)
BASE=${USERNAME}
GIT_REPO=$(git remote -v)
NODE=$(xper_version.sh 1)
CHILDREN=$(git branch --list "${NODE}.*" | grep -vE "${NODE}\..*\..*")
PROJ_DIR=$(xper_rootdir.sh)
ROOT_DIR=$(xper_rootdir.sh)
INDEX_FP=$ROOT_DIR/.index

if [[ $NODE != $BASE && $NODE == "$USERNAME"* ]]; then
	git add $PROJ_DIR && git commit -m "commit by $USERNAME before deletion of $NODE"
	git checkout $BASE
	git branch -D $NODE
	[[ $GIT_REPO != "" ]] && git push origin -d $NODE

	if [[ -e $INDEX_FP ]]; then
		sed "/$NODE/d" $INDEX_FP > $INDEX_FP.tmp && mv $INDEX_FP.tmp $INDEX_FP
	fi

	for child in $CHILDREN; do
		git checkout $child
		xper_delete.sh
	done
else
	echo "[xper_delete] cannot delete $NODE (either BASE or not yours)"
fi
