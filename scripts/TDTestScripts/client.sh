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
sudo apt-get install -y python3-scapy

#import
from scapy.all import IP, TCP, send
from datetime import datetime
import sys

# Get the start time
start_time=$(date +%s)

src_port=12250
dst_port=5221

#run TCPdump in background with no hang up, for duration + 30 seconds
nohup tcpdump -timeout $(($dur + 30)) -w /mnt/$saDirectory/$hname/$hname-trace-%m-%d-%H-%M-%S.pcap host $destIP -G 3800 -C 500M -s 120 -K -n &

#start sending out of order TCP packets
while [ $(( $(date +%s) - start_time )) -lt $dur ]; do
    # Create a TCP SYN packet
    syn_packet = IP(dst=$destIP) / TCP(sport=src_port, dport=dst_port, flags='S')

    # Send the TCP SYN packet
    send(syn_packet, verbose=0)
    #print("SENT TCP SYN ", dst_ip, ":", dst_port," and ",src_port)

    # Create a TCP ACK packet
    ack_packet = IP(dst=$destIP) / TCP(sport=src_port, dport=dst_port, flags='A')#, seq=syn_ack_response[TCP].ack, ack=syn_ack_response[TCP].seq + 1)

    # Send the ACK packet
    send(ack_packet, verbose=0)
    #print("SENT TCP ACK ", dst_ip, ":", dst_port," and ",src_port)

    # Sleep for 5.5 to wait for TCP RSTs from VFP half open state
    sleep 5.5
    # replace sleep with new source port and retry as fast as possible till first port has been unused for 6 seconds
done

### add client sniffer with filter for TCP RSTs from dst IP
## currently tcp dump captures all packets
sleep 30
echo "Python script loop completed."

