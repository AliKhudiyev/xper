#/bin/bash

setup(){
	cd $REPO_DIR
	source ../utils.sh

	xper.sh init
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
		return 1
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

# should create a new subversion 2.1 
# (because two previous parents' tags are different, 
# hence there is some change)
xper.sh new --tag v2.1t
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

if [[ $failed -eq 0 ]]; then
	echo "[test_xper_new]: passed"
	teardown
	exit 0
else
	echo "[test_xper_new]: failed"
	exit 1
fi
