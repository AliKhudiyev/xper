#/bin/bash

setup(){
	cd $REPO_DIR
	source ../utils.sh
}

teardown(){
	cd $REPO_DIR/..
	find $REPO_DIR -mindepth 1 -delete
}

test_files_exist(){
	if [[ ! -d .git ]]; then
		echo "[test_xper_init]: .git folder is missing"
		return 1
	fi

	if [[ ! -f .xper ]]; then
		echo "[test_xper_init]: .xper file is missing"
		return 1
	fi

	return 0
}

test_xper_ctx(){
	USER=$(xper_ctx.sh user)
	MODE=$(xper_ctx.sh mode)
	LOCK=$(xper_ctx.sh locked)
	LOG=$(xper_ctx.sh log)
	TAG=$(xper_ctx.sh tag)
	OWNER=$(xper_ctx.sh owner)

	if [[ $MODE != "normal" ]]; then
		echo "[test_xper_init]: mode=$MODE (expected 'normal')"
		return 1
	fi

	if [[ $LOCK -ne 0 ]]; then
		echo "[test_xper_init]: locked=$LOCK (expected 0)"
		return 1
	fi

	if [[ $OWNER != $USER ]]; then
		echo "[test_xper_init]: owner=$OWNER (expected $USER)"
		return 1
	fi

	return 0
}

# = = = test begins = = = #
setup

xper.sh init
test_files_exist && test_xper_ctx

if [[ $? -eq 0 ]]; then
	echo "[test_xper_init]: passed"
	teardown
	exit 0
else
	echo "[test_xper_init]: failed"
	exit 1
fi
