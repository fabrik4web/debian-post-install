#!/bin/bash
# Script post-install for Debian 7 (Wheezy)
#
# Benoit Ponthieu / Fabrik4Web SAS - 06/2013

####################
# Global Variables #
####################

HOME_PATH=`grep $USERNAME /etc/passwd | cut -d: -f6`
APT_GET="apt-get -q -y --force-yes"
WGET="wget -m --no-check-certificate"
DATE=`date +"%Y%m%d_%H%M%S"`
LOG_FILE="/tmp/debian7postinstall-$DATE.log"

#################
# Functions used in the script #
#################

KERNEL_VERSION="3.8.13"
KERNEL_URL="https://raw.github.com/fabrik4web/debian-post-install/master/kernel"
CONFIG_URL="https://raw.github.com/fabrik4web/debian-post-install/master/config"

######################################
# Fonctions utilisées dans le script #
######################################

showtxt() {
  echo "$*"
}

showerror() {
  showtxt "$*" >&2
}

showerrorandexit() {
  local exitcode=$1
  shift
  displayerror "$*"
  exit $exitcode
}

showandexec() {
  local message=$1
  echo -n "[In progress] $message"
  shift
  echo ">>> $*" >> $LOG_FILE 2>&1
  sh -c "$*" >> $LOG_FILE 2>&1
  local ret=$?
  if [ $ret -ne 0 ]; then
    echo -e "\r\e[0;31m   [ERROR]\e[0m $message"
  else
    echo -e "\r\e[0;32m      [OK]\e[0m $message"
  fi
  return $ret
}

##############
# Prrogramme #
##############

# Create log file
#----------------

echo "Start of the script" > $LOG_FILE

# It tests whether the script is running as root
#-----------------------------------------------

if [ $EUID -ne 0 ]; then
  showerrorandexit 1 "The script must be run as root"
fi

# Changing the kernel with a patched kernel GRSecurity
# ----------------------------------------------------

showtxt ""
showtxt "##########################################################"
showtxt "## Changing the kernel with a patched kernel GRSecurity ##"
showtxt "##########################################################"
showtxt ""

showandexec "Download and installation of the file System.map-$KERNEL_VERSION-xxxx-std-ipv6-64" "$WGET -O /boot/System.map-$KERNEL_VERSION-xxxx-std-ipv6-64 $KERNEL_URL/System.map-$KERNEL_VERSION-xxxx-std-ipv6-64"
showandexec "Download and installation of the file bzImage-$KERNEL_VERSION-xxxx-grs-ipv6-64" "$WGET -O /boot/bzImage-$KERNEL_VERSION-xxxx-grs-ipv6-64 $KERNEL_URL/bzImage-$KERNEL_VERSION-xxxx-grs-ipv6-64"
showandexec "Download and installation of the file 06_CustomKernel" "$WGET -O /etc/grub.d/06_CustomKernel $CONFIG_URL/06_CustomKernel"
showandexec "Application rights of the file 06_CustomeKernel" "chmod a+x /etc/grub.d/06_CustomKernel"
showandexec "Update grub" "update-grub"

# Configuring exim4 can post messages during installation
#--------------------------------------------------------

showtxt ""
showtxt "#############################################################"
showtxt "## Configuring exim4 can post messages during installation ##"
showtxt "#############################################################"
showtxt ""

showandexec "Download and installation of the file update-exim4.conf.conf" "$WGET -O /etc/exim4/update-exim4.conf $CONFIG_URL/update-exim4.conf.conf"
showandexec "Restart Exim4" "/etc/init.d/exim4 restart"

# Management repositories and update
#-----------------------------------

showtxt ""
showtxt "########################################"
showtxt "## Management repositories and update ##"
showtxt "########################################"
showtxt ""

showandexec "Download and installation of the file sources.list" "$WGET -O /etc/apt/sources.list $CONFIG_URL/sources.list"
showandexec "Installation of the key deposit Dotdeb" "$WGET -O - http://www.dotdeb.org/dotdeb.gpg | apt-key add -"
showandexec "Update the list of the deposits" "$APT_GET update"
showandexec "Updating software" "$APT_GET upgrade"

# The end :)
#-----------

echo "End of the script" >> $LOG_FILE
