#!/bin/bash

CMD=$1
ARGS="$2 $3 $4"

if [[ $CMD == "init" ]]; then xper_init.sh $ARGS
elif [[ $CMD == "new" ]]; then xper_new.sh $ARGS
elif [[ $CMD == "update" ]]; then xper_update.sh $ARGS
elif [[ $CMD == "backup" ]]; then xper_backup.sh $ARGS
elif [[ $CMD == "finish" ]]; then xper_finish.sh $ARGS
elif [[ $CMD == "modify" ]]; then xper_modify.sh $ARGS
elif [[ $CMD == "lock" ]]; then xper_lock.sh $ARGS
elif [[ $CMD == "unlock" ]]; then xper_unlock.sh $ARGS
elif [[ $CMD == "goto" ]]; then xper_goto.sh $ARGS
elif [[ $CMD == "delete" ]]; then xper_delete.sh $ARGS
elif [[ $CMD == "children" ]]; then xper_children.sh $ARGS
else
	echo "usage: xper.sh [cmd] [args..]"
	printf "cmd:\n\tinit\n\tnew\n\tupdate\n\tbackup\n\tfinish\n\tmodify\n\tlock\n\tunlock\n\tgoto\n\tdelete\n"
	exit 1
fi
