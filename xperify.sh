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

		output=($(python3 ~/Desktop/Projects/xper/branch_parents.py --root "$root_branch"))
		curr_branch=$(git branch --show-current)

		for branch in ${branches[@]}; do
			if ! echo $output | cut -d ':' -f 2 | xargs printf "%s\n" | grep -wq "$branch"; then
				if [[ $branch == $curr_branch ]]; then
					other_branches=($(echo $branches | xargs printf "%s\n" | grep -v $curr_branch))
					git checkout ${other_branches[0]}
				fi
				git branch -D ${branch}
			fi
		done

		branches=($(git branch --format '%(refname:short)'))
		# echo pre haha branches=${branches[@]}

		for branch in ${branches[@]}; do
			# tmp_branch="__${branch}__"
			# echo haha $(git branch --format '%(refname:short)')
			# echo "renaming $branch to __${branch}__ temporarily..."
			git branch -m $branch __${branch}__
		done

		for line in ${output[@]}; do
			branch="v$(echo $line | cut -d ':' -f 1)"
			branch_name=$(echo $line | cut -d ':' -f 2)
			branch_parent="v$(echo $line | cut -d ':' -f 3)"
			branch_hash="$(echo $line | cut -d ':' -f 5)"

			echo "(hash=$branch_hash) branch=$branch name=$branch_name parent=$branch_parent"

			if git branch --format '%(refname:short)' | grep -wq "__${branch_name}__"; then
				git branch -m __${branch_name}__ $branch
				echo "[xperify] renamed $branch_name to ${branch}"
			else
				git checkout -b $branch $branch_hash
				echo "[xperify] created a new branch $branch"
			fi

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
			git add $ROOT_DIR && git commit -m 'xper updated .gitignore'
		done
	else
		echo "[xperify] operation canceled"
	fi
fi
