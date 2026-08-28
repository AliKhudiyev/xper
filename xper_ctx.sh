#!/bin/bash
# usage: xper_ctx.sh STR_FIELD

FIELD=$1
ROOT_DIR=$(xper_rootdir.sh)

if [[ $FIELD == "" ]]; then
	cat $ROOT_DIR/.xper
else
	cat $ROOT_DIR/.xper | grep "$FIELD" | sed -E "s/$FIELD=(.*)/\1/g"
fi
