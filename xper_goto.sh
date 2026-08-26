#!/bin/bash

USERNAME=$(git config --global user.name | tr -d ' ')
TARGET_NODE="${USERNAME}_$1"
PROJ_DIR=$(git rev-parse --show-toplevel)

git $PROJ_DIR/** && git commit -m "before jump by $USERNAME"
git checkout ${TARGET_NODE}
