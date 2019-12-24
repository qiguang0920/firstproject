#!/bin/bash
Wan_IP=`curl ipv4.icanhazip.com`
Last_IP=`cat /home/Last_IP.txt`
if [ "$Wan_IP" != "$Last_IP" ]
then
echo $Wan_IP >/home/Last_IP.txt
echo "WAN IP changed, send out alerts..."
mail -s "Your New Wlan IP" 111@gmail.com < /home/Last_IP.txt
else

        echo "Your IP Not changed."

fi

