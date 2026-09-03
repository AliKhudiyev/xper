#!/usr/bin/env bash

ROOT_DIR=$(xper_rootdir.sh)

[[ -w $ROOT_DIR ]] && echo 0 || echo 1
