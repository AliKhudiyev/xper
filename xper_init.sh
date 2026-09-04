#!/usr/bin/env bash
# usage: xper_init.sh FLAG_YES

YES=$1
echo yes=$YES

USERNAME=$(git config --local user.name | tr -d ' ')
if [[ $USERNAME == "" ]]; then
	echo "[xper_init] git username not found"
	USERNAME=$(git config --global user.name | tr -d ' ')
	yes='y'
	if [[ $USERNAME != "" ]]; then
		if [[ $YES -ne 1 ]]; then
			read -n 1 -p "[xper_init] would you want to go with username [$USERNAME] ? [y/n] " yes
			echo
		fi
		if [[ $yes == "n" || $yes == "N" ]]; then
			echo "[xper_init] ok. pls configure local git user to use xper"
			exit 0
		fi
	else
		exit 1
	fi
fi

if [[ -d .git ]]; then
	rm -rf .git
fi
git init -b $USERNAME > /dev/null 2>&1
echo "[xper_init] initalized with username [$USERNAME]"

printf "user=${USERNAME}\nmode=normal\nlocked=0\ntag=\nlog=\n" > .xper
printf "owner=${USERNAME}\nreference=\nfinished=0\n" >> .xper
printf "created=$(date +'%Y-%m-%d_%H:%M:%S_%z')\n" >> .xper
printf ".heads\n.heads_filtered\n.index\n" >> .gitignore

xper_save.sh "[as initial placeholder commit]" 1
