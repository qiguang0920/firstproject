#!/bin/bash
clear
printf "
#######################################################################
#                Install LAMP for CentOS7                             #
#            More information http://www.iewb.net                     #
#######################################################################
"
echo "1. Install LAMP"
echo "2. Add/Del a domain"
read -p "Please choose what you want to do: " i
case "$i" in
	1)
php_version="56"
dbpasswd="admin888"
domain="test.com"
public_dir="/home/Public_Root"
phpmyadmin="yes"
while :; do echo
    read -p "Please input your domain,if haven't,input [test.com]: " domain 
    [ -n "$domain" ] && break
done

while :; do echo
    read -p "Please input the php version [56][70][71][72]: " php_version 
    [ -n "$php_version" ] && break
done

while :; do echo
    read -p "Please input MariaDB password: " dbpasswd 
    [ -n "$dbpasswd" ] && break
done

while :; do echo
    read -p "Do you want to install phpmyadmin [yes]or[no]: " phpmyadmin 
    [ -n "$phpmyadmin" ] && break
done

[ ! -e '/etc/yum.repos.d/epel.repo' ] && yum -y install epel-release
#[ ! -e '/usr/bin/wget' ] && yum -y install wget
#[ ! -e '/usr/bin/unzip' ] && yum -y install unzip
rpm -ivh http://rpms.famillecollet.com/enterprise/remi-release-7.rpm
yum --enablerepo=epel install libargon2 libmcrypt -y
yum install --enablerepo=remi-php$php_version php php-opcache php-devel php-mbstring php-mcrypt php-mysqlnd php-phpunit-PHPUnit php-bcmath php-gd php-common -y 
yum install php$php_version -y
if [ ! -e /etc/yum.repos.d/MariaDB.repo ];then
        cat > /etc/yum.repos.d/MariaDB.repo << EOF
# MariaDB 10.1 CentOS repository list - created 2016-12-01 03:36 UTC
# http://downloads.mariadb.org/mariadb/repositories/
# https://yum.mariadb.org/10.3/centos73-amd64/
[mariadb]
name = MariaDB
#baseurl = https://mirrors.ustc.edu.cn/mariadb/yum/10.3/centos7-amd64
baseurl = https://yum.mariadb.org/10.3/centos7-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
EOF
	fi
	for Package in mariadb mariadb-server httpd mod_ssl openssl wget unzip
	do
		yum install $Package -y 
done	

mkdir $public_dir &&mkdir $public_dir/$domain &&mkdir $public_dir/$domain/public_html &&mkdir $public_dir/$domain/logs
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
wget https://www.iewb.net/down/tz.zip && unzip tz.zip && mv tz.php $public_dir/$domain/public_html/t.php && rm -rf ./tz.zip
if [ "$phpmyadmin" != "no" ];then
/usr/bin/wget https://files.phpmyadmin.net/phpMyAdmin/4.7.7/phpMyAdmin-4.7.7-all-languages.zip && /usr/bin/unzip ./phpMyAdmin-4.7.7-all-languages.zip && mv ./phpMyAdmin-4.7.7-all-languages $public_dir/$domain/public_html/phpmyadmin &&rm -rf phpMyAdmin-4.7.7-all-languages.zip  
else
	echo "You select don't install phpmyadmin."
fi
if [ ! -e /etc/httpd/conf.d/$domain.conf ];then
echo "<Directory "\"$public_dir"\">" >>/etc/httpd/conf.d/$domain.conf
echo "Options Indexes FollowSymlinks" >>/etc/httpd/conf.d/$domain.conf
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
systemctl start firewalld
firewall-cmd --add-service=http --permanent 
firewall-cmd --add-service=https --permanent
firewall-cmd --reload
setenforce 0
sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 8M/g' /etc/php.ini
sed -i 's/short_open_tag = Off/short_open_tag = ON/g' /etc/php.ini
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
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
public_dir="/home/Public_Root"

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
public_dir="/home/Public_Root"

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
