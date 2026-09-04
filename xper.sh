#!/usr/bin/env bash

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
	print_command_info "remote" "[--add <REPO-URL>]:" "sets remote repository:"
	print_command_info "track" "<filepath>:" "track a file or a folder completely:"
	print_command_info "untrack" "<filepath>:" "untrack a file or a folder completely:"
	print_command_info "tag" "[<new_tag>]" "show tag (if no new_tag) or rename (if new_tag is provided)"
	print_command_info "del|delete" ":" "delete current version and all of its subversions recursively:"
	print_command_info "update" ":" "pull lates changes from remote repository:"
	print_command_info "backup" ":" "push local changes to remote repository"
	print_command_info "acquire" ":" "pull lates changes from remote repository:"
	print_command_info "release" ":" "push local changes to remote repository"
	print_command_info "jump" "<version>:[-u|--user <username>]" "go to absolute version of any user (default user is the local user):"
	print_command_info "jump" "[-w|--wrap]:[-g|--global]:[-b|--backward <steps>]:[-f|--forward <steps>]:[-u|--user <username>]" "traverse the version tree by using relative distance/steps from the current version; -g option traverses the global version tree where everyone's commits exist; -u option lets traversing only particular user's commits:_:(for all users):(for backward jumps):(for forward jumps):(for only particular user)"
	print_command_info "sort" "[--by <log-field>]:" "sort by version numbers or <log-field> if provided:"
	print_command_info "index" "[--clear]:[--add [<version>]]:[-rm|--remove [<version>]]" "clear the index file:add <version> (current version by default) from the index file:remove <version> (current version by default) from the index file"
	print_command_info "index" "[--after|--before|--swap <vXY>] [<vXX>:" "put <vXX> (current version by default) after/before/swap <vXY> in the index file"
	print_command_info "diff" "<version>:" "show diff between current version and <version>:"
	print_command_info "diff jump" "[jump-options]:" "show diff between current version and the one after jump:"

	echo "  -------------- auxiliary --------------"
	print_command_info "finish" ":" "lock current version (permit further modifications) and backup to remote repository (if any)"
	print_command_info "modify" ":" "update from remote repository (if any) and unlock current version for modification"
	# print_command_info "mode" "[-n|--normal]:[-s|--sequential]" "switch to normal mode; in this mode, update and backup commands are non-blocking:switch to supervisional or sequential mode; in this mode, update and backup commands are blocking relative to other contributors"
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
FLAG_NORMAL_MODE=1
FLAG_FIRST=0
FLAG_LAST=0
FLAG_FILEPATH=0
FLAG_CLEAR=0
FLAG_ADD=0
FLAG_REMOVE=0
FLAG_AFTER=0
FLAG_BEFORE=0
FLAG_SWAP=0
FLAG_ONLYLEAF=0
FLAG_ACQUIRE=0
FLAG_RELEASE=0
FLAG_SORT=0
FLAG_CTIME=0
FLAG_MTIME=0

OPTARG_TAG=""
OPTARG_USER=$(xper_user.sh)
OPTARG_BACKWARD_STEPS=0
OPTARG_FORWARD_STEPS=0
OPTARG_SORTBY=""
OPTARG_FILEPATH=""
OPTARG_VERSION_SOURCE="$(xper_version.sh 1)"
OPTARG_VERSION_TARGET=""
OPTARG_REMOTE_URL=""
OPTARG_VERSIONS="v*"
OPTARG_WORKERS=1
OPTARG_OUTPUT_DIR=""
OPTARG_SUBCMD=""

while [[ $# -gt 0 ]]; do
	case "$1" in
		-s|--scratch|--sort)
			FLAG_SCRATCH=1
			FLAG_SORT=1
			if [[ "$1" == "--sort" ]]; then
				FLAG_SCRATCH=0
			elif [[ "$1" == "--scratch" ]]; then
				FLAG_SORT=0
			fi
			shift
			;;
		-t|--tag)
			if [[ $# -ge 2 ]]; then
				OPTARG_TAG=$2
				shift
			fi
			shift
			;;
		-y|--yes)
			FLAG_YES=1
			shift
			;;
		-u|--user)
			if [[ $# -ge 2 ]]; then
				OPTARG_USER=$2
				# echo optarg_user=$2
				shift
			fi
			shift
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
			if [[ $# -ge 2 ]]; then
				OPTARG_BACKWARD_STEPS=$2
				shift
			fi
			shift
			;;
		-f|--forward)
			# echo forward option
			if [[ $# -ge 2 ]]; then
				OPTARG_FORWARD_STEPS=$2
				shift
			fi
			shift
			;;
		-nl|--normal)
			FLAG_NORMAL_MODE=1
			shift
			;;
		-sl|--sequential|--supervisional)
			FLAG_NORMAL_MODE=0
			shift
			;;
		-p|--path)
			FLAG_FILEPATH=1
			if [[ $# -ge 2 ]]; then
				OPTARG_FILEPATH=$2
				shift
			fi
			shift
			;;
		-c|--clear)
			FLAG_CLEAR=1
			shift
			;;
		-a|--add)
			FLAG_ADD=1
			if [[ $# -ge 2 ]]; then
				OPTARG_VERSION_SOURCE="$2"
				OPTARG_REMOTE_URL="$2"
				shift
			fi
			shift
			;;
		-rm|--remove)
			FLAG_REMOVE=1
			if [[ $# -ge 2 ]]; then
				OPTARG_VERSION_SOURCE=$2
				shift
			fi
			shift
			;;
		--after)
			FLAG_AFTER=1
			if [[ $# -ge 2 ]]; then
				OPTARG_VERSION_TARGET=$2
				shift
			fi
			if [[ $# -ge 2 ]]; then
				OPTARG_VERSION_SOURCE=$2
				shift
			fi
			shift
			;;
		--before)
			FLAG_BEFORE=1
			if [[ $# -ge 2 ]]; then
				OPTARG_VERSION_TARGET=$2
				shift
			fi
			if [[ $# -ge 2 ]]; then
				OPTARG_VERSION_SOURCE=$2
				shift
			fi
			shift
			;;
		--swap)
			FLAG_SWAP=1
			if [[ $# -ge 2 ]]; then
				OPTARG_VERSION_TARGET=$2
				shift
			fi
			if [[ $# -ge 2 ]]; then
				OPTARG_VERSION_SOURCE=$2
				shift
			fi
			shift
			;;
		--only-leaf)
			FLAG_ONLYLEAF=1
			shift
			;;
		-ct)
			FLAG_CTIME=1
			shift
			;;
		-mt)
			FLAG_MTIME=1
			shift
			;;
		--acquire)
			FLAG_ACQUIRE=1
			FLAG_RELEASE=0
			shift
			;;
		--release)
			FLAG_RELEASE=1
			FLAG_ACQUIRE=0
			shift
			;;
		--first)
			FLAG_FIRST=1
			shift
			;;
		--last)
			FLAG_LAST=1
			shift
			;;
		--by)
			if [[ $# -ge 2 ]]; then
				OPTARG_SORTBY=$2
				shift
			fi
			shift
			;;
		-v|--to)
			if [[ $# -ge 2 ]]; then
				OPTARG_VERSIONS=$2
				shift
			fi
			shift
			;;
		--workers)
			if [[ $# -ge 2 ]]; then
				OPTARG_WORKERS=$2
				shift
			fi
			shift
			;;
		-o|--output)
			if [[ $# -ge 2 ]]; then
				OPTARG_OUTPUT_DIR=$2
				shift
			fi
			shift
			;;
		*)
			OPTARG_SUBCMD=$1
			OPTARG_FILEPATH=$1
			shift
			;;
	esac
done

case $CMD in
	init)
		# OPTARG_USER=$(git config --global user.name | tr -d ' ')
		xper_init.sh "$FLAG_YES"
		;;
	remote)
		xper_remote.sh "$FLAG_ADD" "$OPTARG_REMOTE_URL"
		;;
	track)
		xper_track.sh "$OPTARG_FILEPATH"
		;;
	untrack)
		xper_untrack.sh "$OPTARG_FILEPATH"
		;;
	new)
		# echo flgyes=$FLAG_YES
		xper_new.sh "$FLAG_SCRATCH" "$OPTARG_TAG" "$FLAG_YES" "$FLAG_NORMAL_MODE" "$FLAG_ACQUIRE"
		;;
	tag)
		echo "[xper] use xper_ctx.sh tag [<your-tag>]"
		# xper_new.sh "$OPTARG_TAG"
		;;
	delete)
		xper_delete.sh
		;;
	update)
		xper_update.sh "$FLAG_GLOBAL"
		;;
	backup)
		xper_backup.sh "$FLAG_GLOBAL"
		;;
	acquire)
		xper_acquire.sh
		;;
	release)
		xper_release.sh
		;;
	finish)
		xper_finish.sh "$FLAG_YES"
		;;
	modify)
		xper_modify.sh "$FLAG_YES"
		;;
	jump|goto)
		FORWARD=1
		if [[ $OPTARG_SUBCMD != "" ]]; then
			# echo absolute jump
			xper_goto.sh "$OPTARG_SUBCMD" "$OPTARG_USER"
		else
			if [[ $OPTARG_BACKWARD_STEPS -gt $OPTARG_FORWARD_STEPS ]]; then
				FORWARD=0
				STEPS=$(($OPTARG_BACKWARD_STEPS-$OPTARG_FORWARD_STEPS))
			else
				FORWARD=1
				STEPS=$(($OPTARG_FORWARD_STEPS-$OPTARG_BACKWARD_STEPS))
			fi
			xper_goto_rel.sh "$FLAG_GLOBAL" "$FLAG_WRAP" "$FORWARD" "$STEPS" "$OPTARG_USER" "$FLAG_FIRST" "$FLAG_LAST" "$FLAG_SORT" "$FLAG_CTIME" "$FLAG_MTIME"
		fi
		;;
	diff)
		current_version=$(git branch --show-current)
		version="$OPTARG_SUBCMD"
		if [[ $OPTARG_SUBCMD == "jump" || $OPTARG_SUBCMD == "goto" ]]; then
			if [[ $OPTARG_BACKWARD_STEPS -gt $OPTARG_FORWARD_STEPS ]]; then
				FORWARD=0
				STEPS=$(($OPTARG_BACKWARD_STEPS-$OPTARG_FORWARD_STEPS))
				xper_goto_rel.sh "$FLAG_GLOBAL" "$FLAG_WRAP" "$FORWARD" "$STEPS" "$OPTARG_USER" "$FLAG_FIRST" "$FLAG_LAST" "$FLAG_SORT" "$FLAG_CTIME" "$FLAG_MTIME"
			else
				FORWARD=1
				STEPS=$(($OPTARG_FORWARD_STEPS-$OPTARG_BACKWARD_STEPS))
				xper_goto_rel.sh "$FLAG_GLOBAL" "$FLAG_WRAP" "$FORWARD" "$STEPS" "$OPTARG_USER" "$FLAG_FIRST" "$FLAG_LAST" "$FLAG_SORT" "$FLAG_CTIME" "$FLAG_MTIME"
			fi
			version=$(git branch --show-current)
			version_num=$(echo $current_version | rev | cut -d '_' -f 1 | rev)
			version_user=$(echo $current_version | rev | cut -d '_' -f 2 | rev)
			xper.sh jump "$version_num" -u "$version_user"
		fi
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
		xper_sort.sh "$OPTARG_SORTBY" "$FLAG_GLOBAL" "$OPTARG_USER" "$FLAG_ONLYLEAF" "$FLAG_YES" "$FLAG_CTIME" "$FLAG_MTIME"
		;;
	index)
		xper_index.sh "$FLAG_CLEAR" "$FLAG_ADD" "$FLAG_REMOVE" "$OPTARG_VERSION_SOURCE" "$FLAG_AFTER" "$FLAG_BEFORE" "$FLAG_SWAP" "$OPTARG_VERSION_TARGET"
		;;
	broadcast)
		xper_broadcast.sh "$OPTARG_FILEPATH" "$OPTARG_VERSIONS" "$FLAG_GLOBAL" "$OPTARG_USER"
		;;
	run)
		xper_run.sh "$OPTARG_SUBCMD" "$OPTARG_VERSIONS" "$FLAG_GLOBAL" "$OPTARG_USER" "$OPTARG_WORKERS" "$OPTARG_OUTPUT_DIR" "$FLAG_CLEAR"
		;;
	clean)
		xper_clean.sh
		;;
	*)
		print_help
		;;
esac
