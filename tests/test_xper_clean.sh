#!/usr/bin/env bash

setup(){
	cd $REPO_DIR
	source ../utils.sh

	xper.sh init -y
	USERNAME=$(xper_user.sh)
	ROOT_DIR=$REPO_DIR

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

test_repo_clean(){
	if [[ -d .git || -f .xper ]]; then
		echo "[test_xper_clean]: repo has not been cleaned properly"
		return 1
	fi
	return 0
}


# = = = test begins = = = #
setup
failed=0

# should remove .git and .xper
xper.sh clean
test_repo_clean
failed=$(($failed+$?))

# should not do anything (cleaned already)
xper.sh clean
test_repo_clean
failed=$(($failed+$?))

if [[ $failed -eq 0 ]]; then
	echo "[test_xper_clean]: passed"
	teardown
	exit 0
else
	echo "[test_xper_clean]: failed"
	exit 1
fi
