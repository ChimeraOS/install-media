#! /bin/bash


if [ $EUID -ne 0 ]; then
    echo "$(basename $0) must be run as root"
    exit 1
fi

#### Test conenction or ask the user for configuration ####
while ! ( curl -LIs https://github.com | grep HTTP > /dev/null ); do
    whiptail --yesno "No wired connection detected. Please connect this computer \
     to the internet by configuring a new network." 10 50 \
     --yes-button "Configure" \
     --no-button "Exit"

    if [ $? -ne 0 ]; then
         exit 1
    fi

    nmtui-connect
done
#######################################

if ! frzr-bootstrap gamer; then
    exit 1
fi

#### Post install steps for system configuration
# Copy over all network configuration from the live session to the system
MOUNT_PATH=/tmp/frzr_root
SYS_CONN_DIR="/etc/NetworkManager/system-connections"
if [ -d $SYS_CONN_DIR && "$(ls -A $SYS_CONN_DIR)" ]; then
    mkdir -p -m=700 ${MOUNT_PATH}${SYS_CONN_DIR}
    cp  ${SYS_CONN_DIR}/* \
        ${MOUNT_PATH}${SYS_CONN_DIR}/.
fi

# Detect hybrid intel-nvidia setups
NVIDIA_BUSID=$(lspci -nm -d 10de: | \
    awk '{print $1 " " $2 " " $3}' | \
    grep -e 300 -e 302 | \
    awk '{print $1}' | \
    sed 's/\./:/' )
INTEL_BUSID=$(lspci -nm -d 8086: | \
    awk '{print $1 " " $2 " " $3}' | \
    grep -e 300 -e 302 | \
    awk '{print $1}' | \
    sed 's/\./:/' )

if [[ $INTEL_BUSID == ??:??:? && $NVIDIA_BUSID == ??:??:? ]] ; then
    if (whiptail --yesno "Intel/Nvidia hybrid graphics detected. Would you like to force use of Nvidia graphics?"); then
        echo "
Section \"ServerLayout\"
    Identifier \"layout\"
    Screen 0 \"iGPU\"
    Option \"AllowNVIDIAGPUScreens\"
EndSection

Section \"Screen\"
    Identifier \"iGPU\"
    Device \"iGPU\"
EndSection

Section \"Device\"
    Identifier \"iGPU\"
    Driver \"modesetting\"
    BusID \"${INTEL_BUSID}\"
EndSection

Section \"Device\"
    Identifier \"dGPU\"
    Driver \"nvidia\"
    BusID \"${NVIDIA_BUSID}\"
EndSection" > ${MOUNT_PATH}/etc/X11/xorg.conf.d/10-nvidia-prime.conf
    fi
fi

export SHOW_UI=1
if ! frzr-deploy chimeraos/chimeraos:stable; then
    echo "Installation failed."
    exit 1
fi

if (whiptail --yesno "Installation complete. Would you like to restart now?" 10 50); then
    reboot
fi
