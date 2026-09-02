#!/bin/bash
# usage: xper_modify.sh FLAG_YES

YES=$1

OWNER=$(xper_owner.sh)
USERNAME=$(xper_user.sh)
ROOT_DIR=$(xper_rootdir.sh)

if [[ $OWNER == $USERNAME || $YES -eq 1 ]]; then
	find $ROOT_DIR -type d -exec chmod u+w {} + 
	find $ROOT_DIR -type f -exec chmod u+w {} +
	xper_ctx.sh finished 0 1
else
	echo "[xper_modify] you [$USERNAME] are not the owner [$OWNER] of this version"
fi
