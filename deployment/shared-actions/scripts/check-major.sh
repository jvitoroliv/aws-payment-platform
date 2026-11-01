#!/bin/bash

# check-major.sh
# check-major shell script

new_tag=$1
current_tag=$2

new_major_version=$(echo "${new_tag##*-}" | cut -d '.' -f 1)
current_major_version=$(echo "${current_tag##*-}" | cut -d '.' -f 1)
echo "New major version: $new_major_version"
echo "Current major version: $current_major_version"

# Initial release of workflow, always create a major version
if [[ $new_tag && $current_tag == "1.0.0" ]]; then
	echo "This is an inital release - major version update."
	echo "is_major=true" >>"$GITHUB_OUTPUT"
elif [[ $new_major_version > $current_major_version ]]; then
	echo "This is a major version update."
	echo "is_major=true" >>"$GITHUB_OUTPUT"
else
	echo "This is not a major version update."
	echo "is_major=false" >>"$GITHUB_OUTPUT"
fi
echo "new_major_version=${new_major_version}" >>"$GITHUB_OUTPUT"
echo "current_major_version=${current_major_version}" >>"$GITHUB_OUTPUT"
