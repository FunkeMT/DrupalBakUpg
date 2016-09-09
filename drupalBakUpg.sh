#!/bin/bash

set -e

##################################
######         Drupal       ######
######  Backup and Upgrade  ######
######         Script       ######
######                      ######
###### @author Markus Funke ######
###### @date   2016-09-08   ######
##################################



### Configuration
homepage_url="www.homepage.de"

db_user=""
db_db=""
db_host=""
db_port="3306"

drupal_version="drupal-7.XX"

folder_backup="./backup"
folder_homepage="./homepage"



### Variables
bin_mysqldump="mysqldump"
bin_tar="tar"
bin_wget="wget"

now=$(date '+%Y%m%dT%H%M%S')

dir_backup="$folder_backup/$now"
dir_homepage="$folder_homepage"
dir_tmp_backup_folder="tmp_backup"
dir_tmp_backup="$dir_homepage/$dir_tmp_backup_folder"

drupal_url="https://ftp.drupal.org/files/projects/$drupal_version.tar.gz"
drupal_txt_files="CHANGELOG.txt COPYRIGHT.txt INSTALL.mysql.txt INSTALL.pgsql.txt INSTALL.sqlite.txt INSTALL.txt LICENSE.txt MAINTAINERS.txt README.txt UPGRADE.txt"
drupal_files=".gitignore authorize.php cron.php includes index.php install.php misc modules profiles scripts themes update.php web.config xmlrpc.php"


echo
echo "#####################################"
echo "##### Drupal Backup and Upgrade #####"
echo "#####################################"
echo


### Backup
# create backup dir
echo "create backup directory '$dir_backup' ..."
mkdir $dir_backup

# backup database
echo "create MySql Dump from '$db_db' ..."
$bin_mysqldump -h$db_host -P$db_port -u$db_user -p $db_db | bzip2 > "$dir_backup/drupal_db_$now.sql.bz2"

# backup filesystem
echo "create filesystem backup from '$dir_homepage' ..."
$bin_tar -czpf "$dir_backup/drupal_files_$now.tar.gz" $dir_homepage


### Upgrade
# create tmp backup
echo "create tmp backup directory '$dir_tmp_backup' ..."
mkdir $dir_tmp_backup

# move old files to tmp backup
echo "move drupal files to tmp backup directory '$dir_tmp_backup' ..."
(cd $dir_homepage && mv $drupal_files $dir_tmp_backup_folder)

# download new drupal version
echo "download new drupal version '$drupal_version' ..."
$bin_wget --no-check-certificate $drupal_url

# extract
echo "extract downloaded drupal version ..."
$bin_tar -xzpf "$drupal_version.tar.gz" --strip 1 --skip-old-files -C $dir_homepage

#clean up
echo "remove drupal txt files ..."
(cd $dir_homepage && rm -f $drupal_txt_files)


### clean up
# wait for online upgrade
echo "Please run '$homepage_url/update.php' ..."
read -p "Press any key to continue... " -n1 -s

# remove tmp files
echo
read -p "Are you sure to clean up? Y/N " -n1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    echo "clean up ..."
    rm -rf $dir_tmp_backup "$drupal_version.tar.gz"
fi


echo "Upgrade completed!"
echo ">>> Don't forget to delete this script from server!"
exit 0


