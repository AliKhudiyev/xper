#!/bin/bash

ROOT_DIR=$(xper_rootdir.sh)

find $ROOT_DIR -path "$ROOT_DIR/.git" -prune -o -type d -exec chmod a-w {} +
find $ROOT_DIR -path "$ROOT_DIR/.git" -prune -o -type f -exec chmod a-w {} +
