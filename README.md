# install-media
Build the GamerOS installation media.

## How to build
There are two methods of building the installation media for GamerOS. From an Arch based system or from a Docker container.

### Arch based systems
On Arch the following packages will need to be installed:
- archiso
- grep
- file
- coreutils
- pikaur

To start building, use the following command:

```bash
./build-iso.sh
```

### Docker
Before being able to build with Docker, the following packages will need to be installed:
- docker.io
- coreutils

To start building, use the following command:

```bash
./build-iso-docker.sh
```

## Files and directories
Here a short explaination of what which files and directories do.

### gameros
Contains the modified archiso profile for GamerOS.

### gameros/pacman.conf
The pacman configuration during the creation of the installation media. Repositories can be added here.

### gameros/packages.x86_64
A list of packages which are installed on the installation media during creation.

### gameros/airootfs
Files which are added to the filesystem of the installation media's root file system.

### gameros/airootfs/root/customize_airootfs.sh
This script runs in the live enviroment before it is put on the installation media. Allowing configuration changes.

### docker/Dockerfile
This file is the base for the docker container which is used
