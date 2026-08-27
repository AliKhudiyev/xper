#!/bin/bash
# usage: xper_sort STR_SORTBY FLAG_GLOBAL STR_USER

USERNAME=$(git config --global user.name | tr -d ' ')
CURRENT_VERSION=$(git branch --show-current)
PROJ_DIR=$(git rev-parse --show-toplevel)

SORTBY=$1
GLOBAL=$2
USER=$3
RECURSIVE_SORT=0

git add $PROJ_DIR && git commit -m "commit by $USERNAME before sorting"

if [[ $USER == "" ]]; then
	USER=$CURRENT_USER
fi

if [[ $GLOBAL -eq 1 ]]; then
	echo global=1
	ls .git/refs/heads > .git/refs/heads_filtered
else
	echo global=0
	(ls .git/refs/heads | grep -E "${USER}.*") > .git/refs/heads_filtered
fi

# TODO: fix this part.
# 1) all SORTBY field values must be extracted from the log files for all versions in .git/refs/tmp file
# 2) .git/refs/tmp file must be sorted 
# 	2.1) -V option if the column values are versions (SORTBY="")
# 	2.2) -n option if the column values are numerics
# 	2.3) -t ',' -n option if the column values are multiple numerics

rm .git/refs/index 2>/dev/null

if [[ $SORTBY == "" ]]; then
	for head in $(cat .git/refs/heads_filtered); do
		version=$(xper_get_version.sh "$head")
		echo "$head|$version" >> .git/refs/index
	done
	cat .git/refs/index | sort -t '|' -k 2 -V -o .git/refs/index
else
	for head in $(cat .git/refs/heads_filtered); do
		version=$(xper_get_version.sh "$head")
		git checkout $head
		logfp=$(xper.sh logfile)
		# echo logfp=$logfp
		if [[ -f $logfp ]]; then
			sortby=$(cat $logfp | grep "$SORTBY:*" | cut -d ':' -f 2 || echo null)
			if [[ $sortby == *","* ]]; then
				RECURSIVE_SORT=1
			fi
			# echo parsing $SORTBY field... $sortby
		else
			sortby="null"
		fi
		echo "$head|$sortby" >> .git/refs/index
	done

	if [[ $RECURSIVE_SORT -eq 1 ]]; then
		keys=""
		vals=($(cat .git/refs/index | cut -d ',' -f 1-))

		for ((i=2; i<=${#vals[@]}; ++i)); do
			keys="$keys -k $i,$i"
		done

		cat .git/refs/index | sed -E "s/\|/\|,/g" | sort -t ',' $keys -n -o .git/refs/index
	else
		cat .git/refs/index | sort -t '|' -k 2 -n -o .git/refs/index
	fi
fi

# rm .git/refs/heads_filtered
