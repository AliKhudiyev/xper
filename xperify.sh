#!/usr/bin/env bash
# usage: xperify.sh

ROOT_DIR=$(git rev-parse --show-toplevel)
GIT_REPO=$(git remote)

if [[ $ROOT_DIR == "" ]]; then
	echo "[xperify] git directory not found"
	exit 1
else
	echo "[xperify]"
	branches=($(git branch --list "*" --format='%(refname:short)'))
	branch_count=${#branches[@]}

	echo "[xperify] there are $branch_count branches:"
	for ((i=0; i<$branch_count; ++i)); do
		echo "  $i: ${branches[i]}"
	done

	read -p "[xperify] would you like to rename all the branches? [y/n] " ans
	if [[ $ans == 'y' || $ans == 'Y' ]]; then
		username=$(git config --local user.name | tr -d ' ')

		if [[ $username == "" ]]; then
			username=$(git config --global user.name | tr -d ' ')
			if [[ $username == "" ]]; then
				echo "[xperify] you need to set up a git username"
				exit 1
			fi

			read -p "[xperify] would you like to use your global git username $username? [y/n] " ans

			if [[ $ans != 'y' && $ans != 'Y' ]]; then
				exit 0
			fi
		fi

		read -p "what is the index of the root branch? [0, ${branch_count}) " root_branch_index

		if [[ $root_branch_index -ge $branch_count || $root_branch_index -lt 0 ]]; then
			echo "[xperify] invalid index for the root branch"
			exit 1
		fi

		root_branch=${branches[root_branch_index]}
		output=$(python3 ~/Desktop/Projects/xper/branch_parents.py --root "$root_branch" | grep -v "$root_branch::")
		echo "[xperify] root branch is [$root_branch]"

		echo output
		echo $output
		for ((i=0; i<$branch_count; ++i)); do
			branch_old=${branches[i]}

			if [[ $branch_old != $root_branch ]]; then
				branch_version=$(echo $output | sed -E "s/(.+):(.+):(.+)/\3/g")
				echo branch_version=$branch_version
				branch="${username}_v${branch_version}"
				parent_version=$(echo $version | rev | cut -d '.' -f 2- | rev)
				parent="${username}_v${parent_version}"
			else
				branch=$username
				parent=""
			fi

			git branch -m $branch_old $branch
			echo "[xperify] renamed $branch_old to ${branch}"

			if [[ $GIT_REPO != "" ]]; then
				echo "[xperify] pushing updates to remote repo..."
				git push origin -u $branch
				git push origin --delete $branch_old
			fi

			git checkout $branch
			printf "user=$username\nmode=normal\nlocked=0\ntag=\n" > .xper
			printf "log=\nowner=$username\nreference=$parent\n" >> .xper
			printf "finished=0\n" >> .xper
			printf ".heads\n.heads_filtered\n.index\n" >> .gitignore
		done
	else
		echo "[xperify] operation canceled"
	fi
fi
