#!/usr/bin/env bash
# usage: xper_update.sh FLAG_GLOBAL

GLOBAL=$1

GIT_REPO=$(git remote -v)
USERNAME=$(xper_user.sh)
BRANCH=$(xper_version.sh 1)
PUSHLOCKED=$(xper_locked.sh)

if [[ $GIT_REPO == "" ]]; then
	echo "[xper_update.sh] no remote repository was found"
	exit 1
fi

OWNER=$(xper_owner.sh)
USER=$(xper_ctx.sh user)
MODE=$(xper_ctx.sh mode)
LOCKED=$(xper_ctx.sh locked)
TAG=$(xper_ctx.sh tag)

# echo local user=$USERNAME
# echo owner=$OWNER mode=$MODE locked=$LOCKED tag=$TAG

xper_save.sh "before update"
if [[ $GLOBAL -eq 1 ]]; then
	git pull --rebase --allow-unrelated-histories --all > /dev/null 2>&1
	for branch in $(git branch -r | grep -v '\->'); do 
		git branch --track ${branch#origin/} $branch > /dev/null 2>&1
	done
	git pull --rebase --allow-unrelated-histories --all > /dev/null 2>&1
elif git branch -r | grep -v "\->" | cut -d '/' -f 2 | grep -w "$BRANCH" -q ; then
	git pull --rebase --allow-unrelated-histories origin $BRANCH > /dev/null 2>&1
fi

if [[ $MODE == "normal" ]]; then
	if [[ $OWNER != $USERNAME ]]; then
		xper.sh finish --yes
	else
		xper.sh modify --yes
	fi
elif [[ $PUSHLOCKED -eq 1 || $USER != $USERNAME ]]; then
	# $MODE == "sequential"
	xper.sh finish --yes
else
	xper.sh modify --yes
fi
