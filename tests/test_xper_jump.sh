#/bin/bash

setup(){
	cd $REPO_DIR
	source ../utils.sh

	xper.sh init
	USERNAME=$(xper_user.sh)
	ROOT_DIR=$REPO_DIR
	INDEX_FP=$REPO_DIR/.index

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

test_version(){
	EXPECTED=$1
	MESSAGE=$2
	CURRENT=$(xper_version.sh 0)
	if [[ $CURRENT != $EXPECTED ]]; then
		echo "[test_xper_jump]: version=$CURRENT (expected $EXPECTED)"
		echo $MESSAGE
		cat $INDEX_FP
		return 1
	fi
	return 0
}


# = = = test begins = = = #
setup
failed=0

# should jump to version 1
xper.sh jump v1
test_version 1
failed=$(($failed+$?))

# should jump to version 2.1.1
xper.sh jump v2.1.1
test_version 2.1.1
failed=$(($failed+$?))

# should stay at version 2.1.1
xper.sh jump v2.1.1
test_version 2.1.1
failed=$(($failed+$?))

# xper.sh sort (by default)

# should jump to version 3
xper.sh jump -f 1
test_version 3 "v2.1.1 -f 1"
failed=$(($failed+$?))

# should jump to version 1
xper.sh jump -b 100
test_version 1
failed=$(($failed+$?))

# should jump to version 3.1
xper.sh jump -b 1 -w
test_version 3.1
failed=$(($failed+$?))

# should jump to version 2.1
xper.sh jump -w -f 3
test_version 2.1
failed=$(($failed+$?))

xper.sh sort --by "integer" # numerical sort

# should jump to version 3.1
xper.sh jump -b 1
test_version 3.1
failed=$(($failed+$?))

# should jump to version 1
xper.sh jump -b 100
test_version 1
failed=$(($failed+$?))

# should jump to version 3
xper.sh jump -b 2 --wrap
test_version 3 "v1 -b 2 --wrap"
failed=$(($failed+$?))

# should stay at version 3
xper.sh jump -b 6 --wrap
test_version 3 "v3 -b 6 --wrap"
failed=$(($failed+$?))

# should stay at version 3
xper.sh jump -f 6 --wrap
test_version 3 "v3 -b 6 --wrap"
failed=$(($failed+$?))


if [[ $failed -eq 0 ]]; then
	echo "[test_xper_jump]: passed"
	teardown
	exit 0
else
	echo "[test_xper_jump]: failed"
	exit 1
fi
