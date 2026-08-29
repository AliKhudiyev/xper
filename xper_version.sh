#!/bin/bash
# usage: xper_version.sh FLAG_FULL

if [[ ! -d .git ]]; then
	echo ""
	exit 0
fi

FULL=$1
BRANCH=$(git branch --show-current)

if [[ $FULL -eq 1 ]]; then
	echo $BRANCH
else
	version=$(echo $BRANCH | rev | cut -d 'v' -f 1 -s | rev)
	if [[ $version == "" ]]; then
		version=0
	fi
	echo $version
fi
