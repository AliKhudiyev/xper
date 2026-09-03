#!/usr/bin/env bash
# usage: xper_user.sh

if [[ ! -d .git ]]; then
	echo ""
	exit 0
fi

USERNAME="$(git config --local user.name)"
if [[ ${#USERNAME} -eq 0 ]]; then
	USERNAME="$(git config --global user.name 2>/dev/null)"
fi
USERNAME=$(echo "${USERNAME}" | tr -d ' ')

echo "${USERNAME}"
