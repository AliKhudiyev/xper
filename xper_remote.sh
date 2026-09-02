#!/bin/bash
# usage: xper_remote.sh FLAG_ADD STR_URL

YES=$1
URL=$2

if [[ $YES -eq 1 ]]; then
	git remote add origin $URL
else
	echo "$(git remote -v)"
fi
