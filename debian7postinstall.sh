#!/bin/bash
# Script post-installation pour Debian 7 (Wheezy)
#
# Benoit Ponthieu / Fabrik4Web SAS - 06/2013

######################
# Variables Globales #
######################

HOME_PATH=`grep $USERNAME /etc/passwd | cut -d: -f6`
APT_GET="apt-get -q -y --force-yes"
WGET="wget -m --no-check-certificate"
DATE=`date +"%Y-%m-%d%_H%M%S"`
LOG_FILE="/tmp/debian7postinstall-$DATE.log"

#################
# Configuration #
#################

KERNEL_VERSION="3.8.13"
KERNEL_URL="https://github.com/fabrik4web/debian-post-install/blob/master/kernel"
CONFIG_URL="https://github.com/fabrik4web/debian-post-install/blob/master/config"

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
  echo -n "[En cours] $message"
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

# Création du fichier de log
#---------------------------

echo "Debut du script" > $LOG_FILE

# On teste si le script est bien exécuter en tant que root
#---------------------------------------------------------

if [ $EUID -ne 0 ]; then
  showerrorandexit 1 "Le script doit être lancé en root !"
fi

# Configuration pour pouvoir envoyer des mails lors de l'installation
#--------------------------------------------------------------------

showtxt ""
showtxt "#########################################################################"
showtxt "## Configuration pour pouvoir envoyer des mails lors de l'installation ##"
showtxt "#########################################################################"
showtxt ""

showandexec "Téléchargement et mise en place du fichier update-exim4.conf.conf" "$WGET -O /etc/exim4/update-exim4.conf $CONFIG_URL/update-exim4.conf"
showandexec "Redémarrage d'exim4" "/etc/initd.d/exim4 restart"

# Gestion des dépots et mise à jour
#----------------------------------

showtxt ""
showtxt "#######################################"
showtxt "## Gestion des dépots et mise à jour ##"
showtxt "#######################################"
showtxt ""

showandexec "Téléchargement et mise en place du fichier sources.list" "$WGET -O /etc/apt/sources.list $CONFIG_URL/sources.list"
showandexec "Installation clés du dépôt Dotdeb" "$WGET -O - http://www.dotdeb.org/dotdeb.gpg | apt-key add -"
showandexec "Mise à jour de la liste des dépots" "$APT_GET update"
showandexec "Mise à jour des logiciels" "$APT_GET upgrade"

# Fini :)
#--------

echo "Fin du script" >> $LOG_FILE