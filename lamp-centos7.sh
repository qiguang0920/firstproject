#!/bin/bash
clear
printf "
#######################################################################
#                Install LAMP for CentOS7                             #
#            More information http://www.iewb.net                     #
#######################################################################
"
php_version="56"
dbpasswd="admin888"
public_dir="/home/test.com/public_html"
phpmyadmin="yes"
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
[ ! -e '/usr/bin/wget' ] && yum -y install wget
[ ! -e '/usr/bin/unzip' ] && yum -y install unzip
rpm -ivh http://rpms.famillecollet.com/enterprise/remi-release-7.rpm
yum install --enablerepo=remi-php$php_version php php-opcache php-devel php-mbstring php-mcrypt php-mysqlnd php-phpunit-PHPUnit php-bcmath php-gd php-common -y 
yum install php$php_version -y
if [ ! -e /etc/yum.repos.d/MariaDB.repo ];then
        cat > /etc/yum.repos.d/MariaDB.repo << EOF
# MariaDB 10.1 CentOS repository list - created 2016-12-01 03:36 UTC
# http://downloads.mariadb.org/mariadb/repositories/
[mariadb]
name = MariaDB
baseurl = https://mirrors.ustc.edu.cn/mariadb/yum/10.3/centos73-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
EOF
	fi
	for Package in mariadb mariadb-server httpd mod_ssl openssl wget
	do
		yum install $Package -y 
done	

mkdir /home/test.com &&mkdir /home/test.com/public_html &&mkdir /home/test.com/logs
if [ ! -e $public_dir/index.php ];then
        cat > $public_dir/index.php << EOF
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
<h1>See this page proved LAMP installation was successful</h1>
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
wget http://www.yahei.net/tz/tz.zip && unzip tz.zip && mv tz.php $public_dir/t.php && rm -rf ./tz.zip
if [ "$phpmyadmin" != "no" ];then
/usr/bin/wget https://files.phpmyadmin.net/phpMyAdmin/4.7.7/phpMyAdmin-4.7.7-all-languages.zip && /usr/bin/unzip ./phpMyAdmin-4.7.7-all-languages.zip && mv ./phpMyAdmin-4.7.7-all-languages $public_dir/phpmyadmin &&rm -rf phpMyAdmin-4.7.7-all-languages.zip  
else
	echo "You select don't install phpmyadmin."
fi
if [ ! -e /etc/httpd/conf.d/vhost.conf ];then
        cat >/etc/httpd/conf.d/vhost.conf << EOF
<VirtualHost *:80>
ServerAdmin web@iewb.net
ServerName test.com
ServerAlias test.com
DocumentRoot /home/test.com/public_html/
ErrorLog /home/test.com/logs/error.log
CustomLog /home/test.com/logs/access.log combined
</VirtualHost>
EOF
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
