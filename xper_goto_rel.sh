#!/bin/bash
# usage: xper_goto_rel.sh FLAG_GLOBAL FLAG_WRAP FLAG_FORWARD INT_STEPS STR_USER

GLOBAL=$1
WRAP=$2
FORWARD=$3
USER=$5

USERNAME=$(git config --global user.name | tr -d ' ')
CURRENT_VERSION=$(git branch --show-current)
PROJ_DIR=$(git rev-parse --show-toplevel)

include=".+_v[0-9].*"
if [[ $CURRENT_VERSION == $USERNAME ]]; then include=".+"; fi

versions=($(ls .git/refs/heads | grep -v "main" | grep -E $include | sort))
target_version=$CURRENT_VERSION

if [[ $GLOBAL -eq 0 ]]; then
	versions=($(ls .git/refs/heads | grep -v "main" | grep -E $include | grep "$USER" | sort))
fi

STEPS=$(($4 % ${#versions[@]}))
echo $STEPS steps

echo version count is ${#versions[@]}

for i in ${!versions[@]}; do
	echo $CURRENT_VERSION vs ${versions[i]}
	if [[ $CURRENT_VERSION == ${versions[i]} ]]; then
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
		target_version=${versions[$ti]}
		break
	fi
done

echo target_version=$target_version

if [[ $target_version != $CURRENT_VERSION ]]; then
	git add $PROJ_DIR/** && git commit -m "before jump by $USERNAME"
	git checkout ${target_version}
fi
