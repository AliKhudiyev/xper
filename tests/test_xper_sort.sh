#!/usr/bin/env bash

setup(){
	cd $REPO_DIR
	source ../utils.sh

	xper.sh init -y
	USERNAME=$(xper_user.sh)
	ROOT_DIR=$REPO_DIR
	INDEX_FP=$ROOT_DIR/.index

	xper.sh logfile --path log.txt
	echo "integer:42" > log.txt
	echo "float:42.34" >> log.txt
	echo "vector:42,34,5" >> log.txt

	xper.sh new    # v1
	echo "integer:-4" > log.txt
	echo "float:42.34" >> log.txt
	echo "vector:42,34,5,-8" >> log.txt

	xper.sh new -s # v2
	xper.sh logfile --path log2.txt
	rm log.txt
	echo "integer:420" > log2.txt
	echo "float:42.34" >> log2.txt
	echo "vector:42,-3,5" >> log2.txt

	xper.sh new -y # v2.1
	echo "integer:4" > log2.txt
	echo "float:42.348" >> log2.txt
	echo "vector:-50,-34,5" >> log2.txt

	xper.sh new -y # v2.1.1
	echo "integer:33" > log2.txt
	echo "float:45.34" >> log2.txt
	echo "vector:42,34,5,8" >> log2.txt

	xper.sh new -s # v3
	echo "integer:36" > log.txt
	echo "float:41.34" >> log.txt
	echo "vector:-50,3,50" >> log.txt

	xper.sh new -y # v3.1
	xper.sh logfile --path log3.1.txt
	echo "integer:1" > log3.1.txt
	echo "float:42.3" >> log3.1.txt
	echo "vector:42" >> log3.1.txt
}

teardown(){
	cd $REPO_DIR/..
	find $REPO_DIR -mindepth 1 -delete
}

test_version_sort(){
	xper.sh sort

	lines=$(cat $INDEX_FP | wc -l | tr -d ' ')
	branches=$(xper_version_count.sh)
	i=1

	if [[ $lines != $branches ]]; then
		echo "[test_xper_sort]: index file has $lines versions (expected $branches)"
		return 1
	fi

	current=$(head -$i $INDEX_FP | tail -1 | cut -d '|' -f 1)
	expected=${USERNAME}
	i=$(($i+1))
	if [[ $current != $expected ]]; then
		echo "[test_xper_sort]: version sort produced wrong ordering $current (expected $expected)"
		return 1
	fi

	current=$(head -$i $INDEX_FP| tail -1 | cut -d '|' -f 1)
	expected=${USERNAME}_v1
	i=$(($i+1))
	if [[ $current != $expected ]]; then
		echo "[test_xper_sort]: version sort produced wrong ordering $current (expected $expected)"
		return 1
	fi

	current=$(head -$i $INDEX_FP | tail -1 | cut -d '|' -f 1)
	expected=${USERNAME}_v2
	i=$(($i+1))
	if [[ $current != $expected ]]; then
		echo "[test_xper_sort]: version sort produced wrong ordering $current (expected $expected)"
		return 1
	fi

	current=$(head -$i $INDEX_FP | tail -1 | cut -d '|' -f 1)
	expected=${USERNAME}_v2.1
	i=$(($i+1))
	if [[ $current != $expected ]]; then
		echo "[test_xper_sort]: version sort produced wrong ordering $current (expected $expected)"
		return 1
	fi

	current=$(head -$i $INDEX_FP | tail -1 | cut -d '|' -f 1)
	expected=${USERNAME}_v2.1.1
	i=$(($i+1))
	if [[ $current != $expected ]]; then
		echo "[test_xper_sort]: version sort produced wrong ordering $current (expected $expected)"
		return 1
	fi

	current=$(head -$i $INDEX_FP | tail -1 | cut -d '|' -f 1)
	expected=${USERNAME}_v3
	i=$(($i+1))
	if [[ $current != $expected ]]; then
		echo "[test_xper_sort]: version sort produced wrong ordering $current (expected $expected)"
		return 1
	fi

	current=$(head -$i $INDEX_FP | tail -1 | cut -d '|' -f 1)
	expected=${USERNAME}_v3.1
	i=$(($i+1))
	if [[ $current != $expected ]]; then
		echo "[test_xper_sort]: version sort produced wrong ordering $current (expected $expected)"
		return 1
	fi

	return 0
}

test_numerical_log_sort(){
	xper.sh sort --by "integer"

	lines=$(cat $INDEX_FP | wc -l | tr -d ' ')
	branches=$(xper_version_count.sh)
	i=1

	if [[ $lines != $branches ]]; then
		echo "[test_xper_sort]: index file has $lines versions (expected $branches)"
		return 1
	fi

	current=$(head -$i $INDEX_FP | tail -1 | cut -d '|' -f 1)
	expected=${USERNAME}_v1
	i=$(($i+1))
	if [[ $current != $expected ]]; then
		echo "[test_xper_sort]: numerical sort produced wrong ordering $current (expected $expected)"
		return 1
	fi

	current=$(head -$i $INDEX_FP | tail -1 | cut -d '|' -f 1)
	expected=${USERNAME}_v3.1
	i=$(($i+1))
	if [[ $current != $expected ]]; then
		echo "[test_xper_sort]: numerical sort produced wrong ordering $current (expected $expected)"
		return 1
	fi

	current=$(head -$i $INDEX_FP | tail -1 | cut -d '|' -f 1)
	expected=${USERNAME}_v2.1
	i=$(($i+1))
	if [[ $current != $expected ]]; then
		echo "[test_xper_sort]: numerical sort produced wrong ordering $current (expected $expected)"
		return 1
	fi

	current=$(head -$i $INDEX_FP | tail -1 | cut -d '|' -f 1)
	expected=${USERNAME}_v2.1.1
	i=$(($i+1))
	if [[ $current != $expected ]]; then
		echo "[test_xper_sort]: numerical sort produced wrong ordering $current (expected $expected)"
		return 1
	fi

	current=$(head -$i $INDEX_FP | tail -1 | cut -d '|' -f 1)
	expected=${USERNAME}_v3
	i=$(($i+1))
	if [[ $current != $expected ]]; then
		echo "[test_xper_sort]: numerical sort produced wrong ordering $current (expected $expected)"
		return 1
	fi

	current=$(head -$i $INDEX_FP | tail -1 | cut -d '|' -f 1)
	expected=${USERNAME}
	i=$(($i+1))
	if [[ $current != $expected ]]; then
		echo "[test_xper_sort]: numerical sort produced wrong ordering $current (expected $expected)"
		return 1
	fi

	current=$(head -$i $INDEX_FP | tail -1 | cut -d '|' -f 1)
	expected=${USERNAME}_v2
	i=$(($i+1))
	if [[ $current != $expected ]]; then
		echo "[test_xper_sort]: numerical sort produced wrong ordering $current (expected $expected)"
		return 1
	fi

	# xper.sh sort --by "float"
	return 0
}

test_recursive_log_sort(){
	xper.sh sort --by "vector"

	lines=$(cat $INDEX_FP | wc -l | tr -d ' ')
	branches=$(xper_version_count.sh)
	i=1

	if [[ $lines != $branches ]]; then
		echo "[test_xper_sort]: index file has $lines versions (expected $branches)"
		return 1
	fi

	current=$(head -$i $INDEX_FP | tail -1 | cut -d '|' -f 1)
	expected=${USERNAME}_v2.1
	i=$(($i+1))
	if [[ $current != $expected ]]; then
		echo "[test_xper_sort]: recursive sort produced wrong ordering $current (expected $expected)"
		return 1
	fi

	current=$(head -$i $INDEX_FP | tail -1 | cut -d '|' -f 1)
	expected=${USERNAME}_v3
	i=$(($i+1))
	if [[ $current != $expected ]]; then
		echo "[test_xper_sort]: recursive sort produced wrong ordering $current (expected $expected)"
		return 1
	fi

	current=$(head -$i $INDEX_FP | tail -1 | cut -d '|' -f 1)
	expected=${USERNAME}_v2
	i=$(($i+1))
	if [[ $current != $expected ]]; then
		echo "[test_xper_sort]: recursive sort produced wrong ordering $current (expected $expected)"
		return 1
	fi

	current=$(head -$i $INDEX_FP | tail -1 | cut -d '|' -f 1)
	expected=${USERNAME}_v3.1
	i=$(($i+1))
	if [[ $current != $expected ]]; then
		echo "[test_xper_sort]: recursive sort produced wrong ordering $current (expected $expected)"
		return 1
	fi

	current=$(head -$i $INDEX_FP | tail -1 | cut -d '|' -f 1)
	expected=${USERNAME}_v1
	i=$(($i+1))
	if [[ $current != $expected ]]; then
		echo "[test_xper_sort]: recursive sort produced wrong ordering $current (expected $expected)"
		return 1
	fi

	current=$(head -$i $INDEX_FP | tail -1 | cut -d '|' -f 1)
	expected=${USERNAME}
	i=$(($i+1))
	if [[ $current != $expected ]]; then
		echo "[test_xper_sort]: recursive sort produced wrong ordering $current (expected $expected)"
		return 1
	fi

	current=$(head -$i $INDEX_FP | tail -1 | cut -d '|' -f 1)
	expected=${USERNAME}_v2.1.1
	i=$(($i+1))
	if [[ $current != $expected ]]; then
		echo "[test_xper_sort]: recursive sort produced wrong ordering $current (expected $expected)"
		return 1
	fi

	return 0
}


# = = = test begins = = = #
setup
failed=0

test_version_sort && test_numerical_log_sort && test_recursive_log_sort
failed=$(($failed+$?))

if [[ $failed -eq 0 ]]; then
	echo "[test_xper_sort]: passed"
	teardown
	exit 0
else
	echo "[test_xper_sort]: failed"
	exit 1
fi
