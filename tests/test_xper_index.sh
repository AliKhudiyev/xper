#/usr/bin/env bash

setup(){
	cd $REPO_DIR
	source ../utils.sh

	xper.sh init -y
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

test_index_count(){
	EXPECTED="$1"
	CURRENT=$(grep -c "." $ROOT_DIR/.index)
	MESSAGE="$2"
	if [[ $CURRENT != $EXPECTED ]]; then
		echo "[test_xper_index]: count=$CURRENT (expected $EXPECTED)"
		echo "$MESSAGE"
		exit 1
	fi
	return 0
}

test_index_exists_at(){
	EXPECTED="$1"
	LINE_NUM="$2"
	CURRENT=$(sed -n "${LINE_NUM}p" $ROOT_DIR/.index | cut -d '|' -f 1)
	MESSAGE="$3"
	if [[ $CURRENT != $EXPECTED ]]; then
		echo "[test_xper_index]: version[@$LINE_NUM]=$CURRENT (expected $EXPECTED)"
		echo "$MESSAGE"
		exit 1
	fi
	return 0
}

test_version(){
	EXPECTED="$1"
	CURRENT=$(xper_version.sh 0)
	MESSAGE="$2"
	if [[ $CURRENT != $EXPECTED ]]; then
		echo "[test_xper_index]: version=$CURRENT (expected $EXPECTED)"
		echo "$MESSAGE"
		exit 1
	fi
	return 0
}


# = = = test begins = = = #
setup
failed=0

xper.sh index --clear
test_index_count 0
failed=$(($failed+$?))

git checkout ${USERNAME}_v1
xper.sh index --add
test_index_count 1 && test_index_exists_at ${USERNAME}_v1 1 "adding default v1"
failed=$(($failed+$?))

# should not add the same version twice
xper.sh index --add
test_index_count 1
failed=$(($failed+$?))

xper.sh index --add USER_v2.1
xper.sh index --add USER_v7
xper.sh index --add ${USERNAME}_v2.1
test_index_count 4 && test_index_exists_at USER_v2.1 2 && test_index_exists_at USER_v7 3 && test_index_exists_at ${USERNAME}_v2.1 4
failed=$(($failed+$?))

# after swapping index 2 and 4
xper.sh index --swap ${USERNAME}_v2.1 USER_v2.1
test_index_count 4 && test_index_exists_at USER_v2.1 4 "after swapping index 2 and 4" && test_index_exists_at USER_v7 3 && test_index_exists_at ${USERNAME}_v2.1 2
failed=$(($failed+$?))

# swapping version with itself
xper.sh index --swap ${USERNAME}_v1
test_index_count 4 && test_index_exists_at ${USERNAME}_v1 1 && test_index_exists_at USER_v2.1 4 "after swapping $USERNAME_v1 with itself" && test_index_exists_at USER_v7 3 && test_index_exists_at ${USERNAME}_v2.1 2
failed=$(($failed+$?))

# reordering version with itself
xper.sh index --before ${USERNAME}_v1
test_index_count 4 && test_index_exists_at ${USERNAME}_v1 1 && test_index_exists_at USER_v2.1 4 && test_index_exists_at USER_v7 3 && test_index_exists_at ${USERNAME}_v2.1 2
failed=$(($failed+$?))

# reordering version with itself
xper.sh index --after ${USERNAME}_v1
test_index_count 4 && test_index_exists_at ${USERNAME}_v1 1 && test_index_exists_at USER_v2.1 4 && test_index_exists_at USER_v7 3 && test_index_exists_at ${USERNAME}_v2.1 2
failed=$(($failed+$?))

xper.sh index --after USER_v7
test_index_count 4 && test_index_exists_at ${USERNAME}_v1 4 "--after USER_v7" && test_index_exists_at USER_v2.1 3 && test_index_exists_at USER_v7 2 && test_index_exists_at ${USERNAME}_v2.1 1
failed=$(($failed+$?))

# shouldn't change anything because USER_v2.1.3 doesn't exist
xper.sh index --before USER_v7 USER_v2.1.3
test_index_count 4 && test_index_exists_at ${USERNAME}_v1 4 "--after shouldn't change" && test_index_exists_at USER_v2.1 3 && test_index_exists_at USER_v7 2 && test_index_exists_at ${USERNAME}_v2.1 1
failed=$(($failed+$?))

# shouldn't change anything because USER_v27 doesn't exist
xper.sh index --before USER_v7.1 USER_v2.1
test_index_count 4 && test_index_exists_at ${USERNAME}_v1 4 && test_index_exists_at USER_v2.1 3 && test_index_exists_at USER_v7 2 && test_index_exists_at ${USERNAME}_v2.1 1 || echo "--after shouldn't change"
failed=$(($failed+$?))

xper.sh index --before USER_v7 USER_v2.1
test_index_count 4 && test_index_exists_at ${USERNAME}_v1 4 && test_index_exists_at USER_v2.1 2 && test_index_exists_at USER_v7 3 && test_index_exists_at ${USERNAME}_v2.1 1
failed=$(($failed+$?))

# shouldn't change anything because USER_v73 doesn't exist
xper.sh index --remove USER_v73
test_index_count 4 && test_index_exists_at ${USERNAME}_v1 4 && test_index_exists_at USER_v2.1 2 && test_index_exists_at USER_v7 3 && test_index_exists_at ${USERNAME}_v2.1 1
failed=$(($failed+$?))

xper.sh index --remove USER_v7
test_index_count 3 && test_index_exists_at ${USERNAME}_v1 3 && test_index_exists_at USER_v2.1 2 && test_index_exists_at ${USERNAME}_v2.1 1
failed=$(($failed+$?))

xper.sh index --remove ${USERNAME}_v2.1
test_index_count 2 && test_index_exists_at ${USERNAME}_v1 2 && test_index_exists_at USER_v2.1 1
failed=$(($failed+$?))


if [[ $failed -eq 0 ]]; then
	echo "[test_xper_index]: passed"
	teardown
	exit 0
else
	echo "[test_xper_index]: failed"
	exit 1
fi
