#!/bin/bash
# usage: xper_save.sh STR_MSG

MSG=$1
USERNAME=$(xper_user.sh)
ROOT_DIR=$(xper_rootdir.sh)

git add $ROOT_DIR && git commit --allow-empty -m "commit by $USERNAME $MSG"
