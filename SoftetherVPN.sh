#!/bin/bash
# Install SoftEther VPN for CentOS/Rocky/AlmaLinux

# Check if user is root
[ $(id -u) != "0" ] && { echo -e "\033[31mError:This script must be run as root!\033[0m"; exit 1; } 
[ ! -e '/etc/redhat-release' ] && { echo -e "\033[31mError: This script is not supported on your system.\033[0m"; exit 1; } 
export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
clear
printf "
#######################################################################
#            Installs OpenVPN for CentOS/Rocky/AlmaLinux              #
#            More information http://www.iewb.net                     #
#######################################################################
"
pwd=`pwd`
echo "1. Install Softether VPN Server"
echo "2. Install Softether VPN Client"
read -p "Please choose what you want to do: " i
case "$i" in
	1)
[ ! -e '/usr/bin/wget' ] && yum -y install wget
wget -O softether.tar.gz https://github.com/SoftEtherVPN/SoftEtherVPN_Stable/releases/download/v4.44-9807-rtm/softether-vpnserver-v4.44-9807-rtm-2025.04.16-linux-x64-64bit.tar.gz
yum -y install tar
tar -zxvf softether.tar.gz
#下载是否完成
if [ ! -e "./vpnserver" ]; then echo "Download softether-vpnserver From Github failed"; exit 1; fi
yum -y install gcc zlib-devel openssl-devel readline-devel ncurses-devel
cd vpnserver/
make
touch /usr/lib/systemd/system/vpnserver.service
	cat > /usr/lib/systemd/system/vpnserver.service <<EOF
[Unit]
Description=SoftEther Server
After=network.target
[Service]
Type=forking
ExecStart=$pwd/vpnserver/vpnserver start
ExecStop= $pwd/vpnserver/vpnserver stop
[Install]
WantedBy=multi-user.target
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
rm -rf $pwd/softether.tar.gz 

chmod 754 /usr/lib/systemd/system/vpnserver.service
systemctl enable vpnserver
systemctl start vpnserver
firewall-cmd --add-port=5555/tcp --permanent
firewall-cmd --add-port=443/tcp --permanent
#firewall-cmd --add-port=31400-31409/tcp --permanent
firewall-cmd --add-masquerade --permanent
#firewall-cmd --add-forward-port=port=31400:proto=tcp:toport=31400:toaddr=192.168.30.10 --permanent
firewall-cmd --reload
clear
echo -e "\033[32m successful\033[0m"
;;
2)
# Install SoftEther Client for CentOS/Rocky/AlmaLinux
#/sbin/ifconfig vpn_vpn2 192.168.30.15 netmask 255.255.255.0 up
#cd vpnclient && ./vpncmd
#RemoteEnable 
wget -O vpnclient.tar.gz https://github.com/SoftEtherVPN/SoftEtherVPN_Stable/releases/download/v4.44-9807-rtm/softether-vpnclient-v4.44-9807-rtm-2025.04.16-linux-x64-64bit.tar.gz
tar -zxvf vpnclient.tar.gz
#下载是否完成
if [ ! -e "./vpnclient" ]; then echo "Download softether-vpnclient From Github failed"; exit 1; fi
yum -y install gcc net-tools
cd vpnclient/
make
touch /usr/lib/systemd/system/vpnclient.service
	cat > /usr/lib/systemd/system/vpnclient.service <<EOF
[Unit]
Description=SoftEther Client
After=network.target
[Service]
Type=forking
ExecStart=$pwd/vpnclient/vpnclient start
ExecStop= $pwd/vpnclient/vpnclient stop
[Install]
WantedBy=multi-user.target
EOF

rm -rf $pwd/vpnclient.tar.gz
chmod 754 /usr/lib/systemd/system/vpnclient.service
systemctl enable vpnclient
systemctl start vpnclient

firewall-cmd --add-port=9930/tcp --permanent
firewall-cmd --reload
#start
touch /home/start.sh
	cat > /home/start.sh <<EOF
#!/bin/bash
/sbin/ifconfig vpn_vpn 192.168.30.100 netmask 255.255.255.0 up
EOF
chmod +x /home/start.sh
#crontab
echo "@reboot sleep 60; /home/start.sh" >>/var/spool/cron/root

clear
echo -e "\033[32m successful\033[0m"
;;
*)
		 echo "Please choose a right item."
esac