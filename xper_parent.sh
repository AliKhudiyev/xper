#!/bin/bash

CURRENT_VERSION=$(git branch --show-current)
USERNAME=$(echo $CURRENT_VERSION | sed -E "s/(.+)_v.+/\1/g")

if [[ $CURRENT_VERSION == $USERNAME || $CURRENT_VERSION == "main" ]]; then
	exit 0
fi

version_nums=($(echo $CURRENT_VERSION | tr '.' ' '))
delimiter='_'

if [[ ${#version_nums[@]} -eq 1 ]]; then delimiter='_'; fi
parent=$(echo $CURRENT_VERSION | rev | cut -d $delimiter -f 2- | rev)

