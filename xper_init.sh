#!/bin/bash

USERNAME=$(git config --global user.name | tr -d ' ')

git init -b main && git commit --allow-empty -m "Initial placeholder commit"
git checkout -b $USERNAME && git commit --allow-empty -m "Initial placeholder commit"
