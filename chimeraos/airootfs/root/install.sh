#! /bin/bash

if [ $EUID -ne 0 ]; then
    echo "$(basename $0) must be run as root"
    exit 1
fi

dmesg --console-level 1

#### Test conenction or ask the user for configuration ####

# Waiting a bit because some wifi chips are slow to scan 5GHZ networks
sleep 2

while ! ( curl -Ls https://github.com | grep '<html' > /dev/null ); do
    whiptail \
     "No internet connection detected.\n\nPlease use the network configuration tool to activate a network, then select \"Quit\" to exit the tool and continue the installation." \
     12 50 \
     --yesno \
     --yes-button "Configure" \
     --no-button "Exit"

    if [ $? -ne 0 ]; then
         exit 1
    fi

    nmtui-connect
done
#######################################

if ! frzr-bootstrap gamer; then
    whiptail --msgbox "System bootstrap step failed." 10 50
    exit 1
fi

#### Post install steps for system configuration
# Copy over all network configuration from the live session to the system
MOUNT_PATH=/tmp/frzr_root
SYS_CONN_DIR="/etc/NetworkManager/system-connections"
if [ -d ${SYS_CONN_DIR} ] && [ -n "$(ls -A ${SYS_CONN_DIR})" ]; then
    mkdir -p -m=700 ${MOUNT_PATH}${SYS_CONN_DIR}
    cp  ${SYS_CONN_DIR}/* \
        ${MOUNT_PATH}${SYS_CONN_DIR}/.
fi

export SHOW_UI=1

if ( ls -1 /dev/disk/by-label | grep -q CHIMERA_UPDATE ); then

CHOICE=$(whiptail --menu "How would you like to install ChimeraOS?" 18 50 10 \
  "local" "Use local media for installation." \
  "Online" "Fetch the latest stable image." \
   3>&1 1>&2 2>&3)
fi

if [ ${CHOICE} == local ]; then
    export local_install=true
    frzr-deploy
    RESULT=$?
else
    frzr-deploy chimeraos/chimeraos:stable
    RESULT=$?
fi

MSG="Installation failed."
if [ "${RESULT}" == "0" ]; then
    MSG="Installation successfully completed."
elif [ "${RESULT}" == "29" ]; then
    MSG="GitHub API rate limit error encountered. Please retry installation later."
fi

if (whiptail --yesno "${MSG}\n\nWould you like to restart the computer?" 10 50); then
    reboot
fi

exit ${RESULT}
