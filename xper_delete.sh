#!/bin/bash

USERNAME=$(xper_user.sh)
BASE=${USERNAME}
NODE=$(xper_version.sh 1)
CHILDREN=$(git branch --list "${NODE}.*" | grep -vE "${NODE}\..*\..*")
PROJ_DIR=$(xper_rootdir.sh)

if [[ $NODE != $BASE && $NODE == "$USERNAME"* ]]; then
	git add $PROJ_DIR && git commit -m "commit by $USERNAME before deletion of $NODE"
	git checkout $BASE
	git branch -D $NODE

	if [[ -e ".git/refs/index" ]]; then
		sed "/$NODE/d" .git/refs/index > .git/refs/index.tmp && mv .git/refs/index.tmp .git/refs/index
	fi

	for child in $CHILDREN; do
		git checkout $child
		xper_delete.sh
	done
else
	echo "[xper_delete] cannot delete $NODE (either BASE or not yours)"
fi
