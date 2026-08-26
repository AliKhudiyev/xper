#!/bin/bash

CURRENT_VERSION=$(git branch --show-current)

git diff $CURRENT_VERSION $1
