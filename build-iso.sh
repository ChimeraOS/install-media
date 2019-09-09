#!/bin/bash

if [ $EUID -ne 0 ]; then
	echo "$(basename $0) must be run as root"
	exit 1
fi

# configuration variables for the iso
output_dir="output"
script_dir="gameros"

# get the directory of this script
work_dir="$(realpath $0|rev|cut -d '/' -f2-|rev)"

# create output directory if it doesn't exist yet
mkdir -p ${work_dir}/${output_dir}

# change working directory
cd ${work_dir}/${script_dir}

# make the container build the iso
exec ./build.sh -v -o ${work_dir}/${output_dir}
