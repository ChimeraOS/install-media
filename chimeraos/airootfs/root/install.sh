#! /bin/bash

clean_progress() {
        local scale=$1
        local postfix=$2
        local last_value=$scale
        while IFS= read -r line; do
                value=$(( ${line}*${scale}/100 ))
                if [ "$last_value" != "$value" ]; then
                        echo ${value}${postfix}
                        last_value=$value
                fi
        done
}

poll_gamepad() {
        modprobe xpad > /dev/null
        systemctl start inputplumber > /dev/null

        while true; do
                sleep 1
                busctl call org.shadowblip.InputPlumber \
                        /org/shadowblip/InputPlumber/CompositeDevice0 \
                        org.shadowblip.Input.CompositeDevice \
                        LoadProfilePath "s" /root/gamepad_profile.yaml &> /dev/null
                if [ $? == 0 ]; then
                        break
                fi
        done
}

get_boot_disk() {
        local current_boot_id=$(efibootmgr | grep BootCurrent | head -1 | cut -d':' -f 2 | tr -d ' ')
        local boot_disk_info=$(efibootmgr | grep "Boot${current_boot_id}" | head -1)
        local part_uuid=$(echo $boot_disk_info | tr "/" "\n" | grep "HD(" | cut -d',' -f3 | head -1 | sed -e 's/^0x//')

        if [ -z $part_uuid ]; then
                # prevent printing errors when the boot disk info is not in a known format
                return
        fi

        local part=$(blkid | grep $part_uuid | cut -d':' -f1 | head -1 | sed -e 's,/dev/,,')
        local part_path=$(readlink "/sys/class/block/$part")
        basename `dirname $part_path`
}

is_disk_external() {
        local disk=$1     # the disk to check if it is external
        local external=$(lsblk --list -n -o name,hotplug | grep "$disk " | cut -d' ' -f2- | xargs echo -n)

        test "$external" == "1"
}

is_disk_smaller_than() {
        local disk=$1     # the disk to check the size of
        local min_size=$2 # minimum size in GB
        local size=$(lsblk --list -n -o name,size | grep "$disk " | cut -d' ' -f2- | xargs echo -n)

        if echo $size | grep "T$" &> /dev/null; then
                return 1
        fi

        if echo $size | grep "G$" &> /dev/null; then
                size=$(echo $size | sed 's/G//' | cut -d'.' -f1)
                if [ "$size" -lt "$min_size" ]; then
                        return 0
                else
                        return 1
                fi
        fi

        return 0
}

get_disk_model_override() {
        local device=$1
        grep "${DEVICE_VENDOR}:${DEVICE_PRODUCT}:${DEVICE_CPU}:${device}" overrides | cut -f2- | xargs echo -n
}

get_disk_human_description() {
        local name=$1
        local size=$(lsblk --list -n -o name,size | grep "$name " | cut -d' ' -f2- | xargs echo -n)

        if [ "$size" = "0B" ]; then
                return
        fi

        local model=$(get_disk_model_override $name | xargs echo -n)
        if [ -z "$model" ]; then
                model=$(lsblk --list -n -o name,model | grep "$name " | cut -d' ' -f2- | xargs echo -n)
        fi

        local vendor=$(lsblk --list -n -o name,vendor | grep "$name " | cut -d' ' -f2- | xargs echo -n)
        local transport=$(lsblk --list -n -o name,tran | grep "$name " | cut -d' ' -f2- | \
                sed -e 's/usb/USB/' | \
                sed -e 's/nvme/Internal/' | \
                sed -e 's/sata/Internal/' | \
                sed -e 's/ata/Internal/' | \
                sed -e 's/mmc/SD card/' | \
                xargs echo -n)
        echo "[${transport}] ${vendor} ${model:=Unknown model} ($size)" | xargs echo -n
}

cancel_install() {
    if (whiptail --yesno --yes-button "Power off" --no-button "Open command prompt" "Installation was cancelled. What would you like to do?" 10 70); then
        poweroff
    fi

    exit 1
}

select_disk() {
    while true
    do
            # a key/value store using an array
            # even number indexes are keys (starting at 0), odd number indexes are values
            # keys are the disk name without `/dev` e.g. sda, nvme0n1
            # values are the disk description
            device_list=()

            boot_disk=$(get_boot_disk)
            if [ -n "$boot_disk" ]; then
                    device_output=$(lsblk --list -n -o name,type | grep disk | grep -v zram | grep -v $boot_disk)
            else
                    device_output=$(lsblk --list -n -o name,type | grep disk | grep -v zram)
            fi

            while read -r line; do
                    name=$(echo "$line" | cut -d' ' -f1 | xargs echo -n)
                    description=$(get_disk_human_description $name)
                    if [ -z "$description" ]; then
                            continue
                    fi
                    device_list+=($name)
                    device_list+=("$description")
            done <<< "$device_output"

            # NOTE: each disk entry consists of 2 elements in the array (disk name & disk description)
            if [ "${#device_list[@]}" -gt 2 ]; then
                    export DISK=$(whiptail --nocancel --menu "Choose a disk to install $OS_NAME on:" 20 70 5 "${device_list[@]}" 3>&1 1>&2 2>&3)
            elif [ "${#device_list[@]}" -eq 2 ]; then
                    # skip selection menu if only a single disk is available to choose from
                    export DISK=${device_list[0]}
            else
                    whiptail --msgbox "Could not find a disk to install to.\n\nPlease connect a 64 GB or larger disk and start the installer again." 12 70
                    cancel_install
            fi

            export DISK_DESC=$(get_disk_human_description $DISK)

            if is_disk_smaller_than $DISK $MIN_DISK_SIZE; then
                    if (whiptail --yesno --yes-button "Select a different disk" --no-button "Cancel install" \
                            "ERROR: The selected disk $DISK - $DISK_DESC is too small. $OS_NAME requires at least $MIN_DISK_SIZE GB.\n\nPlease select a different disk." 12 75); then
                            continue
                    else
                            cancel_install
                    fi
            fi

            if is_disk_external $DISK; then
                    if (whiptail --yesno --defaultno --yes-button "Install anyway" --no-button "Select a different disk" \
                            "WARNING: $DISK - $DISK_DESC appears to be an external disk. Installing $OS_NAME to an external disk is not officially supported and may result in poor performance and permanent damage to the disk.\n\nDo you wish to install anyway?" 12 80); then
                            break
                    else
                            # Unlikely that we would ever have ONLY an external disk, so this should be good enough
                            continue
                    fi
            fi

            break
    done
}




if [ $EUID -ne 0 ]; then
    echo "$(basename $0) must be run as root"
    exit 1
fi


OS_NAME=ChimeraOS
MIN_DISK_SIZE=55 # GB

DEVICE_VENDOR=$(cat /sys/devices/virtual/dmi/id/sys_vendor)
DEVICE_PRODUCT=$(cat /sys/devices/virtual/dmi/id/product_name)
DEVICE_CPU=$(lscpu | grep Vendor | cut -d':' -f2 | xargs echo -n)



dmesg --console-level 1



# start polling for a gamepad
poll_gamepad &


# try to set correct date & time -- required to be able to connect to github via https if your hardware clock is set too far into the past
timedatectl set-ntp true


#### Test connection or ask the user for configuration ####

# Waiting a bit because some wifi chips are slow to scan 5GHZ networks
echo "Starting installer..."
sleep 2

TARGET="stable"
while ! ( curl --http1.1 -Ls https://github.com | grep '<html' > /dev/null ); do
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

MOUNT_PATH=/tmp/frzr_root

# sets DISK and DISK_DESC
select_disk

# warn before erasing disk
if ! (whiptail --yesno --defaultno --yes-button "Erase disk and install" --no-button "Cancel install" "\
WARNING: $OS_NAME will now be installed and all data on the following disk will be lost:\n\n\
        $DISK - $DISK_DESC\n\n\
Do you wish to proceed?" 15 70); then
        cancel_install
fi

export SHOW_UI=1
export FRZR_INSTALLER=1
export MOUNT_PATH="/tmp/frzr_root"
export EFI_MOUNT_PATH="/tmp/frzr_root/efi"
export SWAP_GIB=0
export SYSTEMD_RELAX_ESP_CHECKS=1

# perform bootstrap of disk
frzr bootstrap gamer /dev/${DISK}
RESULT=$?
if [ "${RESULT}" != "0" ]; then
    whiptail --msgbox "System bootstrap step failed." 10 50
    cancel_install
fi

#### Post install steps for system configuration
# Copy over all network configuration from the live session to the system
SYS_CONN_DIR="/etc/NetworkManager/system-connections"
if [ -d ${SYS_CONN_DIR} ] && [ -n "$(ls -A ${SYS_CONN_DIR})" ]; then
    mkdir -p -m=700 ${MOUNT_PATH}${SYS_CONN_DIR}
    cp  ${SYS_CONN_DIR}/* \
        ${MOUNT_PATH}${SYS_CONN_DIR}/.
fi

frzr deploy chimeraos/chimeraos:${TARGET}
RESULT=$?

MSG="Installation failed."
if [ "${RESULT}" == "0" ]; then
    MSG="Installation successfully completed."
elif [ "${RESULT}" == "29" ]; then
    MSG="GitHub API rate limit error encountered. Please retry installation later."
fi

if (whiptail --yesno --yes-button "Reboot" --no-button "Open command prompt" "${MSG}" 10 70); then
    reboot
fi

exit ${RESULT}
