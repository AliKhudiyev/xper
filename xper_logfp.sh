#!/bin/bash
# usage: xper_logfp.sh FLAG_SETLOGFP STR_LOGFP

SETLOGFP=$1
LOGFP=$2

if [[ $SETLOGFP -eq 1 ]]; then
	if [[ $OSTYPE == "darwin"* ]]; then
		sed -i "" "s/log=.*/log=$LOGFP/g" .xper
	else
		sed -i "s/log=.*/log=$LOGFP/g" .xper
	fi
fi

cat .xper | grep "log" | cut -d '=' -f 2
