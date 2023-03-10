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
echo "1. Install Softether VPN Server"
echo "2. Install Softether VPN Client"
read -p "Please choose what you want to do: " i
case "$i" in
	1)
[ ! -e '/usr/bin/wget' ] && yum -y install wget
wget -O softether.tar.gz https://github.com/SoftEtherVPN/SoftEtherVPN_Stable/releases/download/v4.41-9782-beta/softether-vpnserver-v4.41-9782-beta-2022.11.17-linux-x64-64bit.tar.gz
tar -zxvf softether.tar.gz
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
ExecStart=/root/vpnserver/vpnserver start
ExecStop= /root/vpnserver/vpnserver stop
[Install]
WantedBy=multi-user.target
EOF

chmod 754 /usr/lib/systemd/system/vpnserver.service
systemctl enable vpnserver
systemctl start vpnserver

setenforce 0
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
echo "1" > /proc/sys/net/ipv4/ip_forward
if ! grep "net.ipv4.ip_forward = 1" /etc/sysctl.conf >>/dev/null
then
echo 'net.ipv4.ip_forward = 1' >> /etc/sysctl.conf
fi
sysctl -p /etc/sysctl.conf

firewall-cmd --add-port=5555/tcp --permanent
firewall-cmd --add-port=443/tcp --permanent
firewall-cmd --add-port=31400-31409/tcp --permanent
firewall-cmd --add-masquerade --permanent
firewall-cmd --add-forward-port=port=31400:proto=tcp:toport=31400:toaddr=192.168.30.10 --permanent
firewall-cmd --add-forward-port=port=31401:proto=tcp:toport=31401:toaddr=192.168.30.10 --permanent
firewall-cmd --add-forward-port=port=31402:proto=tcp:toport=31402:toaddr=192.168.30.10 --permanent
firewall-cmd --add-forward-port=port=31403:proto=tcp:toport=31403:toaddr=192.168.30.10 --permanent
firewall-cmd --add-forward-port=port=31404:proto=tcp:toport=31404:toaddr=192.168.30.10 --permanent
firewall-cmd --add-forward-port=port=31405:proto=tcp:toport=31405:toaddr=192.168.30.10 --permanent
firewall-cmd --add-forward-port=port=31406:proto=tcp:toport=31406:toaddr=192.168.30.10 --permanent
firewall-cmd --add-forward-port=port=31407:proto=tcp:toport=31407:toaddr=192.168.30.10 --permanent
firewall-cmd --add-forward-port=port=31408:proto=tcp:toport=31408:toaddr=192.168.30.10 --permanent
firewall-cmd --add-forward-port=port=31409:proto=tcp:toport=31409:toaddr=192.168.30.10 --permanent
firewall-cmd --reload
clear
echo -e "\033[32m successful\033[0m"
;;
2)
# Install SoftEther VPN Client for CentOS7
#/sbin/ifconfig vpn_vpn2 192.168.30.15 netmask 255.255.255.0 up
#cd vpnclient && ./vpncmd
#RemoteEnable 
[ ! -e '/usr/bin/wget' ] && yum -y install wget
wget -O vpnclient.tar.gz https://github.com/SoftEtherVPN/SoftEtherVPN_Stable/releases/download/v4.41-9782-beta/softether-vpnclient-v4.41-9782-beta-2022.11.17-linux-x64-64bit.tar.gz
tar -zxvf vpnclient.tar.gz
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
ExecStart=/root/vpnclient/vpnclient start
ExecStop= /root/vpnclient/vpnclient stop
[Install]
WantedBy=multi-user.target
EOF

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