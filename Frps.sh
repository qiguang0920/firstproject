#!/bin/bash
# Install Frp_server for CentOS/Rocky/AlmaLinux

# Check if user is root
[ $(id -u) != "0" ] && { echo -e "\033[31mError: You must be root to run this script\033[0m"; exit 1; } 

export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
clear
printf "
#######################################################################
#            Install Frp_server for CentOS/Rocky/AlmaLinux	          #
#            More information http://www.iewb.net                     #
#######################################################################
"
pwd=`pwd`
wget https://github.com/fatedier/frp/releases/download/v0.65.0/frp_0.65.0_linux_amd64.tar.gz
yum install tar -y 
tar -zxvf frp_0.65.0_linux_amd64.tar.gz 
#下载是否完成
if [ ! -e "$pwd/frp_0.65.0_linux_amd64/frps" ]; then echo "Download frp From Github failed"; exit 1; fi
rm -rf frp_0.65.0_linux_amd64.tar.gz

dashboard_user="admin"
dashboard_pwd="admin"
token="IEWB.NET_$RANDOM"
while :; do echo
    read -p "Please input dashboard username: " dashboard_user
    [ -n "$dashboard_user" ] && break
done

while :; do echo
    read -p "Please input dashboard password: " dashboard_pwd
    [ -n "$dashboard_pwd" ] && break
done

cat > $pwd/frp_0.65.0_linux_amd64/frps.ini <<EOF
#通用设置
[common]
# frp 监听地址
bind_port = 7000
#frp 控制面板
dashboard_port = 7500
# dashboard 用户名密码可选，默认都为 admin
dashboard_user = $dashboard_user
dashboard_pwd = $dashboard_pwd
token= $token
EOF

setenforce 0
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
echo "1" > /proc/sys/net/ipv4/ip_forward
sed -i 's/net.ipv4.ip_forward = 0/net.ipv4.ip_forward = 1/g' /etc/sysctl.conf
if ! grep "net.ipv4.ip_forward = 1" /etc/sysctl.conf >>/dev/null
then
echo 'net.ipv4.ip_forward = 1' >> /etc/sysctl.conf
fi
sysctl -p /etc/sysctl.conf

firewall-cmd --add-port=7000/tcp --permanent
firewall-cmd --add-port=7500/tcp --permanent
#firewall-cmd --add-port=31400-31409/tcp --permanent
touch /home/frp.sh
	cat > /home/frp.sh <<EOF
#!/bin/bash
$pwd/frp_0.65.0_linux_amd64/frps -c $pwd/frp_0.65.0_linux_amd64/frps.ini &
EOF

chmod +x /home/frp.sh
#crontab
echo "@reboot sleep 10; /home/frp.sh" >>/var/spool/cron/root
/bin/bash /home/frp.sh
clear
echo -e "Dashboard_user: \033[32m${dashboard_user}\033[0m" "Dashboard Password: \033[32m${dashboard_pwd}\033[0m"
echo -e "token: \033[32m${token}\033[0m"
#reboot