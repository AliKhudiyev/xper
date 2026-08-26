#!/bin/bash

GIT_REPO=$(git remote -v)
USERNAME=$(git config --global user.name | tr -d ' ')

if [[ $GIT_REPO == "" ]]; then
	echo "[xper_update.sh] no remote repository was found"
	exit 1
fi

USER=""
MODE="normal"
LOCKED=0
TAG=""

cat .xper | while IFS= read -r line; do
	if [[ $line == "user=*" ]]; then
		USER=$(echo $line | cut -d '=' -f2)
	elif [[ $line == "mode=*" ]]; then
		MODE=$(echo $line | cut -d '=' -f2)
	elif [[ $line == "locked=*" ]]; then
		LOCKED=$(echo $line | cut -d '=' -f2)
	elif [[ $line == "tag=*" ]]; then
		TAG=$(echo $line | cut -d '=' -f2)
	fi
done

echo user=$USER mode=$MODE locked=$LOCKED tag=$TAG

git pull

if [[ $USER != $USERNAME && $MODE != "normal" && $LOCKED -eq 1 ]]; then
	git reset --hard ORIG_HEAD
elif [[ $MODE != "normal" ]]; then
	locked=1
	if [[ $USER == $USERNAME ]]; then locked=$LOCKED; fi
	printf "user=${USERNAME}\nmode=${MODE}\nlocked=${locked}\ntag=${TAG}\n" > .xper
	git add .xper && git commit -m "autolock by ${USERNAME}" && git push
fi
