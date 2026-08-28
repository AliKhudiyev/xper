#!/bin/bash
# usage: xper_version_count.sh

echo $(git branch --list | wc -l | tr -d ' ')
