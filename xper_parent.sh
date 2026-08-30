#!/bin/bash

CURRENT_VERSION=$(xper_version.sh 1)
USERNAME=$(xper_user.sh)

if [[ $CURRENT_VERSION == $USERNAME || $CURRENT_VERSION == "main" ]]; then
	exit 0
fi

version_nums=($(echo $CURRENT_VERSION | tr '.' ' '))
delimiter='.'

if [[ ${#version_nums[@]} -eq 1 ]]; then delimiter='_'; fi
parent=$(echo $CURRENT_VERSION | rev | cut -d $delimiter -f 2- | rev)
echo $parent
