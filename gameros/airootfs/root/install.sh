#! /bin/bash


if [ $EUID -ne 0 ]; then
	echo "$(basename $0) must be run as root"
	exit 1
fi

#### Internet connection detection ####
dhcpcd --background

whiptail --infobox "Checking connection..." 10 50
sleep 5

while ! ( curl -Is https://gamer-os.github.io/ | head -1 | grep 200 > /dev/null ); do
	whiptail --yesno "No internet connection detected. Please connect this computer\
	 to the internet with a wired connection, wait a few seconds, then retry." 10 50\
	 --yes-button "Retry"\
	 --no-button "Exit"

	if [ $? -ne 0 ]; then
		 exit 1
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
