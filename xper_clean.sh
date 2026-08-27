#!/bin/bash

USERNAME=$(git config --global user.name | tr -d ' ')
PROJ_DIR=$(git rev-parse --show-toplevel)

rm -rf .git
rm -rf .xper*
