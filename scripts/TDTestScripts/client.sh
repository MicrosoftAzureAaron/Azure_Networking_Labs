#!/bin/bash

destIP=$1 ##$1 ${privateEndpoint_NIC.outputs.privateEndpoint_IPAddress} 
saName=$2 ##$2 ${storageAccount.outputs.storageAccount_Name} 
saDirectory=$3 ##$3 ${storageAccount.outputs.storageAccountFileShare_Name} 
saKey=$4 ##$4 ${storageAccount.outputs.storageAccount_key0}
dur=$5 ### $dur in seconds 900 is 15 minutes

#block host from sending TCP RST to PE IP due to wrong order non RFC tcp
sudo iptables -A OUTPUT -p tcp -d $destIP --tcp-flags RST RST -j DROP

#get hostname for pcapfile
hname=$(hostname)

#make mount dst for storage account via storage account private endpoint
#need to check for prior existance
mkdir /mnt/$saDirectory

#create SMB cred folder for mounting drive from storage account
if [ ! -d "/etc/smbcredentials" ]; then
    mkdir /etc/smbcredentials
fi
#no else if dir, exists no need to create it

#crate username cred file and write username pwd to file
if [ ! -f "/etc/smbcredentials/$saName.cred" ]; then
    echo "username=$saName" >> /etc/smbcredentials/$saName.cred
    echo "password=$saKey" >> /etc/smbcredentials/$saName.cred
fi
#no else if file exists, username should not exist, but if script is run after first attemp it will

#set permissions for cred file
chmod 600 /etc/smbcredentials/$saName.cred

#create permant file mount in FTSAB
echo "//$saName.file.core.windows.net/$saDirectory /mnt/$saDirectory cifs nofail,credentials=/etc/smbcredentials/$saName.cred,dir_mode=0777,file_mode=0777,serverino,nosharesock,actimeo=30" >> /etc/fstab

#mount drive 
mount -t cifs //$saName.file.core.windows.net/$saDirectory /mnt/$saDirectory -o credentials=/etc/smbcredentials/$saName.cred,dir_mode=0777,file_mode=0777,serverino,nosharesock,actimeo=30

#create folder to store PCAP based on VM name, in filesharename
mkdir /mnt/$saDirectory/$hname

#change folder permissions
chmod 600 /mnt/$saDirectory/$hname

#install scapy
sudo apt-get update
sudo apt-get install -y scapy

sudo curl -O -L https://raw.githubusercontent.com/MicrosoftAzureAaron/Azure_Networking_Labs/main/scripts/TDTestScripts/clientSCAPY.py
sudo chmod +x clientSCAPY.py

#run TCPdump in background with no hang up, for duration + 30 seconds
nohup tcpdump -timeout $(($dur + 30)) -w /mnt/$saDirectory/$hname/$hname-trace-%m-%d-%H-%M-%S.pcap host $destIP -G 3800 -C 500M -s 120 -K -n &

#run the client test script
nohup python3 clientSCAPY.py $destIP $dur &
