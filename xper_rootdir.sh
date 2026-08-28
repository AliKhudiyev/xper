#!/bin/bash
# usage: xper_rootdir.sh

if [[ -d .git ]]; then
	echo $(git rev-parse --show-toplevel)
else
	echo ""
fi
