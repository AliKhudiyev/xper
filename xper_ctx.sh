#!/bin/bash
# usage: xper_ctx.sh STR_FIELD opt:STR_VALUE opt:FLAG_YES

FIELD=$1
VALUE=$2
YES=$3

ROOT_DIR=$(xper_rootdir.sh)
XPER_FP=$ROOT_DIR/.xper
FINISHED=$(grep '^finished=' $XPER_FP | cut -d '=' -f 2-)
PUSHLOCKED=$(xper_locked.sh)

if [[ $# -ge 2 ]]; then
	if [[ $YES -eq 1 ]]; then
		find $ROOT_DIR -type d -exec chmod u+w {} +
		find $ROOT_DIR -type f -exec chmod u+w {} +
	fi

	sed -E "s/$FIELD=(.*)/$FIELD=$VALUE/g" $XPER_FP > $XPER_FP.tmp && mv $XPER_FP.tmp $XPER_FP

	if [[ $PUSHLOCKED -eq 1 ]]; then
		find $ROOT_DIR -path "$ROOT_DIR/.git" -prune -o -type d -exec chmod a-w {} +
		find $ROOT_DIR -path "$ROOT_DIR/.git" -prune -o -type f -exec chmod a-w {} +
	fi
else
	if [[ $FIELD == "" ]]; then
		cat $XPER_FP
	else
		cat $XPER_FP | grep "$FIELD" | sed -E "s/$FIELD=(.*)/\1/g"
	fi
fi
