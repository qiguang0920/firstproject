#!/bin/bash
# Install OpenVPN for CentOS/Rocky/AlmaLinux

# Check if user is root
[ $(id -u) != "0" ] && { echo -e "\033[31mError: You must be root to run this script\033[0m"; exit 1; } 
[ ! -e '/etc/redhat-release' ] && { echo -e "\033[31mError: Your operating system cannot use this script.\033[0m"; exit 1; } 
export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
clear
printf "
#######################################################################
#            Installs OpenVPN for CentOS/Rocky/AlmaLinux              #
#            More information http://www.iewb.net                     #
#######################################################################
"
echo "1. Install OpenVPN Server"
echo "2. Add OpenVPN Client"
echo "3. Uninstall OpenVPN Server"
echo "4. Revoke OpenVPN Client"
read -p "Please choose what you want to do: " i
case "$i" in
	1)
Port="1194"
Client_Name="Client"
protocol="udp"
global="yes"
while :; do echo
	echo "1. udp"
	echo "2. tcp"
	read -t 20 -p "Please choose the protocol :" v	
	case "$v" in
	1)
	protocol=udp
	;;
	2)
	protocol=tcp
	;;
	*)
	 echo "your choice is not 1-2, protocol will be default udp"
	 protocol=${protocol:-udp}
	;;	 
esac	
[ -n "protocol" ] && break
done

while :; do echo
	echo "1. yes"
	echo "2. no"
	read -t 20 -p "Whether to enable global proxy? :" v	
	case "$v" in
	1)
	global=yes
	;;
	2)
	global=no
	;;
	*)
	 echo "your choice is not 1-2, default yes"
	 global=${global:-yes}
	;;	 
esac	
[ -n "global" ] && break
done

while :; do echo
    read -t 20 -p "Please input VPN Server Port: " Port
	Port=${Port:-1194}
    [ -n "$Port" ] && break
done
while :; do echo
    read -t 20 -p "Please input Client Configuration Name: " Client_Name
	Client_Name=${Client_Name:-Client}
    [ -n "$Client_Name" ] && break
done
	
[ ! -e '/etc/yum.repos.d/epel.repo' ] && yum -y install epel-release
os_name=`awk -F= '/^NAME/{print $2}' /etc/os-release | awk -F'"' '{print $2}'`
if [ "$os_name" = "CentOS Stream" ];then
rpm -ivh https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
fi

[ ! -e '/usr/bin/wget' ] && yum -y install wget
[ ! -e '/usr/bin/curl' ] && yum -y install curl
SERVER_IP=`ip addr |grep "inet"|grep -v "127.0.0.1"|grep -v "inet6" |cut -d: -f2|awk '{print $2}'|cut -d/ -f1|awk '{print $1}'`
VPN_IP=`curl ipv4.icanhazip.com`

setenforce 0
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
echo "1" > /proc/sys/net/ipv4/ip_forward
sed -i 's/net.ipv4.ip_forward = 0/net.ipv4.ip_forward = 1/g' /etc/sysctl.conf
if ! grep "net.ipv4.ip_forward = 1" /etc/sysctl.conf >>/dev/null
then
echo 'net.ipv4.ip_forward = 1' >> /etc/sysctl.conf
fi
sysctl -p /etc/sysctl.conf

yum -y install openvpn openssl ca-certificates tar
#download files
mkdir -p /etc/openvpn/easy-rsa/
wget -O easyrsa.tgz https://github.com/OpenVPN/easy-rsa/releases/download/v3.2.0/EasyRSA-3.2.0.tgz && tar -zxvf easyrsa.tgz  && mv ./EasyRSA-3.2.0/* /etc/openvpn/easy-rsa/ && rm -rf ./EasyRSA-3.2.0 easyrsa.tgz &&
#下载是否完成
if [ ! -e "/etc/openvpn/easy-rsa/easyrsa" ]; then echo "Download EasyRSA From Github failed"; exit 1; fi
wget -O /etc/openvpn/checkpsw.sh https://raw.githubusercontent.com/qiguang0920/openvpn/master/data/checkpsw.sh
if [ ! -e "/etc/openvpn/checkpsw.sh" ]; then echo "Download checkpsw.sh From Github failed"; exit 1; fi
touch /etc/openvpn/psw-file

#easy-rsa
	mkdir -p /etc/openvpn/server/
	chown -R root:root /etc/openvpn/easy-rsa/
	cd /etc/openvpn/easy-rsa/ || exit 1
	(	
		# Create the PKI, set up the CA and the server and client certificates
		./easyrsa --batch init-pki >/dev/null
		./easyrsa --batch build-ca nopass >/dev/null 2>&1
		./easyrsa --batch --days=3650 build-server-full server nopass >/dev/null 2>&1
		./easyrsa --batch --days=3650 build-client-full $Client_Name nopass >/dev/null 2>&1
		./easyrsa --batch --days=3650 gen-dh >/dev/null 2>&1
		./easyrsa --batch --days=3650 gen-crl >/dev/null 2>&1
	)
	cp pki/ca.crt pki/private/ca.key pki/issued/server.crt pki/private/server.key pki/crl.pem pki/dh.pem /etc/openvpn/server
	chmod o+x /etc/openvpn/server/
	(
		set -x		
		openvpn --genkey --secret /etc/openvpn/server/tc.key >/dev/null
	)

cat > /etc/openvpn/server.conf  <<EOF
# 监听地址
local 0.0.0.0
# 监听端口
port $Port
# 监听协议
proto $protocol
#采用路由隧道模式,TUN模式是一种虚拟点对点的网络设备模式,通常用于实现点对点VPN,TAP模式是一种以太网桥设备模式
dev tun
;dev tap
# ca证书路径
ca /etc/openvpn/server/ca.crt
# 服务器证书
cert /etc/openvpn/server/server.crt
# This file should be kept secret 服务器
key /etc/openvpn/server/server.key
# 密钥交换协议文件
dh /etc/openvpn/server/dh.pem
auth SHA256
#tls-auth 和 tls-crypt 两种 TLS 握手策略，tls-crypt 更加的安全.tls-crypt 将使用预共享密钥对所有消息进行加密,隐藏了与OpenVPN服务器进行的TLS握手的初始化,能够防止 TLS 拒绝服务攻击
tls-crypt /etc/openvpn/server/tc.key
# TUN模式下运行时配置虚拟寻址拓扑
topology subnet
#VPN服务端为自己和客户端分配IP的地址池，服务端自己获取网段的第一个地址（这里为10.8.0.1），后为客户端分配其他的可用地址
server 10.8.0.0 255.255.255.0
#记录已分配虚拟IP的客户端和虚拟IP的对应关系,以后openvpn重启时,将可以按照此文件继续为对应的客户端分配此前相同的IP
ifconfig-pool-persist ipp.txt
# 存活时间，10秒ping一次,120 如未收到响应则视为断线
keepalive 10 120
#通信加密 须与客户端相同
cipher AES-256-GCM
#通过keepalive检测超时后，重新启动VPN,不重新读取keys,保留第一次使用的keys
persist-key
# 检测超时后，重新启动VPN，一直保持tun是linkup,否则网络会先linkdown然后再linkup
persist-tun
# 日志级别
verb 3
# 日志文件路径
log-append /var/log/openvpn.log
# 证书吊销，当特定密钥被泄露但整体 PKI 仍然完好无损时使用
crl-verify /etc/openvpn/server/crl.pem
#最多连接客户端数量
max-clients 50
#服务器所在网络
;push "route 192.168.10.0 255.255.255.0"
;push "route 192.168.20.0 255.255.255.0"
#配置密码认证，客户端需同时开启
;auth-user-pass-verify /etc/openvpn/checkpsw.sh via-env
;username-as-common-name
;script-security 3
;client-cert-not-required
EOF

if [ $protocol = "udp" ]; then
		echo "explicit-exit-notify" >> /etc/openvpn/server.conf
	fi
if [ $global = "yes" ]; then
		echo 'push "redirect-gateway def1 bypass-dhcp"'>> /etc/openvpn/server.conf
		echo 'push "dhcp-option DNS 8.8.8.8"'>> /etc/openvpn/server.conf
		echo 'push "dhcp-option DNS 1.1.1.1"'>> /etc/openvpn/server.conf
	fi
	ln /etc/openvpn/server.conf /etc/openvpn/server/server.conf
#Client
cat > /etc/openvpn/client.txt  <<EOF
client
dev tun
proto $protocol
remote $VPN_IP $Port
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
auth SHA256
cipher AES-256-GCM
;auth-user-pass
ignore-unknown-option block-outside-dns block-ipv6
verb 3
EOF

	cat /etc/openvpn/client.txt > /etc/openvpn/client/$Client_Name.ovpn
	echo "<ca>" >>/etc/openvpn/client/$Client_Name.ovpn
	cat /etc/openvpn/easy-rsa/pki/ca.crt >>/etc/openvpn/client/$Client_Name.ovpn
	echo "</ca>" >>/etc/openvpn/client/$Client_Name.ovpn
	echo "<cert>" >>/etc/openvpn/client/$Client_Name.ovpn
	sed -ne '/BEGIN CERTIFICATE/,$ p' /etc/openvpn/easy-rsa/pki/issued/$Client_Name.crt >>/etc/openvpn/client/$Client_Name.ovpn
	echo "</cert>" >>/etc/openvpn/client/$Client_Name.ovpn
	echo "<key>" >>/etc/openvpn/client/$Client_Name.ovpn
	cat /etc/openvpn/easy-rsa/pki/private/$Client_Name.key >>/etc/openvpn/client/$Client_Name.ovpn
	echo "</key>" >>/etc/openvpn/client/$Client_Name.ovpn
	echo "<tls-crypt>" >>/etc/openvpn/client/$Client_Name.ovpn
	sed -ne '/BEGIN OpenVPN Static key/,$ p' /etc/openvpn/server/tc.key >>/etc/openvpn/client/$Client_Name.ovpn
	echo "</tls-crypt>" >>/etc/openvpn/client/$Client_Name.ovpn	
	chmod 600 /etc/openvpn/client/$Client_Name.ovpn

#

firewall-cmd --add-port $Port/udp --permanent
firewall-cmd --add-port $Port/tcp --permanent
firewall-cmd --permanent --add-masquerade
firewall-cmd --permanent --add-rich-rule='rule family=ipv4 source address=10.8.0.0/24 masquerade'
firewall-cmd --reload

chmod +x /etc/openvpn/checkpsw.sh
chmod 777 /etc/openvpn/psw-file

<<'COMMMENT'
if [ ! -e /usr/lib/systemd/openvpn@server ];then
	cat > /usr/lib/systemd/openvpn@server <<EOF
[Unit]
Description=openvpn@server
After=this is a openvpn service

[Service]
Type=forking
PIDFile=/run/openvpn.pid
ExecStart=/sbin/openvpn /etc/openvpn/server.conf start
ExecReload=/sbin/openvpn /etc/openvpn/server.conf restart
ExecStop=/sbin/openvpn /etc/openvpn/server.conf stop
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF
fi
systemctl enable openvpn@server
systemctl start openvpn@server
COMMMENT

systemctl enable openvpn-server@server
systemctl start openvpn-server@server

clear
	echo -e "\033[32mOpenVPN Server Installation Complete.\033[0m"
	echo -e "External IP: \033[32m${VPN_IP}\033[0m"
	echo -e "Protocol:\033[32m${protocol}\033[0m  Port: \033[32m${Port}\033[0m"
	echo -e "Client Configuration File: \033[32m/etc/openvpn/client/$Client_Name.ovpn\033[0m"
;;

2)
while :; do echo
    read -t 20 -p "Please input Client Name: " Client_Name
	while [ -z "$Client_Name" ] ;do 
				echo " Empty name is not allowed." 
				exit
				done			
	while [[ -z "$Client_Name" || -e /etc/openvpn/easy-rsa/pki/issued/"$Client_Name".crt ]]; do
				echo "$Client_Name: Existing name." 
				exit
				done
#Rclient=$(tail -n +2 /etc/openvpn/easy-rsa/pki/index.txt | grep "^R" | cut -d '=' -f 2 | nl -s ') ')
#	if [[ $Rclient == *$Client_Name* ]]; then
#	echo "$Client_Name: Revoked name."
#	exit
#	fi			
    [ -n "$Client_Name" ] && break
	
done
VPN_IP=`curl ipv4.icanhazip.com`
cd /etc/openvpn/easy-rsa/ || exit 1
	(	
./easyrsa --batch --days=3650 build-client-full $Client_Name nopass >/dev/null 2>&1
	)
	cat /etc/openvpn/client.txt > /etc/openvpn/client/$Client_Name.ovpn
	echo "<ca>" >>/etc/openvpn/client/$Client_Name.ovpn
	cat /etc/openvpn/easy-rsa/pki/ca.crt >>/etc/openvpn/client/$Client_Name.ovpn
	echo "</ca>" >>/etc/openvpn/client/$Client_Name.ovpn
	echo "<cert>" >>/etc/openvpn/client/$Client_Name.ovpn
	sed -ne '/BEGIN CERTIFICATE/,$ p' /etc/openvpn/easy-rsa/pki/issued/$Client_Name.crt >>/etc/openvpn/client/$Client_Name.ovpn
	echo "</cert>" >>/etc/openvpn/client/$Client_Name.ovpn
	echo "<key>" >>/etc/openvpn/client/$Client_Name.ovpn
	cat /etc/openvpn/easy-rsa/pki/private/$Client_Name.key >>/etc/openvpn/client/$Client_Name.ovpn
	echo "</key>" >>/etc/openvpn/client/$Client_Name.ovpn
	echo "<tls-crypt>" >>/etc/openvpn/client/$Client_Name.ovpn
	sed -ne '/BEGIN OpenVPN Static key/,$ p' /etc/openvpn/server/tc.key >>/etc/openvpn/client/$Client_Name.ovpn
	echo "</tls-crypt>" >>/etc/openvpn/client/$Client_Name.ovpn
	chmod 600 /etc/openvpn/client/$Client_Name.ovpn
	
	clear
	echo -e "External IP: \033[32m${VPN_IP}\033[0m"
	echo -e "Client Configuration File: \033[32m/etc/openvpn/client/$Client_Name.ovpn\033[0m"
;;
3)
yum remove openvpn -y && rm -rf /etc/openvpn /usr/lib/systemd/openvpn@server	
;;
4)
			Numclient=$(tail -n +2 /etc/openvpn/easy-rsa/pki/index.txt | grep -c "^V")
			echo "Select the Client to revoke:"
			tail -n +2 /etc/openvpn/easy-rsa/pki/index.txt | grep "^V" | cut -d '=' -f 2 | nl -s ') '
			read -rp "Client: " Clientnum
			[ -z "$Clientnum" ] && exit
			until [[ "$Clientnum" =~ ^[0-9]+$ && "$Clientnum" -le "$Numclient" ]]; do
				echo "$Clientnum: invalid selection."  && exit
				read -rp "Client: " Clientnum
				[ -z "$Clientnum" ] && exit
			done
			Client=$(tail -n +2 /etc/openvpn/easy-rsa/pki/index.txt | grep "^V" | cut -d '=' -f 2 | sed -n "$Clientnum"p)
			echo "Revoking $Client..."
			cd /etc/openvpn/easy-rsa/ || exit 1
			(
					set -x
					./easyrsa --batch revoke "$Client" >/dev/null 2>&1
					./easyrsa --batch --days=3650 gen-crl >/dev/null 2>&1
			)
			rm -f /etc/openvpn/easy-rsa/pki/reqs/$Client.req
			rm -f /etc/openvpn/server/crl.pem		
			cp /etc/openvpn/easy-rsa/pki/crl.pem /etc/openvpn/server/crl.pem				
			echo "$Client revoked!"
			exit
		;;

*)
echo "Please choose a right item."
esac