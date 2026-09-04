#!/usr/bin/env bash
# usage: xper_get_children.sh STR_VERSION FLAG_RECURSE

VERSION=$1
RECURSE=$2

if [[ $RECURSE -eq 1 ]]; then
	git branch --list "$VERSION*" --format="%(refname:short)" | xargs echo
else
	git branch --list "$VERSION*" --format="%(refname:short)" | grep -vE "$VERSION\..+\..+" | xargs echo
fi
