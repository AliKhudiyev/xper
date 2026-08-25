#!/bin/bash

USERNAME=$(git config --global user.name | tr -d ' ')
BASE=${USERNAME}
NODE=$(git branch --show-current)

git branch --list "${NODE}.*" | grep -vE "${NODE}\..*\..*"
