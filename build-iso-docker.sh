#!/bin/bash

# get the directory of this script
work_dir="$(realpath $0|rev|cut -d '/' -f2-|rev)"

# configuration variables for the iso
dockerfile="${work_dir}/docker/Dockerfile"

# build the docker container
docker build -f "${dockerfile}" -t chimera-install-builder ${work_dir}

# make the container build the iso
exec docker run --privileged --rm -v ${work_dir}:/root/chimeraos -h chimera-install-builder chimera-install-builder ./build-iso.sh
