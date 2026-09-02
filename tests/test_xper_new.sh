#/bin/bash

setup(){
	cd $REPO_DIR
	source ../utils.sh

	xper.sh init
	USERNAME=$(xper_user.sh)
	ROOT_DIR=$REPO_DIR
	INDEX_FP=$ROOT_DIR/.index

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
	exit 0
}

teardown(){
	cd $REPO_DIR/..
	find $REPO_DIR -mindepth 1 -delete
}

test_version(){
	EXPECTED=$1
	CURRENT=$(xper_version.sh 0)
	if [[ $CURRENT != $EXPECTED ]]; then
		echo "[test_xper_new]: version=$CURRENT (expected $EXPECTED)"
		exit 1
	fi
	return 0
}

test_reference(){
	EXPECTED=$1
	CURRENT=$(xper_ref.sh)
	if [[ $CURRENT != $EXPECTED ]]; then
		echo "[test_xper_new]: ref=$CURRENT (expected $EXPECTED)"
		exit 1
	fi
	return 0
}

test_tag(){
	EXPECTED=$1
	CURRENT=$(xper_ctx.sh tag)
	if [[ $CURRENT != $EXPECTED ]]; then
		echo "[test_xper_new]: tag=$CURRENT (expected $EXPECTED)"
		return 1
	fi
	return 0
}

# = = = test begins = = = #
setup
failed=0

# should create the first version
xper.sh new
test_version 1
failed=$(($failed+$?))

# should not create a new subversion (due to no changes)
xper.sh new
test_version 1
failed=$(($failed+$?))

# should not create a new subversion (due to no changes)
xper.sh new --tag newtag
test_version 1 && test_tag ""
failed=$(($failed+$?))

# should create a new subversion
xper.sh new --yes
test_version 1.1
failed=$(($failed+$?))

# should create a new version 2 with tag v2t
xper.sh new --scratch --tag v2t
test_version 2
failed=$(($failed+$?))

# should NOT create a new subversion 2.1 
# (even if two previous parents' tags are different, 
# because .xper is meta and not subject to git diff)
xper.sh new --tag v2.1t
test_version 2 && test_tag v2t
failed=$(($failed+$?))

# should create a new subversion 2.1 (due to --yes flag)
xper.sh new --tag v2.1t --yes
test_version 2.1 && test_tag v2.1t
failed=$(($failed+$?))

# should create a new version 3 with tag v3t
xper.sh new --scratch --tag v3t
test_version 3 && test_tag v3t
failed=$(($failed+$?))

# deleting the first version
USERNAME=$(xper_user.sh)
git branch -D ${USERNAME}_v1

# should create a new version 4 (not version 3)
xper.sh new -s
test_version 4
failed=$(($failed+$?))

# should create a new subversion 4.1
xper.sh new -y
test_version 4.1
failed=$(($failed+$?))

# should create a new version 4.1.1
xper.sh new -y
test_version 4.1.1
failed=$(($failed+$?))

# jumping to version 4
git checkout ${USERNAME}_v4

# should create a new version 4.2
xper.sh new -y
test_version 4.2
failed=$(($failed+$?))

# = = = tests for multi-user settings = = =

# should create a new copy at v2.2 (since v2.1 already exists)
git checkout USER_v2
xper.sh new
test_version 2.2 && test_reference USER_v2
failed=$(($failed+$?))

# should create a new copy at v2.1.2 (with reference to USER_v2.1)
git checkout USER_v2.1
xper.sh new
test_version 2.1.2 && test_reference USER_v2.1
failed=$(($failed+$?))

# should create a new copy at v2.1.1.1 (with reference to USER_v2.1.1)
git checkout USER_v2.1.1
xper.sh new
test_version 2.1.1.1 && test_reference USER_v2.1.1
failed=$(($failed+$?))

# should create a new copy at v2.1.2.1 (since v2.1.2 already exists)
git checkout USER_v2.1.2.4
xper.sh new
test_version 2.1.2.1 && test_reference USER_v2.1.2.4
failed=$(($failed+$?))

# should create a new copy at v4 (with reference to USER_v7)
git checkout USER_v7
xper.sh new
test_version 4 && test_reference USER_v7
failed=$(($failed+$?))

if [[ $failed -eq 0 ]]; then
	echo "[test_xper_new]: passed"
	teardown
	exit 0
else
	echo "[test_xper_new]: failed"
	exit 1
fi
