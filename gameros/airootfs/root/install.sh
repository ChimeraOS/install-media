#! /bin/bash


if [ $EUID -ne 0 ]; then
	echo "$(basename $0) must be run as root"
	exit 1
fi

whiptail --infobox "Checking connection..." 10 50
sleep 5

while ! ( curl -Is https://gamer-os.github.io/ | head -1 | grep 200 > /dev/null ); do
	whiptail --infobox "Checking for wifi..." 10 50
	if [ ! -z "$(nmcli device wifi list --rescan yes)" ]; then
		unset networks
		declare -a networks
		for network in $(nmcli device wifi list| sed '/^IN-USE/d' | awk '{print $1 "\t" $2}'| sed '/--/d;/\*/d'); do
			networks+=($network)
		done
		if [ ! ${#networks[@]} -eq 0 ]; then
			WIFI=$(whiptail --nocancel --menu "Choose wifi network:" 20 50 $(((${#networks[@]})/2)) "${networks[@]}" 3>&1 1>&2 2>&3)
			PASSWORD=$(whiptail --passwordbox "Wifi password:" 20 50  3>&1 1>&2 2>&3)
			nmcli device wifi connect "${WIFI}" password "${PASSWORD}"

			if [ $? -ne 0 ]; then
				whiptail --yesno "Couldn't connect to wifi." 10 50\
				--yes-button "Retry"\
				--no-button "Exit"

				if [ $? -ne 0 ]; then
					exit 1
				fi
			fi
		else
			whiptail --yesno "No wifi networks were found." 10 50\
			--yes-button "Retry"\
			--no-button "Exit"

			if [ $? -ne 0 ]; then
				exit 1
			fi
		fi

	else
		whiptail --yesno "No internet connection detected." 10 50\
		--yes-button "Retry"\
		--no-button "Exit"

		if [ $? -ne 0 ]; then
			exit 1
		fi
	fi
done
#######################################

#### Install frzr
curl -L https://github.com/gamer-os/frzr/releases/download/0.7.0/frzr-0.7.0-1-any.pkg.tar.zst > frzr.pkg.tar.zst
pacman --noconfirm -U frzr.pkg.tar.zst
if [ $? -ne 0 ]; then
	exit 1
fi
rm frzr.pkg.tar.zst

if ! frzr-bootstrap gamer; then
	exit
fi

export SHOW_UI=1
if ! frzr-deploy gamer-os/gamer-os:stable; then
	echo "Installation failed."
	exit
fi

if (whiptail --yesno "Installation complete. Would you like to restart now?" 10 50); then
	reboot
fi
