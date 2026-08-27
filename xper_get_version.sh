#!/bin/bash
# usage: xper_get_version.sh STR_BRANCH

BRANCH=$1
VERSION=$(echo $BRANCH | rev | cut -d 'v' -f 1 | rev)

echo $VERSION
