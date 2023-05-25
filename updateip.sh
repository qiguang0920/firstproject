#!/bin/bash
Wan_IP=`curl -s https://api-ipv4.ip.sb/ip`
Last_IP=`cat /home/Last_IP.txt`
if [[ $Wan_IP =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]] && [ "$Wan_IP" != "$Last_IP" ]
then
echo $Wan_IP >/home/Last_IP.txt
echo "WAN IP changed, send out alerts..."
mail -s "Your New Wlan IP" test@gmail.com < /home/Last_IP.txt
else

        echo "Your IP Not changed."
fi
