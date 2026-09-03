#!/usr/bin/env bash
# usage: xper_track.sh STR_FILEPATH

FILEPATH=$1
ROOT_DIR=$(xper_rootdir.sh)

sed -E "/$FILEPATH/d" $ROOT_DIR/.gitignore > $ROOT_DIR/.gitignore.tmp && mv $ROOT_DIR/.gitignore.tmp $ROOT_DIR/.gitignore
echo "[xper_untrack] $FILEPATH untracked"
