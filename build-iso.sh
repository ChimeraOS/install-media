#!/bin/bash

if [ $EUID -ne 0 ]; then
	echo "$(basename $0) must be run as root"
	exit 1
fi

# get the directory of this script
work_dir="$(realpath $0|rev|cut -d '/' -f2-|rev)"

# configuration variables for the iso
output_dir="${work_dir}/output"
script_dir="${work_dir}/gameros"
temp_dir="${work_dir}/temp"

# create output directory if it doesn't exist yet
mkdir -p "${output_dir}"

rm -rf "${temp_dir}"
mkdir -p "${temp_dir}"

# make the container build the iso
exec mkarchiso -v -w "${temp_dir}" -o "${output_dir}" "${script_dir}"
