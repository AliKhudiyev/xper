#!/usr/bin/env bash

REPO_DIR="$(pwd)/repo"
export PATH="$(pwd)/..:$PATH"

if [[ $1 != "" ]]; then
	REPO_DIR=$1
fi
echo REPO_DIR=$REPO_DIR
export REPO_DIR=$REPO_DIR

if [[ -e $REPO_DIR ]]; then
	rm -rf $REPO_DIR/*
else
	mkdir $REPO_DIR
fi


# v1.0 tests
./test_xper_init.sh &&    # done
./test_xper_new.sh &&     # done
./test_xper_delete.sh     # done
./test_xper_update.sh &&  #
./test_xper_backup.sh &&  # 
./test_xper_acquire.sh && # 
./test_xper_release.sh && # 
./test_xper_index.sh &&   # done
./test_xper_jump.sh &&    # done
./test_xper_diff.sh &&    # done
./test_xper_sort.sh &&    # done
./test_xper_finish.sh &&  # done
./test_xper_modify.sh &&  # done
./test_xper_clean.sh &&   # done
./test_xper_aux.sh        # owner, user, ref, ctx, logfile, parent, children, remote, track, untrack

# v2.0 tests
./test_xperify.sh &&         # 
./test_xper_gitify.sh &&     # 
./test_xper_broadcast.sh &&  # 
./test_xper_run.sh           # 
