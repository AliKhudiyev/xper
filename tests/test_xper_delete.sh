#/bin/bash

setup(){
	cd $REPO_DIR
	source ../utils.sh

	xper.sh init
	USERNAME=$(xper_user.sh)

	xper.sh new    # v1
	xper.sh new -s # v2
	xper.sh new -y # v2.1
	xper.sh new -y # v2.1.1
	xper.sh new -s # v3
	xper.sh new -y # v3.1
}

teardown(){
	cd $REPO_DIR/..
	find $REPO_DIR -mindepth 1 -delete
}

test_version(){
	EXPECTED=$1
	CURRENT=$(xper_version.sh 0)
	if [[ $CURRENT != $EXPECTED ]]; then
		echo "[test_xper_delete]: version=$CURRENT (expected $EXPECTED)"
		return 1
	fi
	return 0
}

test_branch(){
	EXPECTED=$1
	CURRENT=$(xper_version.sh 1)
	if [[ $CURRENT != $EXPECTED ]]; then
		echo "[test_xper_delete]: branch=$CURRENT (expected $EXPECTED)"
		return 1
	fi
	return 0
}

test_branch_count(){
	EXPECTED=$1
	CURRENT=$(xper_version_count.sh)
	if [[ $CURRENT != $EXPECTED ]]; then
		echo "[test_xper_delete]: branch count=$CURRENT (expected $EXPECTED)"
		return 1
	fi
	return 0
}


# = = = test begins = = = #
setup
failed=0

# jump to version 2
git checkout ${USERNAME}_v2
test_version 2 && test_branch_count 7
failed=$(($failed+$?))

# should delete v2* and move to the base branch (version=0)
xper.sh delete
test_version 0 && test_branch $USERNAME && test_branch_count 4
failed=$(($failed+$?))

# should not delete the base branch
xper.sh delete
test_version 0 && test_branch $USERNAME && test_branch_count 4
failed=$(($failed+$?))

# jump to version 1
git checkout ${USERNAME}_v1
test_version 1 && test_branch_count 4
failed=$(($failed+$?))

# should delete version 1
xper.sh delete
test_version 0 && test_branch $USERNAME && test_branch_count 3
failed=$(($failed+$?))

# jump to subversion 3.1
git checkout ${USERNAME}_v3.1
test_version 3.1 && test_branch_count 3
failed=$(($failed+$?))

# should delete subvesion 3.1 only
xper.sh delete
test_version 0 && test_branch $USERNAME && test_branch_count 2
failed=$(($failed+$?))

if [[ $failed -eq 0 ]]; then
	echo "[test_xper_delete]: passed"
	teardown
	exit 0
else
	echo "[test_xper_delete]: failed"
	exit 1
fi
