#!/bin/bash
# usage: xper_init FLAG_SCRATCH STR_TAG FLAG_YES

SCRATCH=$1
TAG=$2
YES=$3

USERNAME=$(xper_user.sh)
CURRENT_VERSION=$(xper_version.sh 1)
PARENT_VERSION=$(xper.sh parent)
PROJ_DIR=$(xper_rootdir.sh)

BASE=${USERNAME}

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
	IFS='.' read -r -a version_target <<< "$1"
	IFS='.' read -r -a version_prev <<< "$1"
	IFS='.' read -r -a version_next <<< "$1"

	dist_prev=$(version_distance $version_target $version_prev)
	dist_next=$(version_distance $version_target $version_next)

	if [[ $dist_prev < $dist_next ]]; then
		;
	else
		;
	fi
}

new_from_scratch(){
	git checkout $BASE
	CHILDREN=$(git branch --list "*v*" | grep -vE ".+v[0-9]+\..*" | sed -E "s/.+_v([0-9]+)/\1/g" | sort -n | tail -1)
	echo "${BASE}'s last children = $CHILDREN"
	git checkout -b ${BASE}_v$((CHILDREN+1))
	git commit --allow-empty -m "Initial placeholder commit"
	xper.sh sort
};

new_from_current(){
	if [[ $CURRENT_VERSION == $USERNAME* ]]; then

		CHILDREN=$(git branch --list "$CURRENT_VERSION.*" | grep -vE "$CURRENT_VERSION\..*\..*" | sed -E "s/${CURRENT_VERSION}\.([0-9]+)/\1/g" | sort -n | tail -1)
		echo "current last children = $CHILDREN"
		git checkout -b ${CURRENT_VERSION}.$((CHILDREN+1))
		git commit --allow-empty -m "[as initial placeholder commit]"
		xper.sh sort
	else
		local owner_version=$(xper_version.sh 0)
		local user_versions=($(ls $PROJ_DIR/.git/refs/heads | grep "$USERNAME*" | rev | cut -d 'v' -f 1 -s | rev))

		version_prev=0
		for ((i=1; i<${#user_versions[@]}; ++i)); do
			local user_version=${user_versions[i]}
			if [[ $user_version > $owner_version ]]; then
				new_version=$(pick_new_version $owner_version $version_prev $user_version)
				git checkout -b ${USERNAME}_v${new_version}
				git commit --allow-empty -m "[as initial placehold commit]"
				xper.sort
				break
			fi
			version_prev=$user_version
		done
	fi
};

xper_save.sh "before branching"
diff=$(xper_diff.sh $PARENT_VERSION)
# echo diff=$diff

if [[ $SCRATCH -eq 1 || $PARENT_VERSION == "" ]]; then
	new_from_scratch
	sed "s/tag=.*/tag=$TAG/g" .xper > .xper.tmp && mv .xper.tmp .xper
elif [[ $diff != "" || $YES -eq 1 ]]; then
	new_from_current
	sed "s/tag=.*/tag=$TAG/g" .xper > .xper.tmp && mv .xper.tmp .xper
else
	echo "[xper_new] did not create a new version"
fi
