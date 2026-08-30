#!/bin/bash
# usage: xper_init FLAG_SCRATCH STR_TAG FLAG_YES

SCRATCH=$1
TAG=$2
YES=$3

USERNAME=$(xper_user.sh)
OWNER=$(xper_owner.sh)
CURRENT_VERSION=$(xper_version.sh 1)
PARENT_VERSION=$(xper.sh parent)
ROOT_DIR=$(xper_rootdir.sh)

PROJ_DIR=$ROOT_DIR
INDEX_FP="$ROOT_DIR/.git/refs/index"

echo "scratch=$SCRATCH tag=$TAG yes=$YES"
echo "username is $USERNAME"
echo "current version is $CURRENT_VERSION"
echo "parent version is $PARENT_VERSION"

# version_distance v1 v2
version_distance(){
	IFS='.' read -r -a v1 <<< "$1"
	IFS='.' read -r -a v2 <<< "$1"

	local max_len=${#v1[@]}
	[[ ${#v2[@]} -gt $max_len ]] && max_len=${#v2[@]}

	local dist=()

	for ((i=0; i<$max_len; ++i)); do
		a=${v1[i]:-0}
		b=${v2[i]:-0}
		diff=$((a-b))

		[[ $diff -lt 0 ]] && diff=$((-diff))
		result+=("$diff")
	done

	IFS='.'; echo "${result[*]}"
}

pick_new_version(){
	local version_target=()
	IFS='.' read -r -a version_target <<< "$1"
	# local version_target="$1"
	local user_versions=$(git branch --list "$USERNAME*")
	local current_version=""
	local prev_version=""

	# echo "version_target=${version_target[@]}"
	# echo "user_versions=${user_versions}"
	for ((i=0; i<${#version_target[@]}; ++i)); do
		current_version+="${version_target[i]}"
		user_versions=$(echo $user_versions | grep -oE "${USERNAME}_v${current_version}(\.[0-9]+)*")
		# echo current_version=$current_version
		# echo user_versions=$user_versions
		if [[ ${#user_versions} -eq 0 ]]; then
			# echo current_version=$current_version
			break
		fi
		prev_version=$current_version
		current_version+="."
	done

	local last_child=$(git branch --list "${USERNAME}_v*" | grep -E ".+v${prev_version}\..*" | grep -vE ".+v${prev_version}\..+\..+" | sort -V | tail -1 | rev | cut -d '.' -f 1 | rev)
	# echo last_child=$last_child
	local next_child=$((last_child+1))
	echo $prev_version.$next_child
}

new_from_scratch(){
	git checkout $USERNAME
	CHILDREN=$(git branch --list "${USERNAME}_v*" | grep -vE ".+v[0-9]+\..*" | sed -E "s/.+_v([0-9]+)/\1/g" | sort -n | tail -1)
	echo "${USERNAME}'s last children = $CHILDREN"
	git checkout -b ${USERNAME}_v$((CHILDREN+1))
	git commit --allow-empty -m "Initial placeholder commit"
	xper.sh sort
};

new_from_current(){
	if [[ $CURRENT_VERSION == $USERNAME* ]]; then

		CHILDREN=$(git branch --list "$CURRENT_VERSION.*" | grep -vE "$CURRENT_VERSION\..*\..*" | sed -E "s/${CURRENT_VERSION}\.([0-9]+)/\1/g" | sort -n | tail -1)
		echo "current last children = $CHILDREN"
		git checkout -b ${CURRENT_VERSION}.$((CHILDREN+1))
		xper_ctx.sh reference "${CURRENT_VERSION}"
		xper_save.sh "[as initial placeholder commit]"
		xper.sh sort
	else
		# echo owner!=user
		local owner_version=$(xper_version.sh 0)
		# echo owner_version=$owner_version
		# echo finding new version...
		# pick_new_version $owner_version
		local new_version=$(pick_new_version "$owner_version")
		echo "new version = $new_version"
		git checkout -b ${USERNAME}_v${new_version}
		xper_ctx.sh reference "${CURRENT_VERSION}"
		xper_save.sh "[as initial placeholder commit]"
		xper.sh sort
	fi
};

xper_save.sh "before branching"
diff=$(xper_diff.sh $PARENT_VERSION)
# echo diff=$diff

if [[ $SCRATCH -eq 1 || $PARENT_VERSION == "" ]]; then
	new_from_scratch
	sed "s/tag=.*/tag=$TAG/g" .xper > .xper.tmp && mv .xper.tmp .xper
elif [[ $diff != "" || $YES -eq 1 || $OWNER != $USERNAME ]]; then
	new_from_current
	sed "s/tag=.*/tag=$TAG/g" .xper > .xper.tmp && mv .xper.tmp .xper
else
	echo "[xper_new] did not create a new version"
fi
