#!/usr/bin/env bash
# usage: xper_goto_rel.sh FLAG_GLOBAL FLAG_WRAP FLAG_FORWARD INT_STEPS STR_USER FLAG_FIRST FLAG_LAST

GLOBAL=$1
WRAP=$2
FORWARD=$3
STEPS=$4
USER=$5
FIRST=$6
LAST=$7

USERNAME=$(xper_user.sh)
CURRENT_VERSION=$(xper_version.sh 1)
PROJ_DIR=$(xper_rootdir.sh)
ROOT_DIR=$(xper_rootdir.sh)
INDEX_FP=$ROOT_DIR/.index

include=".+_v[0-9].*"
if [[ $USER == "" ]]; then
	USER=$USERNAME
fi
# if [[ $CURRENT_VERSION == $USERNAME ]]; then 
# 	include=".+"
# fi

if [[ ! -e $INDEX_FP ]]; then
	xper_sort.sh
# else
# 	echo index already exists
fi

versions=($(cat $INDEX_FP | grep -E "$include"))
# target_version=$CURRENT_VERSION
target_version=$(echo ${versions[@]: -1} | cut -d '|' -f 1)
# echo default target_version=$target_version

if [[ $GLOBAL -eq 0 ]]; then
	# versions=($(cat $INDEX_FP | grep -E "$USER.*"))
	versions=($(cat $INDEX_FP | grep -E "$include" | grep -E "$USER.*"))
	# uncomment line above (with $include) if you want stricter USERNAME matching
fi

# echo versions=${#versions[@]}
# echo ${versions[@]}
if [[ ${#versions[@]} -eq 0 ]]; then
	echo "[xper_goto] no other version exists"
	exit 0
fi

[[ $WRAP -eq 1 ]] && STEPS=$(($4 % ${#versions[@]}))
# echo $STEPS steps

# echo version count is ${#versions[@]}

get_version_number(){
	echo $1 | rev | cut -d '_' -f 1 | rev
}

if [[ $FIRST -eq 1 ]]; then
	if [[ $GLOBAL -eq 1 ]]; then
		target_version=$(cat $INDEX_FP | grep -E "$include" | head -1 | cut -d '|' -f 1)
	else
		target_version=$(cat $INDEX_FP | grep -E "$include" | grep -E "$USER*" | head -1 | cut -d '|' -f 1)
	fi
	# echo target_version=$target_version
elif [[ $LAST -eq 1 ]]; then
	if [[ $GLOBAL -eq 1 ]]; then
		target_version=$(cat $INDEX_FP | grep -E "$include" | tail -1 | cut -d '|' -f 1)
	else
		target_version=$(cat $INDEX_FP | grep -E "$include"| grep -E "$USER*" | tail -1 | cut -d '|' -f 1)
	fi
else
	for i in ${!versions[@]}; do
		version=$(echo ${versions[i]} | cut -d '|' -f 1)
		current=$CURRENT_VERSION
		# echo current=$current and version=${version}
		if [[ "${current}" == "${version}" || $((i+1)) -eq ${#versions[@]} ]]; then
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
fi

# echo target_version=$target_version

if [[ $target_version != $CURRENT_VERSION ]]; then
	xper_save.sh "before jump"
	user=$(echo $target_version | rev | cut -d '_' -f 2 | rev)
	version=$(get_version_number $target_version)
	xper.sh jump ${version} -u $user
else
	echo "[xper_goto] already on the right version"
fi
