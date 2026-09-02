#!/bin/bash

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


./test_xper_init.sh &&    # done
./test_xper_new.sh &&     # done
./test_xper_delete.sh &&  # done
./test_xper_update.sh &&  #
./test_xper_backup.sh &&  # 
./test_xper_acquire.sh && # 
./test_xper_release.sh && # 
./test_xper_index.sh &&   # done
./test_xper_jump.sh &&    # done
./test_xper_diff.sh &&
./test_xper_sort.sh &&    # done
./test_xper_finish.sh &&  # done
./test_xper_modify.sh &&  # done
./test_xper_clean.sh &&   # done
./test_xper_aux.sh        # 
