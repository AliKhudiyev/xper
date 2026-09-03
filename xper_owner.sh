#!/usr/bin/env bash

CURRENT_VERSION=$(git branch --show-current)
echo $CURRENT_VERSION | rev | cut -d '_' -f 2- | rev
