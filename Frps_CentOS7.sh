#!/bin/bash
# Install SoftEther VPN for CentOS7

# Check if user is root
[ $(id -u) != "0" ] && { echo -e "\033[31mError: You must be root to run this script\033[0m"; exit 1; } 

export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
clear
printf "
#######################################################################
#            Install SoftEther VPN for CentOS7			              #
#            More information http://www.iewb.net                     #
#######################################################################
"
cd /root
wget https://github.com/fatedier/frp/releases/download/v0.48.0/frp_0.48.0_linux_amd64.tar.gz && tar -zxvf frp_0.48.0_linux_amd64.tar.gz
cd frp_0.48.0_linux_amd64 
	cat > /root/frp_0.48.0_linux_amd64/frps.ini <<EOF
#通用设置
[common]
# frp 监听地址
bind_port = 7000
#frp 控制面板
dashboard_port = 7500
# dashboard 用户名密码可选，默认都为 admin
dashboard_user = admin
dashboard_pwd = Luhaiyang
token= Luhaiyang@qq.com
EOF
setenforce 0
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
echo "1" > /proc/sys/net/ipv4/ip_forward
if ! grep "net.ipv4.ip_forward = 1" /etc/sysctl.conf >>/dev/null
then
echo 'net.ipv4.ip_forward = 1' >> /etc/sysctl.conf
fi
sysctl -p /etc/sysctl.conf
firewall-cmd --add-port=7000/tcp --permanent
firewall-cmd --add-port=7500/tcp --permanent
firewall-cmd --add-port=31400-31409/tcp --permanent
touch /home/frp.sh
	cat > /home/frp.sh <<EOF
#!/bin/bash
/root/frp_0.48.0_linux_amd64/frps -c /root/frp_0.48.0_linux_amd64/frps.ini &
EOF
chmod +x /home/frp.sh
#crontab
echo "@reboot sleep 10; /home/frp.sh" >>/var/spool/cron/root

#reboot
