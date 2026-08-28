#!/bin/bash

xper.sh update
failed=$?

if [[ $failed -ne 0 ]]; then
	echo "[xper_backup.sh] failed"
	exit $failed
fi

GIT_REPO=$(git remote -v)
USERNAME=$(git config --global user.name | tr -d ' ')
PROJ_DIR=$(git rev-parse --show-toplevel)

if [[ $GIT_REPO == "" ]]; then
	echo "no remote repository was found"
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

xper.sh new
git add $PROJ_DIR && git commit -m "commit by $USERNAME" && git push
failed=$?

if [[ $failed -ne 0 ]]; then
	echo failed
fi
