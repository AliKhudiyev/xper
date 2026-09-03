#!/usr/bin/env bash
# usage: xper_track.sh STR_FILEPATH

FILEPATH=$1
ROOT_DIR=$(xper_rootdir.sh)

echo $FILEPATH >> $ROOT_DIR/.gitignore
echo "[xper_track] $FILEPATH tracked"
