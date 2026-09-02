#!/bin/bash
# usage: xper_save.sh STR_MSG FLAG_YES

MSG=$1
YES=$2

USERNAME=$(xper_user.sh)
ROOT_DIR=$(xper_rootdir.sh)
COMMIT_MSG="commit by $USERNAME $MSG"

git add $ROOT_DIR > /dev/null 2>&1
git_status=$(git status -s)
if [[ "$git_status" == "" && $YES -ne 1 ]]; then
	# echo "[xper_save.sh]: already saved"
	exit 0
fi

failed=0
if [[ $YES -eq 1 ]]; then
	git commit --allow-empty -m "$COMMIT_MSG" > /dev/null 2>&1
	failed=$?
else
	git commit -m "$COMMIT_MSG" > /dev/null 2>&1
	failed=$?
fi

if [[ $failed -eq 0 ]]; then
	echo "[xper_save] saved successfully"
else
	exit 1
fi
