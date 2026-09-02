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


# = = = test begins = = = #
setup
failed=0

# TODO
failed=$(($failed+$?))

if [[ $failed -eq 0 ]]; then
	echo "[test_xper_update]: passed"
	teardown
	exit 0
else
	echo "[test_xper_update]: failed"
	exit 1
fi
