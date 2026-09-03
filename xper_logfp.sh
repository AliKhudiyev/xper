#!/usr/bin/env bash
# usage: xper_logfp.sh FLAG_SETLOGFP STR_LOGFP

if [[ ! -f .xper ]]; then
	echo "[xper_logfp] .xper file doesn't exist"
	exit 1
fi

SETLOGFP=$1
LOGFP=$2

if [[ $SETLOGFP -eq 1 ]]; then
	sed "s/log=.*/log=$LOGFP/g" .xper > .xper.tmp && mv .xper.tmp .xper
fi

cat .xper | grep "log" | cut -d '=' -f 2
