#!/bin/bash

NECESSARY_MARGIN=2
RIGHT_MARGIN=$(($NECESSARY_MARGIN+2))
MAX_LINE_WIDTH=$(($(tput cols 2>/dev/null || echo 80)-$RIGHT_MARGIN))

CMD_WIDTH=12
OPT_WIDTH=20

print_command_info(){
	local cmd=$1
	IFS=':' read -r -a opts <<< "$2"
	IFS=':' read -r -a info <<< "$3"
	local opts_count=${#opts}
	local cmd_width=$CMD_WIDTH
	local opt_width=$OPT_WIDTH
	local info_spaces=$(($cmd_width+$opt_width))
	local info_width=$(($MAX_LINE_WIDTH-$info_spaces))

	# echo $cmd
	# echo "opts:" $opts
	# echo "info:" $info
	# echo ${info[2]}
	# echo $info_width
	printf "%-*s" "$cmd_width" "  $cmd "
	for i in ${!opts[@]}; do
		printf "${opts[i]}"
		if [[ ${info[i]} != "_" ]]; then
			# local info_folded=$(echo ${info[i]} | fold -s -w 30)
			# echo ${info_folded}
			# echo ${info[i]} | fold -s -w 30
			local offset=$(($cmd_width+${#opts[i]}))
			printf "%*s%s" "$(($info_spaces-$offset))" "" ":"
			offset=$info_spaces
			echo ${info[i]} | fold -s -w $info_width | while read -r line; do
				# printf "line is:: $line"
				printf "%*s%s" "$(($info_spaces-$offset))" "" " ${line}"
				printf "\n"
				offset=-1
			done
		else
			printf "\n"
		fi
		printf "%*s" "$cmd_width" ""
	done

	echo
}

# print_command_info "new" "[-s]:[-t]:[-y]" "initializes:_:yes"
# print_command_info "init" "[-s|--scratch]:[-t|--tag <tag>]:[-y|--yes]" "initializes:_:(forces creation)"
# print_command_info "tag" "[<new_tag>]" "show tag (if no new_tag) or rename (if new_tag is provided)"

print_help(){
	printf "usage: xper <command> [options]"
	printf "\n\n"
	printf "%-*s" "$CMD_WIDTH" "commands"
	printf "%-*s" "$OPT_WIDTH" "options"
	printf "%-*s" "$(($CMD_WIDTH+$OPT_WIDTH))" "description"
	printf "\n"
	printf "%*s" "$MAX_LINE_WIDTH" "" | tr ' ' '-'
	printf "\n"

	print_command_info "init" ":" "initializes:"
	print_command_info "new" "[-s|--scratch]:[-t|--tag <tag>]:[-y|--yes]" "duplicates the current experiment into a new branch/version:(gives it a new tag):(forces creation even without any diff with parent version)"
	print_command_info "tag" "[<new_tag>]" "show tag (if no new_tag) or rename (if new_tag is provided)"
	print_command_info "del|delete" ":" "delete current version and all of its subversions recursively:"
	print_command_info "update" ":" "pull lates changes from remote repository:"
	print_command_info "backup" ":" "push local changes to remote repository"
	print_command_info "finish" ":" "lock current version (permit further modifications) and backup to remote repository (if any)"
	print_command_info "modify" ":" "update from remote repository (if any) and unlock current version for modification"
	print_command_info "jump" "<version>:[-u|--user]" "go to absolute version of any user (default user is the local user):"
	print_command_info "jump" "[-w|--wrap]:[-g|--global]:[-b|--backward <steps>]:[-f|--forward <steps>]:[-u|--user <username>]" "traverse the version tree by using relative distance/steps from the current version; -g option traverses the global version tree where everyone's commits exist; -u option lets traversing only particular user's commits:_:(for all users):(for backward jumps):(for forward jumps):(for only particular user)"
	print_command_info "mode" "[-n|--normal]:[-s|--sequential]" "switch to normal mode; in this mode, update and backup commands are non-blocking:switch to supervisional or sequential mode; in this mode, update and backup commands are blocking relative to other contributors"
	print_command_info "diff" "<version>:" "show diff between current version and <version>:"
	print_command_info "diff jump" "[jump-options]:" "show diff between current version and the one after jump:"
	print_command_info "children" ":" "show all 1-level-deep subversions"
	print_command_info "help" ":" "print this whole message to terminal:"
}

if [[ $# -eq 0 || $1 == "help" ]]; then print_help; fi

CMD=$1
shift

FLAG_SCRATCH=0
FLAG_YES=0
FLAG_WRAP=0
FLAG_GLOBAL=0
FLAG_NORMAL_MODE=0
FLAG_FIRST=0
FLAG_LAST=0
FLAG_FILEPATH=0
FLAG_CLEAR=0
FLAG_ADD=0
FLAG_REMOVE=0
FLAG_AFTER=0
FLAG_BEFORE=0
FLAG_SWAP=0

OPTARG_TAG=""
OPTARG_USER=$(xper_user.sh)
OPTARG_BACKWARD_STEPS=0
OPTARG_FORWARD_STEPS=0
OPTARG_SORTBY=""
OPTARG_FILEPATH=""
OPTARG_VERSION_SOURCE="$(xper_version.sh 1)"
OPTARG_VERSION_TARGET=""
OPTARG_SUBCMD=""

while [[ $# -gt 0 ]]; do
	case "$1" in
		-s|--scratch)
			FLAG_SCRATCH=1
			shift
			;;
		-t|--tag)
			OPTARG_TAG=$2
			shift 2
			;;
		-y|--yes)
			FLAG_YES=1
			shift
			;;
		-u|--user)
			OPTARG_USER=$2
			shift 2
			;;
		-w|--wrap)
			FLAG_WRAP=1
			shift
			;;
		-g|--global)
			FLAG_GLOBAL=1
			shift
			;;
		-b|--backward)
			OPTARG_BACKWARD_STEPS=$2
			shift 2
			;;
		-f|--forward)
			echo forward option
			OPTARG_FORWARD_STEPS=$2
			shift 2
			;;
		-n|--normal)
			FLAG_NORMAL_MODE=1
			shift
			;;
		-s|--sequential)
			FLAG_NORMAL_MODE=0
			shift
			;;
		-p|--path)
			FLAG_FILEPATH=1
			OPTARG_FILEPATH=$2
			shift 2
			;;
		-c|--clear)
			FLAG_CLEAR=1
			shift
			;;
		-a|--add)
			FLAG_ADD=1
			OPTARG_VERSION_SOURCE=$2
			shift 2
			;;
		-rm|--remove)
			FLAG_REMOVE=1
			OPTARG_VERSION_SOURCE=$2
			shift=2
			;;
		--after)
			FLAG_AFTER=1
			OPTARG_VERSION_TARGET=$2
			OPTARG_VERSION_SOURCE=$2
			shift 3
			;;
		--before)
			FLAG_BEFORE=1
			OPTARG_VERSION_TARGET=$2
			OPTARG_VERSION_SOURCE=$2
			shift 3
			;;
		--swap)
			FLAG_SWAP=1
			OPTARG_VERSION_TARGET=$2
			OPTARG_VERSION_SOURCE=$2
			shift 3
			;;
		--first)
			FLAG_FIRST=1
			;;
		--last)
			FLAG_LAST=1
			;;
		--by)
			OPTARG_SORTBY=$2
			shift 2
			;;
		*)
			OPTARG_SUBCMD=$1
			shift
			;;
	esac
done

case $CMD in
	init)
		OPTARG_USER=$(git config --global user.name | tr -d ' ')
		xper_init.sh
		;;
	new)
		echo flgyes=$FLAG_YES
		xper_new.sh $FLAG_SCRATCH "$OPTARG_TAG" $FLAG_YES
		;;
	tag)
		xper_new.sh $OPTARG_TAG
		;;
	delete)
		xper_delete.sh
		;;
	update)
		xper_update.sh
		;;
	backup)
		xper_backup.sh
		;;
	finish)
		xper_finish.sh
		;;
	modify)
		xper_modify.sh
		;;
	jump|goto)
		FORWARD=1
		if [[ $OPTARG_SUBCMD != "" ]]; then
			xper_goto.sh "$OPTARG_SUBCMD" "$FLAG_FIRST" "$FLAG_LAST"
		else
			if [[ $OPTARG_BACKWARD_STEPS -gt $OPTARG_FORWARD_STEPS ]]; then
				FORWARD=0
				STEPS=$(($OPTARG_BACKWARD_STEPS-$OPTARG_FORWARD_STEPS))
			else
				FORWARD=1
				STEPS=$(($OPTARG_FORWARD_STEPS-$OPTARG_BACKWARD_STEPS))
			fi
			xper_goto_rel.sh $FLAG_GLOBAL $FLAG_WRAP $FORWARD $STEPS $OPTARG_USER
		fi
		;;
	mode)
		echo mode
		;;
	diff)
		current_version=$(git branch --show-current)
		version=$(git branch --show-current)
		if [[ $OPTARG_SUBCMD == "jump" || $OPTARG_SUBCMD == "goto" ]]; then
			FORWARD=1
			if [[ $OPTARG_SUBCMD != "" ]]; then
				xper_goto.sh "$OPTARG_SUBCMD" "$FLAG_FIRST" "$FLAG_LAST"
			elif [[ $OPTARG_BACKWARD_STEPS -gt $OPTARG_FORWARD_STEPS ]]; then
				FORWARD=0
				STEPS=$(($OPTARG_BACKWARD_STEPS-$OPTARG_FORWARD_STEPS))
			else
				FORWARD=1
				STEPS=$(($OPTARG_FORWARD_STEPS-$OPTARG_BACKWARD_STEPS))
			xper_goto_rel.sh $FLAG_GLOBAL $FLAG_WRAP $FORWARD $STEPS $OPTARG_USER
			fi
			version=$(git branch --show-current)
		fi
		xper_goto.sh "$current_version" "$FLAG_FIRST" "$FLAG_LAST"
		xper_diff.sh "$version"
		;;
	children)
		xper_children.sh
		;;
	parent)
		xper_parent.sh
		;;
	logfile)
		xper_logfp.sh "$FLAG_FILEPATH" "$OPTARG_FILEPATH"
		;;
	owner)
		xper_owner.sh
		;;
	sort)
		xper_sort.sh "$OPTARG_SORTBY" "$FLAG_GLOBAL" "$OPTARG_USER"
		;;
	index)
		xper_index.sh "$FLAG_CLEAR" "$FLAG_ADD" "$FLAG_REMOVE" "$OPTARG_VERSION_SOURCE" "$FLAG_AFTER" "$FLAG_BEFORE" "$FLAG_SWAP" "$OPTARG_VERSION_TARGET"
		;;
	clean)
		xper_clean.sh
		;;
	*)
		print_help
		;;
esac

# if [[ $CMD == "init" ]]; then xper_init.sh $ARGS
# elif [[ $CMD == "new" ]]; then xper_new.sh $ARGS
# elif [[ $CMD == "update" ]]; then xper_update.sh $ARGS
# elif [[ $CMD == "backup" ]]; then xper_backup.sh $ARGS
# elif [[ $CMD == "finish" ]]; then xper_finish.sh $ARGS
# elif [[ $CMD == "modify" ]]; then xper_modify.sh $ARGS
# elif [[ $CMD == "lock" ]]; then xper_lock.sh $ARGS
# elif [[ $CMD == "unlock" ]]; then xper_unlock.sh $ARGS
# elif [[ $CMD == "goto" ]]; then xper_goto.sh $ARGS
# elif [[ $CMD == "delete" ]]; then xper_delete.sh $ARGS
# elif [[ $CMD == "children" ]]; then xper_children.sh $ARGS
# fi
