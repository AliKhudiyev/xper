#!/usr/bin/env bash
# usage: xper_rootdir.sh

echo $(git rev-parse --show-toplevel)
# if [[ -d .git ]]; then
# 	echo $(git rev-parse --show-toplevel)
# else
# 	echo ""
# fi
