#!/usr/bin/env bash
# usage: xper_refchildren.sh

VERSION=$(xper_version.sh 1)

versions=($(git branch --format '%(refname:short)'))
children=()

for version in ${versions[@]}; do
	version_number=$(echo $version | rev | cut -d '_' -f 1 | rev)
	version_owner=$(echo $version | rev | cut -d '_' -f 2- | rev)
	xper.sh jump $version_number -u $version_owner
	reference=$(xper_ctx.sh reference)

	if [[ $reference == $VERSION ]]; then
		children+=(${version})
	fi
done

version_number=$(echo $VERSION | rev | cut -d '_' -f 1 | rev)
version_owner=$(echo $VERSION | rev | cut -d '_' -f 2- | rev)
xper.sh jump $version_number -u $version_owner

echo ${children[@]} | xargs printf "%s\n"
