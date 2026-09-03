#!/usr/bin/env bash
# usage: xper_release.sh

MODE=$(xper_ctx.sh mode)
USER=$(xper_ctx.sh user)
LOCKED=$(xper_ctx.sh locked)
USERNAME=$(xper_user.sh)
PUSHLOCKED=$(xper_locked.sh)

# echo mode=$MODE pushlocked=$PUSHLOCKED locked=$LOCKED user=$USER username=$USERNAME

if [[ $MODE == "normal" ]]; then
	echo "[xper_release] normal mode need no release"
elif [[ $PUSHLOCKED -eq 1 ]]; then
	echo "[xper_release] already released"
elif [[ $PUSHLOCKED -eq 0 && $LOCKED -eq 1 && $USER == $USERNAME ]]; then
	xper_ctx.sh locked 0
	# xper_ctx.sh user $USERNAME
	xper.sh backup --yes
	failed=$?
	xper.sh finish --yes
	if [[ $failed -eq 1 ]]; then
		echo "[xper_release] could not release"
		xper.sh modify --yes
	else
		echo "[xper_release] released"
	fi
else
	echo "[xper_release] could not release :("
fi
