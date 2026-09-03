#!/usr/bin/env bash
# usage: xper_finish.sh FLAG_YES

YES=$1

OWNER=$(xper_owner.sh)
USERNAME=$(xper_user.sh)
ROOT_DIR=$(xper_rootdir.sh)
XPER_FP=$ROOT_DIR/.xper

if [[ $OWNER == $USERNAME || $YES -eq 1 ]]; then
	xper_ctx.sh finished 1 1
	find $ROOT_DIR -path "$ROOT_DIR/.git" -prune -o -type d -exec chmod a-w {} +
	find $ROOT_DIR -path "$ROOT_DIR/.git" -prune -o -type f -exec chmod a-w {} +
else
	echo "[xper_finish] you [$USERNAME] are not the owner [$OWNER] of this version"
fi
