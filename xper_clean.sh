#!/bin/bash

USERNAME=$(xper_user.sh)
ROOT_DIR=$(xper_rootdir.sh)

if [[ $USERNAME != "" && $ROOT_DIR != "" ]]; then
	rm -rf $ROOT_DIR/.git
	rm -rf $ROOT_DIR/.xper*
else
	echo "[xper_clean] directory is already clean"
fi
