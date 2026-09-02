#!/bin/bash

USERNAME=$(git config --global user.name | tr -d ' ')

git init -b $USERNAME > /dev/null 2>&1

printf "user=${USERNAME}\nmode=normal\nlocked=0\ntag=\nlog=\n" > .xper
printf "owner=${USERNAME}\nreference=\nfinished=0\n" >> .xper
printf ".heads\n.heads_filtered\n.index\n" >> .gitignore

xper_save.sh "[as initial placeholder commit]" 1
