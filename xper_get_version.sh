#!/usr/bin/env bash
# usage: xper_get_version.sh STR_BRANCH

FULL=0
BRANCH=$1

if [[ $FULL -eq 1 ]]; then
	echo $BRANCH
else
	if grep -qE ".+_v[0-9]+(\.[0-9]+)*" <<< "$BRANCH"; then
		echo $BRANCH | rev | cut -d 'v' -f 1 | rev
	else
		echo 0
	fi
fi
