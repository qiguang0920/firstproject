#!/bin/bash
#Time
if [ -e /usr/lib/systemd/system/ntpdate.service ];then
ntpdate -u pool.ntp.org
else
chronyd -q 'server pool.ntp.org iburst'
fi
clear
printf "
#######################################################################
#                Install LAMP for CentOS/Rocky/AlmaLinux              #
#             More information http://www.iewb.net                    #
#                         BY:2024-08-30                               #
#######################################################################
"
os_name=`awk -F= '/^NAME/{print $2}' /etc/os-release | awk -F'"' '{print $2}'`
os_version_id=`awk -F= '/^VERSION_ID/{print $2}' /etc/os-release | awk -F'"' '{print $2}'`
os_version_id2=`awk -F= '/^VERSION_ID/{print $2}' /etc/os-release | awk -F'"' '{print $2}'| awk -F'.' '{print $1}'`
os_release=`cat /etc/redhat-release`
os_kernel=`uname -sr`
echo -e "System-release:\e[1;32m $os_release \e[0m"
echo -e "Kernel:\e[1;32m $os_kernel \e[0m"

echo "1. Install LAMP"
echo "2. Add/Del a domain"
read -p "Please choose what you want to do: " i
case "$i" in
	1)
dbpasswd="admin888"
public_dir="/Data/Public_Root"
domain="test.com"
while :; do echo
    read -t 20 -p "Please input your domain,if haven't,input [test.com]: " domain
	domain=${domain:-test.com}
	    [ -n "$domain" ] && break
done

while :; do echo
	echo "1. PHP5.4"
	echo "2. PHP7.2"
	echo "3. PHP7.4"
	echo "4. PHP8.1"
	echo "5. PHP8.2"
	echo "6. PHP8.3"
	read -t 20 -p "Please choose the PHP version :" v	
	case "$v" in
	1)
	php_version=54
	;;
	2)
	php_version=72
	;;
	3)
	php_version=74
	;;
	4)
	php_version=81
	;;
	5)
	php_version=82
	;;
	6)
	php_version=83
	;;
	*)
	 echo "Your choice is not 1-6 ,will be installed php8.3"
	 php_version=${php_version:-83}
	;;	 
esac
	
[ -n "$php_version" ] && break
done

while :; do echo
	echo "1. MariaDB 10.11"
	echo "2. MariaDB 11.8"
	echo "3. MariaDB 11.rc"
	echo "4. MariaDB 12.rc"	
	read -t 20 -p "Please choose the MariaDB version :" v1	
	case "$v1" in
	1)
	MariaDB_version=10.11
	;;
	2)
	MariaDB_version=11.8
	;;
	3)
	MariaDB_version=11.rc
	;;
	4)
	MariaDB_version=12.rc
	;;
	*)
	 echo "Your choice is not 1-4 ,will be installed MariaDB 12.rc"
	 MariaDB_version=${MariaDB_version:-12.rc}
	;;	 
esac
	
[ -n "$MariaDB_version" ] && break
done

while :; do echo
    read -t 20 -p "Please input MariaDB password: " dbpasswd
	dbpasswd=${dbpasswd:-admin888}
    [ -n "$dbpasswd" ] && break
done

while :; do echo
    read -t 20 -p "Do you want to install phpmyadmin [yes]or[no]: " phpmyadmin
	phpmyadmin=${phpmyadmin:-yes}
    [ -n "$phpmyadmin" ] && break
done

#yum clean all
yum clean all
##Install EPEL
[ ! -e '/etc/yum.repos.d/epel.repo' ] && yum -y install epel-release 
##Install PHP
#rpm -ivh http://rpms.famillecollet.com/enterprise/remi-release-$os_version_id.rpm --force --nodeps 

if [ "$os_version_id2" = "7" ];then
sed -i 's/mirrorlist=/#mirrorlist=/g' /etc/yum.repos.d/CentOS-*
sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*
#rpm -ivh https://mirrors.ustc.edu.cn/remi/enterprise/remi-release-$os_version_id.rpm --force --nodeps
rpm -ivh http://rpms.famillecollet.com/enterprise/remi-release-$os_version_id.rpm --force --nodeps
yum install --enablerepo=remi-php$php_version php php-opcache php-devel php-mbstring php-mcrypt php-mysqlnd php-phpunit-PHPUnit php-bcmath php-gd php-common php-snmp -y && yum install php -y
sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 8M/g' /etc/php.ini
sed -i 's/short_open_tag = Off/short_open_tag = ON/g' /etc/php.ini

else
#rpm -ivh https://mirrors.ustc.edu.cn/remi/enterprise/remi-release-$os_version_id.rpm --force --nodeps
rpm -ivh http://rpms.famillecollet.com/enterprise/remi-release-$os_version_id.rpm --force --nodeps
dnf install -y --enablerepo=remi php$php_version php$php_version-php-fpm php$php_version-php-cli php$php_version-php-bcmath php$php_version-php-gd php$php_version-php-json php$php_version-php-mbstring php$php_version-php-mcrypt php$php_version-php-mysqlnd php$php_version-php-opcache php$php_version-php-pdo php$php_version-php-pecl-crypto php$php_version-php-pecl-geoip php$php_version-php-snmp php$php_version-php-soap php$php_version-php-xml
dnf install -y --enablerepo=remi php$php_version-php-pecl-mcrypt 
sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 8M/g' /etc/opt/remi/php$php_version/php.ini
sed -i 's/short_open_tag = Off/short_open_tag = ON/g' /etc/opt/remi/php$php_version/php.ini
fi

systemctl enable php$php_version-php-fpm
systemctl restart php$php_version-php-fpm

#Install MariaDB
# Specified apache version
#cd /etc/yum.repos.d && wget https://repo.codeit.guru/codeit.el`rpm -q --qf "%{VERSION}" $(rpm -q --whatprovides redhat-release)`.repo

if [ ! -e /etc/yum.repos.d/MariaDB.repo ];then
        cat > /etc/yum.repos.d/MariaDB.repo << EOF
# MariaDB 10.1 CentOS repository list - created 2016-12-01 03:36 UTC
# http://downloads.mariadb.org/mariadb/repositories/
# https://yum.mariadb.org/10.3/centos73-amd64/
[mariadb]
name = MariaDB
baseurl = https://yum.mariadb.org/$MariaDB_version/rhel$os_version_id2-amd64
gpgkey = https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
EOF
fi

yum install --enablerepo=mariadb mariadb mariadb-server -y

if [ ! -e /var/lib/mysql ];then
yum install mariadb mariadb-server -y 
fi

#Install Httpd
yum --enablerepo=epel install libargon2 libmcrypt -y 
yum install httpd mod_ssl openssl unzip wget -y

mkdir -p $public_dir/$domain &&mkdir $public_dir/$domain/public_html &&mkdir $public_dir/$domain/logs
if [ ! -e $public_dir/$domain/public_html/index.php ];then
        cat > $public_dir/$domain/public_html/index.php << EOF
<title>LAMP Test Page!</title>
<style type="text/css">
* { margin:0; padding:0; }
body { margin:0 auto; font-size:12px; font-family:Verdana; line-height:150%; }
ul { list-style:none; }
h1 { font-size:18px; }
.clearfloat { clear:both; height:0; font-size: 1px; line-height: 0; }
#container{ margin:0 auto; width:940px; }
/*header*/
#header { height:100px; background:#cf0; }
#header h1 { padding:10px 20px; }
#nav { background:#FF6600; height:35px; margin-bottom:6px; padding:5px; }
#nav ul li { float:left; }
#nav ul li a { display:block; padding:4px 10px 2px 10px; color:#000; text-decoration:none; }
#nav ul li a:hover { text-decoration:underline; background:#06f; color:#FFF; }
</style>
</head>
<body><center>
<div id="container">
  <div id="header">
    <h1>This is a test page</h1>
<h1>LAMP installation was successful!</h1>
    <!-- end #header -->
  </div>
  <div class="clearfloat"></div>
  <div id="nav">
    <ul>
      <li><a href="./t.php">PHP</a></li>
      <li><a href="./phpmyadmin">PHPMydmin</a></li>
      <li><a href="http://www.iewb.net">MyBlog</a></li>
        </ul>
</div></div></body></center>
<?php
phpinfo();
?>
EOF
fi
wget https://static.lty.fun/%E5%85%B6%E4%BB%96%E8%B5%84%E6%BA%90/Status-TZ/yhtz7-https.zip --no-check-certificate && unzip yhtz7-https.zip && mv yhtz7-https.php $public_dir/$domain/public_html/t.php && rm -rf ./yhtz7-https.zip
if [ "$phpmyadmin" != "no" ];then
/usr/bin/wget https://files.phpmyadmin.net/phpMyAdmin/5.2.1/phpMyAdmin-5.2.1-all-languages.zip --no-check-certificate && /usr/bin/unzip ./phpMyAdmin-5.2.1-all-languages.zip && mv phpMyAdmin-5.2.1-all-languages $public_dir/$domain/public_html/phpmyadmin &&rm -rf phpMyAdmin-5.2.1-all-languages.zip 
else
	echo "You select don't install phpmyadmin."
fi
if [ ! -e /etc/httpd/conf.d/$domain.conf ];then
echo "<Directory "\"$public_dir"\">" >>/etc/httpd/conf.d/$domain.conf
echo "Options FollowSymlinks" >>/etc/httpd/conf.d/$domain.conf
echo "AllowOverride All" >>/etc/httpd/conf.d/$domain.conf
echo "Require all granted" >>/etc/httpd/conf.d/$domain.conf
echo "</Directory>" >>/etc/httpd/conf.d/$domain.conf
echo "<VirtualHost *:80>" >>/etc/httpd/conf.d/$domain.conf
echo "ServerAdmin web@$domain" >>/etc/httpd/conf.d/$domain.conf
echo "ServerName $domain" >>/etc/httpd/conf.d/$domain.conf
echo "ServerAlias $domain" >>/etc/httpd/conf.d/$domain.conf
echo "DocumentRoot $public_dir/$domain/public_html/" >>/etc/httpd/conf.d/$domain.conf
echo "ErrorLog $public_dir/$domain/logs/error.log" >>/etc/httpd/conf.d/$domain.conf
echo "CustomLog $public_dir/$domain/logs/access.log combined" >>/etc/httpd/conf.d/$domain.conf
echo "</VirtualHost>" >>/etc/httpd/conf.d/$domain.conf
fi
#systemctl start firewalld
firewall-cmd --add-service=http --permanent 
firewall-cmd --add-service=https --permanent
firewall-cmd --reload
setenforce 0
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
##Move MariaDB
systemctl start mariadb
systemctl stop mariadb
mkdir /Data/sqldata
cp -a /var/lib/mysql/* /Data/sqldata
chown -R mysql:mysql /Data/sqldata
sed -i '1i\socket=/Data/sqldata/mysql.sock' /etc/my.cnf
sed -i '1i\[client-server]' /etc/my.cnf
sed -i '4,7d' /etc/my.cnf
sed -i "3a\[mysqld]" /etc/my.cnf
sed -i "4a\init_connect='SET collation_connection = utf8mb4_unicode_ci'" /etc/my.cnf
sed -i "5a\init_connect='SET NAMES utf8mb4'" /etc/my.cnf
sed -i "6a\character_set_server=utf8mb4" /etc/my.cnf
sed -i "7a\collation-server=utf8mb4_unicode_ci" /etc/my.cnf
sed -i "8a\skip-character-set-client-handshake=true" /etc/my.cnf
sed -i "9a\datadir=/Data/sqldata" /etc/my.cnf
sed -i "10a\socket=/Data/sqldata/mysql.sock" /etc/my.cnf
rm -rf /var/lib/mysql/*
ln -s /Data/sqldata/mysql.sock /var/lib/mysql/mysql.sock
systemctl start httpd mariadb
systemctl enable httpd mariadb
mysqladmin -uroot password ''$dbpasswd''
clear
echo -e "\033[32mYour LAMP Platform installation was successful,PHP Version:php$php_version;MariaDB password:$dbpasswd\033[0m"
;;
	2)
echo "a. add a domain"
echo "b. del a domain"
read -p "please choose what you want to do: " i2
case "$i2" in
a)
adddomain="test2.com"
public_dir="/Data/Public_Root"

while :; do echo
    read -p "Please input your new domain: " adddomain 
    [ -n "$adddomain" ] && break
done

if [ -e $public_dir ];then
echo "<Directory "\"$public_dir"\">" >>/etc/httpd/conf.d/$adddomain.conf
echo "Options Indexes FollowSymlinks" >>/etc/httpd/conf.d/$adddomain.conf
echo "AllowOverride All" >>/etc/httpd/conf.d/$adddomain.conf
echo "Require all granted" >>/etc/httpd/conf.d/$adddomain.conf
echo "</Directory>" >>/etc/httpd/conf.d/$adddomain.conf
echo "<VirtualHost *:80>" >>/etc/httpd/conf.d/$adddomain.conf
echo "ServerAdmin web@$adddomain" >>/etc/httpd/conf.d/$adddomain.conf
echo "ServerName $adddomain" >>/etc/httpd/conf.d/$adddomain.conf
echo "ServerAlias $adddomain" >>/etc/httpd/conf.d/$adddomain.conf
echo "DocumentRoot $public_dir/$adddomain/public_html/" >>/etc/httpd/conf.d/$adddomain.conf
echo "ErrorLog $public_dir/$adddomain/logs/error.log" >>/etc/httpd/conf.d/$adddomain.conf
echo "CustomLog $public_dir/$adddomain/logs/access.log combined" >>/etc/httpd/conf.d/$adddomain.conf
echo "</VirtualHost>" >>/etc/httpd/conf.d/$adddomain.conf >>/etc/httpd/conf.d/$adddomain.conf

mkdir $public_dir/$adddomain &&mkdir $public_dir/$adddomain/public_html &&mkdir $public_dir/$adddomain/logs
if [ ! -e $public_dir/$adddomain/public_html/index.php ];then
        cat > $public_dir/$adddomain/public_html/index.php << EOF
<title>LAMP Test Page!</title>
<style type="text/css">
* { margin:0; padding:0; }
body { margin:0 auto; font-size:12px; font-family:Verdana; line-height:150%; }
ul { list-style:none; }
h1 { font-size:18px; }
.clearfloat { clear:both; height:0; font-size: 1px; line-height: 0; }
#container{ margin:0 auto; width:940px; }
/*header*/
#header { height:100px; background:#cf0; }
#header h1 { padding:10px 20px; }
#nav { background:#FF6600; height:35px; margin-bottom:6px; padding:5px; }
#nav ul li { float:left; }
#nav ul li a { display:block; padding:4px 10px 2px 10px; color:#000; text-decoration:none; }
#nav ul li a:hover { text-decoration:underline; background:#06f; color:#FFF; }
</style>
</head>
<body><center>
<div id="container">
  <div id="header">
    <h1>This is a test page</h1>
<h1>Seeing this page proved LAMP installation was successful</h1>
    <!-- end #header -->
  </div>
  <div class="clearfloat"></div>
  <div id="nav">
    <ul>
      <li><a href="./t.php">PHP</a></li>
      <li><a href="./phpmyadmin">PHPMydmin</a></li>
      <li><a href="http://www.iewb.net">MyBlog</a></li>
        </ul>
</div></div></body></center>
<?php
phpinfo();
?>
EOF
fi
systemctl restart httpd
clear
echo -e "\033[32mYou add new domain was successful,the new domain:$adddomain\033[0m"
else
	echo "You doesn't installed LAMP..."
fi
;;
b)
deldomain="test2.com"
public_dir="/Data/Public_Root"

while :; do echo
    read -p "Please input your domain what your want del: " deldomain 
    [ -n "$deldomain" ] && break
done
if [ -e $public_dir/$deldomain ];then
rm -rf $public_dir/$deldomain &&rm -rf /etc/httpd/conf.d/$deldomain.conf
systemctl restart httpd
echo "Your domain $deldomain is deleted."
else
	echo "You havn't add the domain:$deldomain"
fi
;;
*)
echo "Please choose a right item."
esac
;;
	*)
		 echo "Please choose a right item."
esac