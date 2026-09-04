#!/usr/bin/env bash
# usage: xper_run.sh STR_COMMAND STR_VERSIONS FLAG_GLOBAL STR_USER INT_WORKERS
# STR_VERSIONS format:
#     vX    - only vX
#     vX*   - vXY for all Y
#     vX**  - vXY..Z for all Y..Z

COMMAND=$1
VERSIONS=$2
GLOBAL=$3
USER=$4
WORKERS=$5

USERNAME=$(xper_user.sh)
VERSION=$(xper_version.sh 1)
ROOT_DIR=$(xper_rootdir.sh)

# echo global=$GLOBAL VERSIONS=$VERSIONS user=$USER
if [[ $USER == "" && $GLOBAL -ne 1 ]]; then
	USER=$USERNAME
elif [[ $GLOBAL -eq 1 ]]; then
	USER="*"
fi

base_version=$(echo $VERSIONS | cut -d '*' -f 1)
# echo base_version=$base_version
versions=($base_version)

if [[ ${VERSIONS[@]: -1:1} == "*" ]]; then
	if [[ ${VERSIONS[@]: -2:1} == "*" ]]; then
		# echo all levels
		versions=$(git branch --list "${USER}_v$base_version*" --format="%(refname:short)")
	else
		# echo only 1-level
		versions=$(git branch --list "${USER}_v$base_version*" --format="%(refname:short)" | grep -vE ".+_v$base_version\..+\..+")
	fi
fi

# echo versions=${versions[@]}
for version in ${versions[@]}; do
	version_number=$(echo $version | rev | cut -d '_' -f 1 | rev)
	version_owner=$(echo $version | rev | cut -d '_' -f 2- | rev)
	xper.sh jump $version_number -u $version_owner
	PUSHLOCKED=$(xper_locked.sh)
	if [[ $PUSHLOCKED -eq 0 ]]; then
		echo "[xper_run] running your command in $version"
		eval "$COMMAND"
	else
		echo "[xper_run] cannot run in $version"
	fi
done

version_number=$(echo $VERSION | rev | cut -d '_' -f 1 | rev)
version_owner=$(echo $VERSION | rev | cut -d '_' -f 2- | rev)
xper.sh jump $version_number -u $version_owner
