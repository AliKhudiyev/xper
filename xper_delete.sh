#!/bin/bash

USERNAME=$(git config --global user.name | tr -d ' ')
BASE=${USERNAME}
NODE=$(git branch --show-current)
CHILDREN=$(git branch --list "${NODE}.*" | grep -vE "${NODE}\..*\..*")
PROJ_DIR=$(git rev-parse --show-toplevel)

if [[ $NODE != $BASE ]]; then
	git add $PROJ_DIR && git commit -m "commit by $USERNAME before deletion of $NODE"
	git checkout $BASE
	git branch -D $NODE

	if [[ -e ".git/refs/index" ]]; then
		if [[ $OSTYPE == "darwin"* ]]; then
			sed -i "" "/$NODE/d" .git/refs/index
		else
			sed -i "/$NODE/d" .git/refs/index
		fi
	fi

	for child in $CHILDREN; do
		git checkout $child
		xper_delete.sh
	done
else
	echo "Cannot delete BASE"
fi
