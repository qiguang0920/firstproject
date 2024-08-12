#!/bin/sh
# Check if user is root
[ $(id -u) != "0" ] && { echo -e "\033[31mError: You must be root to run this script\033[0m"; exit 1; } 
export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
clear
printf "
#######################################################################
#            添加用户并加入到超级用户，	测试脚本		              #
#            More information http://www.iewb.net                     #
#######################################################################
"
name=test1
pass=test1
read -t 20 -p "Please input your username: " name
	name=${domain:-test1}
	    [ -n "$name" ]
read -t 20 -p "Please input your new user password: " pass
	pass=${domain:-test1}
	    [ -n "$pass" ]		
#输出到控制台
echo "you are setting username : ${name}"
echo "you are setting password : $pass for ${name}"
#添加用户，-M没有家目录
sudo useradd -M $name
#UID改成0
usermod -o -u 0 -g 0 $name
#输出到控制台,如果上一个命令正常运行，则输出成功，否则提示失败
if [ $? -eq 0 ];then
   echo "user ${name} is created successfully!!!"
else
   echo "user ${name} is created failly!!!"
   exit 1
fi
#chmod -v u+w /etc/sudoers
#sed -i "93a$name    ALL=(ALL) NOPASSWD: NOPASSWD: ALL" /etc/sudoers
#chmod -v u-w /etc/sudoers
#用户密码
echo $pass | sudo passwd $name --stdin  &>/dev/null
if [ $? -eq 0 ];then
   echo "${name}'s password is set successfully"
else
   echo "${name}'s password is set failly!!!"
fi
