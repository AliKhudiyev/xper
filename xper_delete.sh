#!/bin/bash

USERNAME=$(git config --global user.name | tr -d ' ')
BASE=${USERNAME}
NODE=$(git branch --show-current)
CHILDREN=$(git branch --list "${NODE}.*" | grep -vE "${NODE}\..*\..*")

if [[ $NODE != $BASE ]]; then
	git checkout $BASE
	git branch -D $NODE
	for child in $CHILDREN; do
		git checkout $child
		xper_delete.sh
	done
else
	echo "Cannot delete BASE"
fi
