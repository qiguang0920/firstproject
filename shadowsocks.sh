#!/bin/sh
yum install epel-release -y
yum install python-setuptools m2crypto supervisor -y
easy_install pip
pip install shadowsocks

[ ! -e '/usr/bin/curl' ] && yum -y install curl
ip=`ip addr |grep "inet"|grep -v "127.0.0.1"|grep -v "inet6" |cut -d: -f2|awk '{print $2}'|awk -F '/' '{print $1}'`
ip2=`curl ipv4.icanhazip.com`

PORT1="10000"
PORT2="10001"
PWD1="botonet123"
PWD2="botonet123"

while :; do echo
    read -p "Please input the first port you will be use: " PORT1 
    [ -n "$PORT1" ] && break
done
while :; do echo
    read -p "Please input the second port you will be use: " PORT2 
    [ -n "$PORT2" ] && break
done


while :; do echo
    read -p "Please input password for the first port: " PWD1
    [ -n "$PWD1" ] && break
done

while :; do echo
    read -p "Please input password for the second port: " PWD2
    [ -n "$PWD2" ] && break

done

touch /etc/shadowsocks.json
        cat > /etc/shadowsocks.json << EOF
{
"server":"$ip",
"local_address": "127.0.0.1",
"local_port":1080,
"port_password":
{
"$PORT1":"$PWD1",
"$PORT2":"$PWD2"
},
"timeout":600,
"method":"rc4-md5"
}
EOF

touch /usr/lib/systemd/system/shadowsocks.service
	cat > /usr/lib/systemd/system/shadowsocks.service <<EOF
[Unit]
Description=shadowsocks
After=network.target remote-fs.target nss-lookup.target
[Service]
Type=forking
PIDFile=/run/shadowsocks.pid
ExecStart=/usr/bin/ssserver -c /etc/shadowsocks.json -d start
ExecReload=/usr/bin/ssserver -c /etc/shadowsocks.json -d restart
ExecStop=/usr/bin/ssserver -c /etc/shadowsocks.json -d stop
PrivateTmp=true
[Install]
WantedBy=multi-user.target
EOF

chmod 754 /usr/lib/systemd/system/shadowsocks.service
systemctl enable shadowsocks
systemctl start shadowsocks
firewall-cmd --add-port=$PORT1/tcp --permanent
firewall-cmd --add-port=$PORT2/tcp --permanent
firewall-cmd --reload
echo -e "now you can connect to your Shadowsocks via your external IP \033[32m${ip2}\033[0m"
echo -e "Port1: \033[32m${PORT1}\033[0m" "Password: \033[32m${PWD1}\033[0m"
echo -e "Port2: \033[32m${PORT2}\033[0m" "Password: \033[32m${PWD2}\033[0m"
echo -e "Local_port: \033[32m 1080\033[0m"
echo -e "Method: \033[32m RC4-MD5 \033[0m"
