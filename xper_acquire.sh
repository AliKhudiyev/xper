#!/usr/bin/env bash
# usage: xper_acquire.sh

MODE=$(xper_ctx.sh mode)
USER=$(xper_ctx.sh user)
USERNAME=$(xper_user.sh)

if [[ $MODE == "normal" ]]; then
	echo "[xper_acquire] normal mode need no acquirement"
else
	if [[ $LOCKED -eq 0 || $USER == $USERNAME ]]; then
		PUSHLOCKED=$(xper_locked.sh)
		if [[ $PUSHLOCKED -eq 1 ]]; then
			xper.sh modify --yes
			xper_ctx.sh locked 1
			xper_ctx.sh user $USERNAME
			xper.sh backup
			failed=$?
			if [[ $failed -ne 0 ]]; then
				echo "[xper_acquire] failed acquiring"
				xper.sh finish --yes
			else
				echo "[xper_acquire] acquired"
			fi
		else
			echo "[xper_acquire] already acquired"
		fi
	else
		xper.sh finish 1
	fi
fi
