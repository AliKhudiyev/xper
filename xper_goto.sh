#!/bin/bash

USERNAME=$(git config --global user.name | tr -d ' ')
TARGET_NODE="${USERNAME}_$1"

git checkout ${TARGET_NODE}
