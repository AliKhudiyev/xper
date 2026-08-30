#!/bin/bash
# usage: xper_ctx.sh STR_FIELD opt:STR_VALUE

FIELD=$1
VALUE=$2
ROOT_DIR=$(xper_rootdir.sh)
XPER_FP=$ROOT_DIR/.xper

if [[ $# -ge 2 ]]; then
	sed -E "s/$FIELD=(.*)/$FIELD=$VALUE/g" $XPER_FP > $XPER_FP.tmp && mv $XPER_FP.tmp $XPER_FP
else
	if [[ $FIELD == "" ]]; then
		cat $XPER_FP
	else
		cat $XPER_FP | grep "$FIELD" | sed -E "s/$FIELD=(.*)/\1/g"
	fi
fi
