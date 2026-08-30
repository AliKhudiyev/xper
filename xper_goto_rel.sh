#!/bin/bash
# usage: xper_goto_rel.sh FLAG_GLOBAL FLAG_WRAP FLAG_FORWARD INT_STEPS STR_USER

GLOBAL=$1
WRAP=$2
FORWARD=$3
USER=$5

USERNAME=$(xper_user.sh)
CURRENT_VERSION=$(xper_version.sh 1)
PROJ_DIR=$(xper_rootdir.sh)

include=".+_v[0-9].*"
if [[ $USER == "" ]]; then
	USER=$USERNAME
fi
# if [[ $CURRENT_VERSION == $USERNAME ]]; then 
# 	include=".+"
# fi

# versions=($(ls .git/refs/heads | grep -v "main" | grep -E $include | sort))
if [[ ! -e ".git/refs/index" ]]; then
	xper_sort.sh
else
	echo index already exists
fi

versions=($(cat .git/refs/index))
target_version=$CURRENT_VERSION

if [[ $GLOBAL -eq 0 ]]; then
	versions=($(cat .git/refs/index | grep -E $include | grep -E "$USER.*"))
fi

echo versions=${#versions[@]}
if [[ ${#versions[@]} -eq 0 ]]; then
	echo "[xper_goto] no other version exists"
	exit 0
fi

STEPS=$(($4 % ${#versions[@]}))
echo $STEPS steps

echo version count is ${#versions[@]}

for i in ${!versions[@]}; do
	version=$(echo ${versions[i]} | cut -d '|' -f 1)
	echo $CURRENT_VERSION vs ${version}
	if [[ "${CURRENT_VERSION}" == "${version}" ]]; then
		ti=$(($i+$STEPS))
		if [[ $FORWARD -eq 0 ]]; then
			ti=$(($i-$STEPS))
			if [[ $ti -lt 0 ]]; then
				if [[ $WRAP -eq 1 ]]; then
					ti=$(($ti+${#versions[@]}))
				else
					ti=0
				fi
			fi
		fi

		if [[ $ti -ge ${#versions[@]} ]]; then
			if [[ $WRAP -eq 1 ]]; then
				ti=$(($ti-${#versions[@]}))
			else
				ti=$((${#versions[@]}-1))
			fi
		fi
		target_version=$(echo ${versions[ti]} | cut -d '|' -f 1)
		break
	fi
done

echo target_version=$target_version

if [[ $target_version != $CURRENT_VERSION ]]; then
	git add $PROJ_DIR && git commit -m "commit by $USERNAME before jump"
	git checkout ${target_version}
else
	echo "[xper_goto] already on the right version"
fi
