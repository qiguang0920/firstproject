#!/bin/bash
clear
printf "
#####################################################################
#                Install NAMED for CentOS 	                        #
#            More information http://www.iewb.net                   #
#####################################################################
"
ip=`ip addr |grep "inet"|grep -v "127.0.0.1"|grep -v "inet6" |cut -d: -f2|awk '{print $2}'|awk -F '/' '{print $1}'`
if [ ! -e /etc/named.conf ];then
yum -y install bind
fi
if [ -e /etc/named.conf ];then
sed -i "s/listen-on port 53 { 127.0.0.1/listen-on port 53 { 127.0.0.1;$ip/g" /etc/named.conf
sed -i 's/allow-query     { localhost; }/allow-query     { any; }/g' /etc/named.conf
sed -i '20a\forwarders {' /etc/named.conf
sed -i '21a\                     199.85.126.10;' /etc/named.conf
sed -i '22a\                     1.1.1.1;' /etc/named.conf
sed -i '23a\                     8.8.8.8;' /etc/named.conf
sed -i '24a\                     8.8.4.4;' /etc/named.conf
sed -i '25a\};' /etc/named.conf
else
echo "/etc/named.confnot found,maybe bind install false."
fi
if [ -e /etc/named.rfc1912.zones ];then
sed -i '24a\zone "test.com" IN {' /etc/named.rfc1912.zones
sed -i '25a\        type master;' /etc/named.rfc1912.zones
sed -i '26a\        file "test.com.zone";' /etc/named.rfc1912.zones
sed -i '27a\};' /etc/named.rfc1912.zones
else
echo "/etc/named.rfc1912.zones not found,maybe bind install false."
fi
if [ -d /var/named ];then
cat > /var/named/test.com.zone << EOF
@       IN SOA  @ ns1.test.com.root.(
                                        31536000        ; serial
                                        10M     ; refresh
                                        3M      ; retry
                                        1D      ; expire
                                        3D )    ; minimum
        NS      ns1
        A       172.16.88.13
;       AAAA    ::1
ns1     A       172.16.88.12
admin   A       172.16.88.13
1       A       172.16.88.13
EOF
sed -i '1i\$TTL 1D' /var/named/test.com.zone
fi
setenforce 0
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
firewall-cmd --add-service=dns
firewall-cmd --reload
systemctl restart named
systemctl enable named
