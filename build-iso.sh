#!/bin/bash

if [ $EUID -ne 0 ]; then
	echo "$(basename $0) must be run as root"
	exit 1
fi

# configuration variables for the iso
output_dir="output"
script_dir="gameros"
repo_dir="packages"

# get the directory of this script
work_dir="$(realpath $0|rev|cut -d '/' -f2-|rev)"

# create output directory if it doesn't exist yet
mkdir -p ${work_dir}/${output_dir}

# add the local repo
sed -i "s?Server = localrepo?Server = file://${work_dir}/${repo_dir}?" ${work_dir}/${script_dir}/pacman.conf

# change working directory
cd ${work_dir}/${script_dir}

# remove the work directory used for the previous build
rm -rf work

# make the container build the iso
exec ./build.sh -v -o ${work_dir}/${output_dir}

# bring pacman.conf back in its original state
sed -i "s?Server = file://${work_dir}/${repo_dir}?Server = localrepo?" ${work_dir}/${script_dir}/pacman.conf
