#!/bin/sh
yum install git vim wget -y
yum install epel-release -y
yum install gcc gettext autoconf libtool automake make pcre-devel asciidoc xmlto c-ares-devel libev-devel libsodium-devel mbedtls-devel -y

[ ! -e '/usr/bin/curl' ] && yum -y install curl
ip=`ip addr |grep "inet"|grep -v "127.0.0.1"|grep -v "inet6" |cut -d: -f2|awk '{print $2}'|awk -F '/' '{print $1}'`
ip2=`curl ipv4.icanhazip.com`
git clone https://github.com/shadowsocks/shadowsocks-libev.git
cd shadowsocks-libev
git submodule update --init --recursive
./autogen.sh && ./configure --prefix=/usr && make
make install
yum install zlib-devel openssl-devel -y
git clone https://github.com/shadowsocks/simple-obfs.git
cd simple-obfs
git submodule update --init --recursive
./autogen.sh
./configure && make
make install

PORT1="10000"
PWD1="botonet123"


while :; do echo
    read -p "Please input the first port you will be use: " PORT1 
    [ -n "$PORT1" ] && break
done

while :; do echo
    read -p "Please input password for the first port: " PWD1
    [ -n "$PWD1" ] && break
done

mkdir -p /etc/shadowsocks-libev
touch /etc/shadowsocks-libev/config.json
        cat > /etc/shadowsocks-libev/config.json << EOF
{
"server":"0.0.0.0",
	"server_port":$PORT1,
	"local_port":1080,
	"password":"$PWD1",
	"timeout":60,
	"method":"aes-256-cfb",
	"plugin":"obfs-server",
	"plugin_opts":"obfs=http"
}
EOF

touch /usr/lib/systemd/system/shadowsocks.service
	cat > /usr/lib/systemd/system/shadowsocks.service <<EOF
[Unit]
Description=Shadowsocks Server
After=network.target
[Service]
ExecStart=/usr/bin/ss-server -c /etc/shadowsocks-libev/config.json -u
Restart=on-abort
[Install]
WantedBy=multi-user.target
EOF

chmod 754 /usr/lib/systemd/system/shadowsocks.service
systemctl enable shadowsocks
systemctl start shadowsocks
firewall-cmd --add-port=$PORT1/tcp --permanent
firewall-cmd --reload

echo -e "You can now connect to your Shadowsocks via your external IP \033[32m${ip2}\033[0m"
echo -e "Port: \033[32m${PORT1}\033[0m" "Password: \033[32m${PWD1}\033[0m"
echo -e "Local_port: \033[32m 1080\033[0m"
echo -e "Method: \033[32m aes-256-cfb \033[0m"
