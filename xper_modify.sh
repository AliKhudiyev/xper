#!/bin/bash

PROJ_ROOT=$(git rev-parse --show-toplevel)

find $PROJ_ROOT -type d -exec chmod u+w {} +
find $PROJ_ROOT -type f -exec chmod u+w {} +
