#!/bin/bash
# usage: xper_init FLAG_SCRATCH STR_TAG FLAG_YES

SCRATCH=$1
TAG=$2
YES=$3

USERNAME=$(xper_user.sh)
CURRENT_VERSION=$(xper_version.sh 1)
PARENT_VERSION=$(xper.sh parent)
PROJ_DIR=$(xper_rootdir.sh)

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
	git commit --allow-empty -m "[as initial placeholder commit]"
	xper.sh sort
};

xper_save.sh "before branching"
diff=$(xper_diff.sh $PARENT_VERSION)
# echo diff=$diff

if [[ $SCRATCH -eq 1 || $PARENT_VERSION == "" ]]; then
	new_from_scratch
	sed "s/tag=.*/tag=$TAG/g" .xper > .xper.tmp && mv .xper.tmp .xper
elif [[ $diff != "" || $YES -eq 1 ]]; then
	new_from_current
	sed "s/tag=.*/tag=$TAG/g" .xper > .xper.tmp && mv .xper.tmp .xper
else
	echo "[xper_new] did not create a new version"
fi
