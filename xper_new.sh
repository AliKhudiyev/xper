#!/bin/bash
# usage: xper_init FLAG_SCRATCH STR_TAG FLAG_YES

SCRATCH=$1
TAG=$2
YES=$3

USERNAME="$(git config --local user.name)"
CURRENT_VERSION="$(git branch --show-current)"
PARENT_VERSION=$(xper.sh parent)
PROJ_DIR=$(git rev-parse --show-toplevel)

if [[ ${#USERNAME} -eq 0 ]]; then
	USERNAME="$(git config --global user.name 2>/dev/null)"
fi
USERNAME=$(echo $USERNAME | tr -d ' ')
BASE=${USERNAME}

echo "scratch=$SCRATCH tag=$TAG yes=$YES"
echo "username is $USERNAME"
echo "current version is $CURRENT_VERSION"
echo "parent version is $PARENT_VERSION"

new_from_scratch(){
	git checkout $BASE
	CHILDREN=$(git branch --list "*v*" | grep -vE ".+v[0-9]+\..*" | sed -E "s/.+_v([0-9]+)/\1/g" | sort -n | tail -1)
	echo "${BASE}'s last children = $CHILDREN"
	git checkout -b ${BASE}_v$((CHILDREN+1))
	git commit --allow-empty -m "Initial placeholder commit"
	xper.sh sort
};

new_from_current(){
	CHILDREN=$(git branch --list "$CURRENT_VERSION.*" | grep -vE "$CURRENT_VERSION\..*\..*" | sed -E "s/${CURRENT_VERSION}\.([0-9]+)/\1/g" | sort -n | tail -1)
	echo "current last children = $CHILDREN"
	git checkout -b ${CURRENT_VERSION}.$((CHILDREN+1))
	git commit --allow-empty -m "Initial placeholder commit"
	xper.sh sort
};

git add $PROJ_DIR && git commit -m "commit by $USERNAME before branching"
diff=$(git diff $CURRENT_VERSION $PARENT_VERSION)
# echo diff=$diff

if [[ $SCRATCH -eq 1 || $PARENT_VERSION == "" ]]; then
	new_from_scratch
	if [[ $OSTYPE == "darwin"* ]]; then
		sed -i "" "s/tag=.*/tag=$TAG/g" .xper
	else
		sed -i "s/tag=.*/tag=$TAG/g" .xper
	fi
elif [[ $diff != "" || $YES -eq 1 ]]; then
	new_from_current
	if [[ $OSTYPE == "darwin"* ]]; then
		sed -i "" "s/tag=.*/tag=$TAG/g" .xper
	else
		sed -i "s/tag=.*/tag=$TAG/g" .xper
	fi
else
	echo "[xper_new] did not create a new version"
fi
