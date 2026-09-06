#!/usr/bin/env bash
# usage: xper_gitify.sh

USERNAME=$(xper_user.sh)
ROOT_DIR=$(xper_rootdir.sh)
GIT_DIR=$ROOT_DIR/.git
XPER_FP=$ROOT_DIR/.xper

if [[ ! -d $GIT_DIR || ! -f $XPER_FP ]]; then
	echo "[xper_gitify] not an xper project"
	exit 1
fi

echo "[xper_gitify] this directory is git-compatible already"
read -p "(this step cannot be undone) do you want to permenantly remove xper compatibility ? [y/n] " ans

if [[ $ans == 'y' || $ans == 'Y' ]]; then
	rm -rf $ROOT_DIR/.xper* 2>/dev/null
	rm $ROOT_DIR/{.index,.heads,.heads_filtered} 2>/dev/null
	echo "[xper_gitify] removed xper compatibility permanently"
else
	echo "[xper_gitify] xper compatibility remains"
fi
