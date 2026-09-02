#!/bin/bash
# usage: xper_sort STR_SORTBY FLAG_GLOBAL STR_USER FLAG_ONLYLEAF FLAG_YES

USERNAME=$(xper_user.sh)
CURRENT_VERSION=$(xper_version.sh 1)
ROOT_DIR=$(xper_rootdir.sh)

PROJ_DIR=$ROOT_DIR
HEADS_DIR=$ROOT_DIR/.heads
INDEX_FP=$ROOT_DIR/.index
PUSHLOCKED=$(xper_locked.sh)

SORTBY=$1
GLOBAL=$2
USER=$3; [[ $USER == "" ]] && USER=$USERNAME
ONLYLEAF=$4
YES=$5
RECURSIVE_SORT=0

if [[ $YES -eq 1 ]]; then
	chmod u+w $ROOT_DIR/.heads_filtered
	chmod u+w $ROOT_DIR/.index
elif [[ $PUSHLOCKED -eq 1 ]]; then
	chmod u-w $ROOT_DIR/.heads_filtered
	chmod u-w $ROOT_DIR/.index
	echo "[xper_sort] cannot alter index file without --yes flag"
	exit 0
fi

xper_save.sh "before sorting"

if [[ $GLOBAL -eq 1 ]]; then
	# echo global=1
	git branch --list --format='%(refname:short)' > ${HEADS_DIR}_filtered
else
	# echo global=0
	git branch --list "${USER}*" --format='%(refname:short)' > ${HEADS_DIR}_filtered
fi

versions_found=$(cat ${HEADS_DIR}_filtered | wc -l | tr -d ' ')
if [[ $versions_found -eq 0 ]]; then
	echo "[xper_sort] user $USER does not exist"
	exit 0
fi

# TODO: fix this part.
# 1) all SORTBY field values must be extracted from the log files for all versions in .git/refs/tmp file
# 2) .git/refs/tmp file must be sorted 
# 	2.1) -V option if the column values are versions (SORTBY="")
# 	2.2) -n option if the column values are numerics
# 	2.3) -t ',' -n option if the column values are multiple numerics

rm $INDEX_FP 2>/dev/null

if [[ $SORTBY == "" ]]; then
	for head in $(cat ${HEADS_DIR}_filtered); do
		version=$(xper_get_version.sh "$head")
		echo "$head|$version" >> $INDEX_FP
	done
	cat $INDEX_FP | sort -t '|' -k 2 -V -o $INDEX_FP
else
	for head in $(cat ${HEADS_DIR}_filtered); do
		version=$(xper_get_version.sh "$head")
		git checkout $head >/dev/null 2>&1
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
		echo "$head|$sortby" >> $INDEX_FP
	done

	if [[ $RECURSIVE_SORT -eq 1 ]]; then
		keys=""
		vals=($(cat $INDEX_FP | cut -d ',' -f 1-))

		for ((i=2; i<=${#vals[@]}; ++i)); do
			keys="$keys -k $i,$i"
		done

		cat $INDEX_FP | sed -E "s/\|/\|,/g" | sort -t ',' $keys -n -o $INDEX_FP
	else
		cat $INDEX_FP | sort -t '|' -k 2 -n -o $INDEX_FP
	fi
	git checkout $CURRENT_VERSION >/dev/null 2>&1
fi

if [[ $ONLYLEAF -eq 1 ]]; then
	lnum=1
	versions=$(cat $INDEX_FP | cut -d '|' -f 1)
	deleted=()
	for version in $versions; do
		children=$(git branch --list "${version}.*" | grep -vE "${version}\..*\..*")
		# echo "version=$version : children=$children"
		if [[ $children != "" ]]; then
			deleted+="${lnum}d;"
		fi
		lnum=$((lnum+1))
	done

	# echo deleted=$deleted
	if [[ $deleted != "" ]]; then
		sed "${deleted}" $INDEX_FP > $INDEX_FP.tmp && mv $INDEX_FP.tmp $INDEX_FP
	fi
fi
