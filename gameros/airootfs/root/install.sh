#! /bin/bash


if [ $EUID -ne 0 ]; then
	echo "$(basename $0) must be run as root"
	exit 1
fi

curl -Is http://www.google.com | head -1 | grep 200 > /dev/null;
if [ $? -ne 0 ]; then
	whiptail --msgbox "No internet connection detected. Please connect this computer to the internet with a wired connection before proceeding." 10 50
fi

if ! frzr-bootstrap gamer; then
	exit
fi

whiptail --msgbox "The system will now be downloaded and installed. This may take some time." 10 50

if ! frzr-deploy https://gamer-os.github.io/gamer-os/repos/default; then
	echo "Installation failed."
	exit
fi

if (whiptail --yesno "Installation complete. Would you like to restart now?" 10 50); then
	reboot
fi
