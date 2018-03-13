#!/bin/bash -e

#############################
#
# Auto Install Drupal on Debian/Ubuntu boxes
# Author: ricardo amaro
# https://drupal.org/user/666176
#
# License: http://www.gnu.org/licenses/gpl-2.0.html
#
#############################
mySqlPassword= "Pa$$w0rd1234"
echo "Sudo password required for install"
sudo apt-get update

sudo DEBIAN_FRONTEND=noninteractive apt-get -y install debconf-utils 

echo 'mysql-server mysql-server/root_password password drupal' | sudo debconf-set-selections
echo 'mysql-server mysql-server/root_password_again password drupal' | sudo debconf-set-selections
echo 'phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2' | sudo debconf-set-selections

sudo DEBIAN_FRONTEND=noninteractive apt-get -y install phpmyadmin git drush apache2 apache2-bin apache2-data libdbd-mysql-perl libmysqlclient18 mysql-client mysql-common mysql-server libapache2-mod-php5 php5 php5-mysql php5-gd php-apc php5-curl php5-sqlite

sudo sed -i "/ServerName/d" /etc/apache2/apache2.conf
echo "ServerName drupal" | sudo tee -a /etc/apache2/apache2.conf
cd /etc/apache2/sites-available
echo '<VirtualHost *:80>
  DocumentRoot /var/www/drupal
  <Directory /var/www/drupal>
    Options Indexes FollowSymLinks MultiViews
    AllowOverride ALL
    Order allow,deny
    Allow from all
  </Directory>
  ErrorLog /var/log/apache2/error.log
  ServerSignature Off
  CustomLog /var/log/apache2/access.log combined
</VirtualHost>' | sudo tee /etc/apache2/sites-available/drupal.conf
sudo rm -rf /etc/apache2/sites-enabled/*default*
cd /etc/apache2/sites-enabled
sudo rm -f /etc/apache2/sites-enabled/drupal.conf
sudo ln -s ../sites-available/drupal.conf drupal.conf
sudo a2enmod rewrite 

sudo sed -i "s/^max_execution_time.*/max_execution_time=120/"  /etc/php5/apache2/php.ini
sudo sed -i "/127\.0\.2\.1/d" /etc/hosts
sudo su -c 'echo "127.0.2.1 drupal" >> /etc/hosts'

echo "DROP DATABASE IF EXISTS drupal;" | sudo mysql --defaults-file=/etc/mysql/debian.cnf
echo "CREATE DATABASE IF NOT EXISTS drupal;" | sudo mysql --defaults-file=/etc/mysql/debian.cnf
echo "CREATE USER 'drupal'@'localhost' IDENTIFIED BY 'd7pass';
GRANT ALL PRIVILEGES ON drupal.* to drupal@localhost;" | sudo mysql --defaults-file=/etc/mysql/debian.cnf
echo "FLUSH PRIVILEGES;" | sudo mysql --defaults-file=/etc/mysql/debian.cnf

sudo usermod -a -G www-data $USER
sudo rm -rf /var/www/drupal

echo "Downloading Drupal..."
sudo mkdir -p /var/www
cd /var/www
#sudo drush -y dl --destination=".." --drupal-project-rename="$(basename `pwd`)"
sudo drush -y dl --destination="/var/www/" --drupal-project-rename="drupal"

cd /var/www/drupal/sites/default/
sudo cp default.settings.php settings.php
sudo mkdir files
sudo chmod -R ga+w /var/www/drupal/sites 
sudo chown -R www-data:www-data /var/www/drupal
sudo /etc/init.d/apache2 restart
# Pre-install db and site
sudo drush -y si --db-url=mysql://drupal:d7pass@127.0.0.1/drupal  --account-name="drupal" --account-pass="d7pass" --account-mail="drupal@example.com"

echo ""
echo "-----------------------INSTALL DONE!--------------------------------"
echo "Open your browser on http://drupal"
echo 
echo "Database: drupal"
echo "User:     drupal"
echo "Password: d7pass"
echo 
echo "Note: Run drush commands when finished 'cd /var/www/drupal ; drush help'"
echo "--------------------------------------------------------------------"
firefox http://drupal http://drupal/phpmyadmin  >/dev/null 2>&1 &

exit 0


#This is used to start the all process from scratch.
#Use with caution
sudo DEBIAN_FRONTEND=noninteractive apt-get -y --purge remove drush mysql-common apache2* php5 phpmyadmin libapache2* debconf-utils ; sudo rm -rfv /var/lib/mysql /etc/apache2 /etc/mysql /var/www/drupal /usr/share/php/drush

