#!/bin/bash

if [ $EUID -ne 0 ]; then
	echo "$(basename $0) must be run as root"
	exit 1
fi

# get the directory of this script
work_dir="$(realpath $0|rev|cut -d '/' -f2-|rev)"

# configuration variables for the iso
output_dir="${work_dir}/output"
script_dir="${work_dir}/chimeraos"
temp_dir="${work_dir}/temp"

# create output directory if it doesn't exist yet
rm -rf "${output_dir}"
mkdir -p "${output_dir}"

rm -rf "${temp_dir}"
mkdir -p "${temp_dir}"

# add AUR packages to the build
AUR_PACKAGES="\
    frzr \
    rtl88x2bu-dkms-git \
    rtw89-dkms-git \
    r8152-dkms \
    rtl8812au-dkms-git \
    rtl8814au-dkms-git \
"

# create repo directory if it doesn't exist yet
LOCAL_REPO="${script_dir}/extra_pkg"
mkdir -p ${LOCAL_REPO}

PIKAUR_CMD="PKGDEST=/tmp/temp_repo pikaur --noconfirm -Sw ${AUR_PACKAGES}"
PIKAUR_RUN=(bash -c "${PIKAUR_CMD}")
if [ -n "${BUILD_USER}" ]; then
	PIKAUR_RUN=(su "${BUILD_USER}" -c "${PIKAUR_CMD}")
fi

# build packages to the repo
pushd /home/${BUILD_USER}
"${PIKAUR_RUN[@]}"
popd

# copy all built packages to the repo
cp /tmp/temp_repo/* ${LOCAL_REPO}

# Add the repo to the build
repo-add ${LOCAL_REPO}/chimeraos.db.tar.gz ${LOCAL_REPO}/*.pkg.*
sed "s|LOCAL_REPO|$LOCAL_REPO|g" $script_dir/pacman.conf.template > $script_dir/pacman.conf

# make the container build the iso
mkarchiso -v -w "${temp_dir}" -o "${output_dir}" "${script_dir}"

# allow git command to work
git config --global --add safe.directory "${work_dir}"

ISO_FILE_PATH=`ls ${output_dir}/*.iso`
ISO_FILE_NAME=`basename "${ISO_FILE_PATH}"`
VERSION=`echo "${ISO_FILE_NAME}" | cut -c11-20 | sed 's/\./-/g'`
ID=`git rev-parse --short HEAD`

pushd ${output_dir}
sha256sum ${ISO_FILE_NAME} > sha256sum.txt
cat sha256sum.txt
popd

echo "::set-output name=iso_file_name::${ISO_FILE_NAME}"
echo "::set-output name=version::${VERSION}"
echo "::set-output name=id::${ID}"
