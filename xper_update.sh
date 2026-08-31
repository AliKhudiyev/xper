#!/bin/bash
# usage: xper_update.sh FLAG_ACQUIRE FLAG_GLOBAL

ACQUIRE=$1
GLOBAL=$2

GIT_REPO=$(git remote -v)
USERNAME=$(xper_user.sh)
BRANCH=$(xper_version.sh 1)

if [[ $GIT_REPO == "" ]]; then
	echo "[xper_update.sh] no remote repository was found"
	exit 1
fi

OWNER=$(xper_owner.sh)
USER=$(xper_ctx.sh user)
MODE=$(xper_ctx.sh mode)
LOCKED=$(xper_ctx.sh locked)
TAG=$(xper_ctx.sh tag)

echo local user=$USERNAME
echo owner=$OWNER mode=$MODE locked=$LOCKED tag=$TAG

if [[ $GLOBAL -eq 1 ]]; then
	git pull --rebase --allow-unrelated-histories --all
	for branch in $(git branch -r | grep -v '\->'); do 
		git branch --track ${branch#origin/} $branch 2>/dev/null
	done
	git pull --rebase --allow-unrelated-histories --all
else
	git pull --rebase --allow-unrelated-histories origin $BRANCH
fi

if [[ $MODE == "normal" ]]; then
	if [[ $OWNER != $USERNAME ]]; then
		xper.sh finish
	else
		xper.sh modify
	fi
else # $MODE != "normal" or $MODE == "sequential"
	if [[ $ACQUIRE -eq 0 ]]; then
		xper.sh finish
		[[ $USER == $USERNAME ]] && xper.sh modify
	elif [[ $LOCKED -eq 0 ]]; then
		xper.sh modify
		xper_ctx.sh locked 1
		xper_ctx.sh user $USERNAME
		xper.backup
		failed=$?
		[[ $failed -ne 0 ]] && xper.sh finish
	else
		xper.sh finish
	fi
	# git add .xper && git commit -m "autolock by ${USERNAME}" && git push
fi
