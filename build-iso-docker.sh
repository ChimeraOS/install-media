#!/bin/bash

# configuration variables for the iso
dockerfile="docker/Dockerfile"
output_dir="output"
repo_dir="packages"

# get the directory of this script
work_dir="$(realpath $0|rev|cut -d '/' -f2-|rev)"

# create output directory if it doesn't exist yet
mkdir -p ${work_dir}/${output_dir}

sed -i "s?Server = localrepo?Server = file://${work_dir}/${repo_dir}?" ${work_dir}/${script_dir}/pacman.conf

# build the docker container
docker build -f ${work_dir}/${dockerfile} -t gameros-builder ${work_dir}

# make the container build the iso
exec docker run --privileged --rm -ti -v ${work_dir}/${output_dir}:/root/gameros/out -h gameros-builder gameros-builder ./build.sh -v
