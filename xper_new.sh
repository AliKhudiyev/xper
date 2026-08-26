#!/bin/bash

USERNAME="$(git config --local user.name)"
CURRENT_VERSION="$(git branch --show-current)"

if [[ ${#USERNAME} -eq 0 ]]; then
	USERNAME="$(git config --global user.name 2>/dev/null)"
fi
USERNAME=$(echo $USERNAME | tr -d ' ')
BASE=${USERNAME}

echo "username is $USERNAME"
echo "current version is $CURRENT_VERSION"

new_from_scratch(){
	git checkout $BASE
	CHILDREN=$(git branch --list "*v*" | grep -vE ".+v[0-9]+\..*" | sed -E "s/.+_v([0-9]+)/\1/g" | sort | tail -1)
	echo "main's last children = $CHILDREN"
	git checkout -b ${BASE}_v$((CHILDREN+1))
	git commit --allow-empty -m "Initial placeholder commit"
};

new_from_current(){
	CHILDREN=$(git branch --list "$CURRENT_VERSION.*" | grep -vE "$CURRENT_VERSION\..*\..*" | sed -E "s/${CURRENT_VERSION}\.([0-9]+)/\1/g" | sort | tail -1)
	echo "current last children = $CHILDREN"
	git checkout -b ${CURRENT_VERSION}.$((CHILDREN+1))
	git commit --allow-empty -m "Initial placeholder commit"
};

if [[ $1 == "--scratch" ]]; then
	new_from_scratch 
else
	new_from_current
fi
