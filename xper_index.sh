#!/bin/bash
# usage: xper_index.sh FLAG_CLEAR FLAG_ADD FLAG_REMOVE STR_VERSION_SOURCE FLAG_AFTER FLAG_BEFORE FLAG_SWAP STR_VERSION_TARGET

CLEAR=$1
ADD=$2
REMOVE=$3
VERSION_SOURCE=$(xper_version.sh 1); [[ $4 != "" ]] && VERSION_SOURCE=$4
AFTER=$5
BEFORE=$6
SWAP=$7
VERSION_TARGET=$8

echo version_source=$VERSION_SOURCE version_target=$VERSION_TARGET

ROOT_DIR=$(xper_rootdir.sh)
INDEX_FP="${ROOT_DIR}/.git/refs/index"

if [[ $CLEAR -eq 1 ]]; then
	echo "" > $INDEX_FP
	echo "[xper_index]: cleared the index file"
elif [[ $ADD -eq 1 ]]; then
	if grep -E "${VERSION_SOURCE}\|.*" $INDEX_FP -q; then
		echo "[xper_index] already exists"
	else
		echo "${VERSION_SOURCE}|" >> $INDEX_FP
	fi
elif [[ $REMOVE -eq 1 ]]; then
	echo "removing [$VERSION_SOURCE]"
	sed -E "/${VERSION_SOURCE}\|.*/d" $INDEX_FP > $INDEX_FP.tmp && mv $INDEX_FP.tmp $INDEX_FP
elif [[ $AFTER -eq 1 ]]; then
	src=$(grep -E "${VERSION_SOURCE}\|.*" $INDEX_FP)
	trg=$(grep -E "${VERSION_TARGET}\|.*" $INDEX_FP)
	lsrc=$(grep -nE "${VERSION_SOURCE}\|.*" $INDEX_FP | cut -d ':' -f 1)
	ltrg=$(grep -nE "${VERSION_TARGET}\|.*" $INDEX_FP | cut -d ':' -f 1)

	xper.sh index --remove $VERSION_SOURCE

	if [[ $ltrg != "" ]]; then
		sed "${ltrg}a\\
${VERSION_SOURCE}|
" $INDEX_FP > $INDEX_FP.tmp && mv $INDEX_FP.tmp $INDEX_FP
	fi
elif [[ $BEFORE -eq 1 ]]; then
	src=$(grep -E "${VERSION_SOURCE}\|.*" $INDEX_FP)
	trg=$(grep -E "${VERSION_TARGET}\|.*" $INDEX_FP)
	lsrc=$(grep -nE "${VERSION_SOURCE}\|.*" $INDEX_FP | cut -d ':' -f 1)
	ltrg=$(grep -nE "${VERSION_TARGET}\|.*" $INDEX_FP | cut -d ':' -f 1)

	xper.sh index --remove $VERSION_SOURCE

	if [[ $ltrg != "" ]]; then
		sed "${ltrg}i\\
${VERSION_SOURCE}|
" $INDEX_FP > $INDEX_FP.tmp && mv $INDEX_FP.tmp $INDEX_FP
	fi
elif [[ $SWAP -eq 1 ]]; then
	echo vsrc=$VERSION_SOURCE
	echo vtrg=$VERSION_TARGET
	src=$(grep -E "${VERSION_SOURCE}\|.*" $INDEX_FP)
	trg=$(grep -E "${VERSION_TARGET}\|.*" $INDEX_FP)
	lsrc=$(grep -nE "${VERSION_SOURCE}\|.*" $INDEX_FP | cut -d ':' -f 1)
	ltrg=$(grep -nE "${VERSION_TARGET}\|.*" $INDEX_FP | cut -d ':' -f 1)
	echo $lsrc: src=$src
	echo $ltrg: trg=$trg
	if [[ $lsrc != "" && $ltrg != "" ]]; then
		sed -E "${lsrc}s/.*/${trg}/; ${ltrg}s/.*/${src}/" $INDEX_FP > $INDEX_FP.tmp && mv $INDEX_FP.tmp $INDEX_FP
	fi
else
	echo "[xper_index]: at least one FLAG must be 1: xper_index.sh FLAG_CLEAR FLAG_ADD FLAG_REMOVE STR_VERSION_SOURCE FLAG_AFTER FLAG_BEFORE FLAG_SWAP STR_VERSION_TARGET"
fi
