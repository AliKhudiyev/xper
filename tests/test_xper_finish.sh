#/bin/bash

setup(){
	cd $REPO_DIR
	source ../utils.sh

	xper.sh init
	USERNAME=$(xper_user.sh)
	ROOT_DIR=$REPO_DIR
	INDEX_FP=$ROOT_DIR/.index

	xper.sh new    # v1
	xper.sh new -s # v2
	xper.sh new -y # v2.1
	xper.sh new -y # v2.1.1
	xper.sh new -s # v3
	xper.sh new -y # v3.1

	# other user's versions
	git checkout -b USER
	printf "user=USER\nmode=normal\nlocked=0\ntag=\nlog=\nowner=USER\nreference=\n" > .xper
	printf ".heads\n.heads_filtered\n.index\n" > .gitignore
	git add . && git commit -m 'initial commit by USER'
	git checkout -b USER_v2
	git checkout -b USER_v2.1
	git checkout -b USER_v2.1.1
	git checkout -b USER_v2.1.2
	git checkout -b USER_v2.1.1.4
	git checkout -b USER_v2.1.2.4
	git checkout -b USER_v2.3
	git checkout -b USER_v2.3.4.1
	git checkout -b USER_v7

	git checkout $USERNAME
}

teardown(){
	cd $REPO_DIR/..
	find $REPO_DIR -mindepth 1 -delete
}

test_lock(){
	EXPECTED="$1"
	CURRENT=$(xper_locked.sh)
	MESSAGE="$2"
	if [[ $CURRENT != $EXPECTED ]]; then
		echo "[test_xper_finish]: read-only=$CURRENT (expected $EXPECTED)"
		echo "$MESSAGE"
		exit 1
	fi
	return 0
}


# = = = test begins = = = #
setup
failed=0

xper.sh finish
test_lock 1 "test 1"
failed=$(($failed+$?))

xper.sh modify
test_lock 0 "test 2"
failed=$(($failed+$?))

xper.sh jump v2
xper.sh finish
test_lock 1 "test 3"
failed=$(($failed+$?))

xper.sh jump v2.1
test_lock 0 "test 4"
failed=$(($failed+$?))

xper.sh jump v2
test_lock 1 "test 5"
failed=$(($failed+$?))

xper.sh jump v3.1
test_lock 0 "test 6"
failed=$(($failed+$?))

xper.sh finish
test_lock 1 "test 7"
failed=$(($failed+$?))

xper.sh jump v3
test_lock 0 "test 8"
failed=$(($failed+$?))

xper.sh modify
test_lock 0 "test 9"
failed=$(($failed+$?))

xper.sh jump v3.1
test_lock 1 "test 10"
failed=$(($failed+$?))

xper.sh jump v2 -u USER
test_lock 1 "test 11"
failed=$(($failed+$?))

xper.sh modify
test_lock 1 "test 12"
failed=$(($failed+$?))

xper.sh jump v2
xper.sh modify
test_lock 0 "test 13"
failed=$(($failed+$?))

if [[ $failed -eq 0 ]]; then
	echo "[test_xper_finish]: passed"
	teardown
	exit 0
else
	echo "[test_xper_finish]: failed"
	exit 1
fi
