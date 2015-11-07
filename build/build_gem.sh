#!/bin/bash

# Make output directory
if [ ! -d output ]; then
	mkdir output
fi

# geminabox url
gem_in_a_box_url="http://corptprepo02:8080/"

# Install gem in a box
gem install geminabox

# Install bump to bump the version
gem install bump

# Add corptprepo02 to gem sources
gem sources -a "$gem_in_a_box_url"

# Get root directory
root_dir=$(git rev-parse --show-toplevel)
pushd "$root_dir"
# Bump version
bump patch

# Build gem
gem build *.gemspec

# Copy gem to output folder
cp *.gem build/output/

# Push gem to gem in a box
gem inabox *.gem -g "$gem_in_a_box_url"

if [ $? -eq 0 ]; then
    git push
else
    git reset --hard
fi

popd
