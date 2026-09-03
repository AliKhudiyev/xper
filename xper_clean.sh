#!/usr/bin/env bash

USERNAME=$(xper_user.sh)
ROOT_DIR=$(xper_rootdir.sh)

if [[ $USERNAME != "" && $ROOT_DIR != "" ]]; then
	rm -rf $ROOT_DIR/.git 2>/dev/null
	rm -rf $ROOT_DIR/.xper* 2>/dev/null
	rm .index .heads .heads_filtered 2>/dev/null
else
	echo "[xper_clean] directory is already clean"
fi
