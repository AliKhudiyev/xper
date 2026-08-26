#!/bin/bash

USERNAME=$(git config --global user.name | tr -d ' ')
BASE=${USERNAME}
NODE=$(git branch --show-current)
CHILDREN=$(git branch --list "${NODE}.*" | grep -vE "${NODE}\..*\..*")
PROJ_DIR=$(git rev-parse --show-toplevel)

if [[ $NODE != $BASE ]]; then
	git add $PROJ_DIR/** && git commit -m "before deletion by $USERNAME"
	git checkout $BASE
	git branch -D $NODE
	for child in $CHILDREN; do
		git checkout $child
		xper_delete.sh
	done
else
	echo "Cannot delete BASE"
fi
