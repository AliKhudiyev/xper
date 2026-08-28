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
	if grep -qE ".+_v[0-9]+(\.[0-9]+)*" <<< "$BRANCH"; then
		echo $BRANCH | rev | cut -d 'v' -f 1 | rev
	else
		echo 0
	fi
fi
