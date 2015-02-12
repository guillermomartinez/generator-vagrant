#!/usr/bin/env bash
#########################
##  Personal Settings  ##
#########################

# Timezone for the system
TimeZone="<%= VmTimeZone %>"
<% if (VmServiceMysql) { %>
<% if (MysqlDatabaseFiles != '') { %>
# Path to repo db path
DBPath="/var/www/db"

# File DB Name at repo
DBNames="<% MysqlDatabaseFiles %>"

# Real MySQL Databasename
MySQLDB="<% MysqlDatabaseFiles %>"<% } %><% } %>


########################################################################################################################
##                                      Vagrant Bootstrap BASH Shell Script                                           ##
########################################################################################################################
<% if (VmServiceMysql) { %>
# MySQL Settings
Username="<%= MysqlUsername %>"
Password="<%= MysqlPassword %>"
Hostname="127.0.0.1"
# Path to mysql binary
PathBin="/usr/bin/"<% } %>

######################
##  Install System  ##
######################

# Set new timezone
rm /etc/timezone
echo $TimeZone > /etc/timezone
dpkg-reconfigure -f noninteractive tzdata

<% if (VmServiceMysql) { %># Set a MySQL Password
debconf-set-selections <<< 'mysql-server-5.5 mysql-server/<%= MysqlUsername %>_password password <%= MysqlPassword %>'
debconf-set-selections <<< 'mysql-server-5.5 mysql-server/<%= MysqlUsername %>_password_again password <%= MysqlPassword %>'<% } %>

# Update Packet Management System
apt-get update

# Install software into the system
apt-get install -y \<% if (VmServiceApache) { %>
    apache2 \<% } if (SoftwarePhp) { %>
    php5 php5-common libapache2-mod-php5 php5-xdebug php5-gd php5-imagick \
    php5-cli php-pear php5-xmlrpc php5-mysql php5-mcrypt \<% } if (VmServiceMysql) { %>
    mysql-server-5.5 mysql-client libdbd-mysql libapache2-mod-auth-mysql \<% } if (VmServiceTomcat) { %>
    tomcat<%= TomcatVersion %> tomcat<%= TomcatVersion %>-admin \<% } if (SoftwareGit) { %>
    git git-core<% if (SoftwareGitolite) { %> gitolite gitweb <% } %> \<% } if (SoftwareNodeJs) { %>
    nodejs npm \<% } if (SoftwareSamba) { %>
    samba smbfs \<% } if (SoftwareSnmp) { %>
    snmp snmpd snmp-mibs-downloader <% if (VmServiceApache) { %>php5-snmp<% } %> \<% } if (SoftwarePython) { %>
    python3 <% if (VmServiceMysql) { %>python-mysqldb <% } if (VmServiceApache) { %>libapache2-mod-python<% } %> \<% } if (VmSystemSoftware) { %>
    <% if (SystemAutoconf) { %>autoconf <% } if (SystemBc) { %>bc <% } if (SystemHtop) { %>htop <% } if (SystemNcurses) { %>ncurses-dev <% } if (SystemLogrotate) { %>logrotate <% } if (SystemLogwatch) { %>logwatch <% } if (SystemLzma) { %>lzma <% } if (SystemScreen) { %>screen <% } if (SystemZip) { %>unzip zip <% } if (SystemRcconf) { %>rcconf sysv-rc-conf <% } %>\<% } %>
    openssl curl


# Set Shell Aliases
echo 'alias rm="rm -fv"' > /home/vagrant/.bash_aliases
echo 'alias ex="ls -lahv --color=auto"' >> /home/vagrant/.bash_aliases
echo 'alias ls="ls -aF --color=auto"' >> /home/vagrant/.bash_aliases
echo 'alias df="df -B h"' >> /home/vagrant/.bash_aliases
echo 'alias cp="cp -v"' >> /home/vagrant/.bash_aliases
echo 'alias mv="mv -v"' >> /home/vagrant/.bash_aliases
echo 'alias n="nano -w"' >> /home/vagrant/.bash_aliases
echo 'alias du="du -h --max-depth 1"' >> /home/vagrant/.bash_aliases
echo 'alias s="tail -f -n 250 /var/log/syslog"' >> /home/vagrant/.bash_aliases
echo 'alias cdwww="cd /var/www"' >> /home/vagrant/.bash_aliases


<% if (VmServiceApache) { %>
##########################
##  Webserver Settings  ##
##########################

rm -rf /var/www/
ln -fs /vagrant <%= ApacheHtdocsPath %>

sed -i '/ServerAdmin webmaster@localhost/c ServerAlias *.<% ApacheDomain %>.localhost' /etc/apache2/sites-available/default
sed -i '/Options Indexes FollowSymLinks MultiViews/c Options -Indexes +FollowSymLinks' /etc/apache2/sites-available/default
sed -i '/AllowOverride None/c AllowOverride FileInfo Indexes' /etc/apache2/sites-available/default

# XDebug Settings for Remote Debugging
echo '[Xdebug]' >> /etc/php5/apache2/php.ini
echo 'zend_extension="/usr/lib/php5/20090626/xdebug.so"' >> /etc/php5/apache2/php.ini
echo 'xdebug.profiler_output_dir = "/tmp/xdebug"' >> /etc/php5/apache2/php.ini
echo 'xdebug.trace_output_dir = "/tmp/xdebug"' >> /etc/php5/apache2/php.ini
echo 'xdebug.idekey = <%= ApacheXdebugIdeKey %>' >> /etc/php5/apache2/php.ini
echo 'xdebug.remote_enable = 1' >> /etc/php5/apache2/php.ini
echo 'xdebug.max_nesting_level = 500' >> /etc/php5/apache2/php.ini
echo 'xdebug.remote_port = "<%= ApacheXdebugPort %>"' >> /etc/php5/apache2/php.ini
echo 'xdebug.remote_host = 10.0.2.2' >> /etc/php5/apache2/php.ini
echo 'xdebug.remote_connect_back = 1' >> /etc/php5/apache2/php.ini

# Active URL Rewrite
a2enmod rewrite
service apache2 restart

<% } if (VmServiceMysql) { %>
######################
##  MySQL Settings  ##
######################

# Uncomment bind-address to connect from main host on it
sed -i '/bind-address/c #bind-address' /etc/mysql/my.cnf

# Set rights to get access from anywhere
/usr/bin/mysql -u $Username -p$Password -h $Hostname -e "UPDATE mysql.user SET Password = PASSWORD('<%= MysqlPassword %>') WHERE User = '<%= MysqlUsername %>';"
/usr/bin/mysql -u $Username -p$Password -h $Hostname -e "GRANT ALL ON *.* TO '<%= MysqlUsername %>'@'%';"
/usr/bin/mysql -u $Username -p$Password -h $Hostname -e "FLUSH PRIVILEGES;"

<% if (MysqlDatabaseFiles != '') { %>
# ReadOnly Tabellen aus der Datei auslesen
ReadTableNames=
IgnoreTable=

ls $DBPath"/"$DBNames"_ReadTable" > /dev/null 2> /dev/null
if [ $? == 0 ]; then

    while read Line
    do
        ReadTableNames="$ReadTableNames $Line"
    done < $DBPath"/"$DBNames"_ReadTable"

    # ReadTableNames String mit --ignore-table verschachteln
    for Elem in $ReadTableNames ; do
        IgnoreTable="$IgnoreTable --ignore-table=$MySQLDB.$Elem"
    done

fi



# Pruefen ob Datenbank vorhanden ist ?
/usr/bin/mysql -u $Username -p$Password -h $Hostname -e "CREATE DATABASE IF NOT EXISTS \`"$MySQLDB"\`;"


# Datenbank ReadOnly Tabellen importieren,
# falls ReadOnly Tabellen vorhanden sind
if [ -n "$IgnoreTable" ]; then

	ls $DBPath"/"$DBNames"_ReadOnly.sql" > /dev/null 2> /dev/null

	if [ $? == 0 ]; then
		echo "Import of readonly table structure . . ."
		# Wenn etwas fehlschaegt, bedeutet es das die Tabelle schon erstellt ist
		/usr/bin/mysql -u $Username -p$Password -h $Hostname --database=$MySQLDB < $DBPath"/"$DBNames"_ReadOnly.sql"

	else
		echo "Error: $DBPath/$Datenbanl_ReadOnly.sql not found !"

	fi
fi


# Datenbank Struktur importieren
ls $DBPath/$DBNames"_Structure.sql" > /dev/null 2> /dev/null
if [ $? == 0 ]; then
	echo "Import of table structure . . ."
	/usr/bin/mysql -u $Username -p$Password -h $Hostname --database=$MySQLDB < $DBPath"/"$DBNames"_Structure.sql" || exit

else
	echo "Error: $DBPath/$DBName_Structure.sql not found !"

fi


# Datenbank Daten importieren
ls $DBPath/$DBNames"_Data.sql" > /dev/null 2> /dev/null
if [ $? == 0 ]; then
	echo "Import of data . . ."
	/usr/bin/mysql -u $Username -p$Password -h $Hostname --database=$MySQLDB < $DBPath"/"$DBNames"_Data.sql" || exit

else
	echo "Error: $DBPath/$DBName_Data.sql not found !"

fi<% } %>


service mysql restart


<% } if (VmServiceTomcat) { %>
#######################
##  Tomcat Settings  ##
#######################



<% } %>
