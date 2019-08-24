#!/bin/bash

# configuration variables for the iso
output_dir="output"
script_dir="gameros"
repo_dir="packages"

# get the directory of this script
work_dir="$(realpath $0|rev|cut -d '/' -f2-|rev)"

# create output directory if it doesn't exist yet
mkdir -p ${work_dir}/${output_dir}

sed -i "s?Server = localrepo?Server = file://${work_dir}/${repo_dir}?" ${work_dir}/${script_dir}/pacman.conf

# change working directory
cd ${work_dir}/${script_dir}

# make the container build the iso
exec ./build.sh -v -o ${work_dir}/${output_dir}
