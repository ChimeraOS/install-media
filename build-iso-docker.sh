#!/bin/bash

if [ $EUID -ne 0 ]; then
	echo "$(basename $0) must be run as root"
	exit 1
fi

# get the directory of this script
work_dir="$(realpath $0|rev|cut -d '/' -f2-|rev)"

# configuration variables for the iso
dockerfile="${work_dir}/docker/Dockerfile"

# build the docker container
docker build -f "${dockerfile}" -t gameros-builder ${work_dir}

# make the container build the iso
exec docker run --privileged --rm -ti -v ${work_dir}:/root/gameros -h gameros-builder gameros-builder ./build-iso.sh