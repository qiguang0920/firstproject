#!/bin/bash
clear
printf "
#####################################################################
#                Install NAMED for CentOS 	                    #
#            More information http://www.iewb.net                   #
#####################################################################
"
ip=`ip addr |grep "inet"|grep -v "127.0.0.1"|grep -v "inet6" |cut -d: -f2|awk '{print $2}'|awk -F '/' '{print $1}'`
if [ ! -e /etc/named.conf ];then
yum -y install bind
fi
if [ -e /etc/named.conf ];then
sed -i "s/listen-on port 53 { 127.0.0.1/listen-on port 53 { 127.0.0.1;$ip/g" /etc/named.conf
sed -i 's?listen-on-v6 port 53 { ::1; };?//listen-on-v6 port 53 { ::1; };?g' /etc/named.conf        
sed -i 's/allow-query     { localhost; }/allow-query     { any; }/g' /etc/named.conf
sed -i '20a\//forwarders {' /etc/named.conf
sed -i '21a\//                     203.80.96.10;' /etc/named.conf
sed -i '22a\//                     168.95.192.1;' /etc/named.conf
sed -i '23a\//                     4.2.2.1;' /etc/named.conf
sed -i '24a\//                     8.8.8.8;' /etc/named.conf
sed -i '25a\//};' /etc/named.conf
sed -i '26a\querylog yes;' /etc/named.conf
else
echo "/etc/named.confnot found,maybe bind install false."
fi
if [ -e /etc/named.rfc1912.zones ];then
sed -i '$a\zone "test.com" IN {' /etc/named.rfc1912.zones
sed -i '$a\        type master;' /etc/named.rfc1912.zones
sed -i '$a\        file "test.com.zone";' /etc/named.rfc1912.zones
sed -i '$a\};' /etc/named.rfc1912.zones
sed -i '$a\zone "88.16.172.in-addr.arpa" IN {' /etc/named.rfc1912.zones
sed -i '$a\        type master;' /etc/named.rfc1912.zones
sed -i '$a\    file "172.16.88.zone";' /etc/named.rfc1912.zones
sed -i '$a\};' /etc/named.rfc1912.zones
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
					3D)	;minimum
        NS      ns1
        A       172.16.88.13
;        AAAA    ::1
ns1     A       172.16.88.12
admin   A       172.16.88.13
mail	A       172.16.88.13
c       CNAME   2345.com.
c2      CNAME   admin
@       MX      5	mail
@       TXT     "v=spf1 include:spf mail.test.com test.com ~all"
EOF
sed -i '1i\$TTL 1D' /var/named/test.com.zone
fi

if [ -d /var/named ];then
cat > /var/named/172.16.88.zone << EOF
@       IN SOA  @ ns1.test.com.invalid.(
                                        31536000        ; serial
                                        10M     ; refresh
                                        3M      ; retry
                                        1D      ; expire
					3D)	;minimum
        IN      NS      ns1.test.com.
;        AAAA    ::1
        PTR     localhost.
12      IN      PTR     ns1.test.com.
13      IN      PTR     admin.test.com.
13      IN      PTR     mail.test.com.
        IN      MX      5	mail.test.com.
EOF
sed -i '1i\$TTL 1D' /var/named/172.16.88.zone
fi
sed -i '$a\OPTIONS="-4"' /etc/sysconfig/named
setenforce 0
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
firewall-cmd --add-service=dns --permanent
firewall-cmd --reload
systemctl restart named
systemctl enable named
