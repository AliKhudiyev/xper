#!/usr/bin/env bash

CURRENT_VERSION=$(xper_version.sh 1)

git diff $CURRENT_VERSION $1 -- . ':!.xper'
