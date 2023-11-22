#!/bin/bash

saName=$1 ### ${storageAccount.outputs.storageAccount_Name} 
saDirectory=$2 ### ${storageAccount.outputs.storageAccountFileShare_Name} 
saKey=$3 ### ${storageAccount.outputs.storageAccount_key0}'
sourceIPPrefix=$4 ### ${virtualNetwork_Client.outputs.virtualNetwork_AddressPrefix}

#get hostname for pcapfile
hname=$(hostname)

#make mount dst for storage account via private endpoint
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
#no else if file exists

#set permissions for cred file
chmod 600 /etc/smbcredentials/$saName.cred

#create permant file mount in FTSAB
echo "//$saName.file.core.windows.net/$saDirectory /mnt/$saDirectory cifs nofail,credentials=/etc/smbcredentials/$saName.cred,dir_mode=0777,file_mode=0777,serverino,nosharesock,actimeo=30" >> /etc/fstab

#mount drive 
mount -t cifs //$saName.file.core.windows.net/$saDirectory /mnt/$saDirectory -o credentials=/etc/smbcredentials/$saName.cred,dir_mode=0777,file_mode=0777,serverino,nosharesock,actimeo=30

#create folder to store PCAP based on VM name
mkdir /mnt/$saDirectory/$hname

#change folder permissions
chmod 600 /mnt/$saDirectory/$hname

#install scapy
sudo apt-get update
sudo apt-get install -y scapy

curl -O -L https://raw.githubusercontent.com/MicrosoftAzureAaron/Azure_Networking_Labs/main/scripts/TDTestScripts/serverSCAPY.py

#run TCPdump in background with no hang up, for duration + 30 seconds
nohup tcpdump -timeout $(($dur + 300)) -w /mnt/$saDirectory/$hname/$hname-trace-%m-%d-%H-%M-%S.pcap net $sourceIPPrefix -G 3800 -C 500M -s 120 -K -n &

python3 serverSCAPY.py $sourceIPPrefix $dur

pause 300

