#!/bin/bash

#arg1== destination IP
#arg2== duration in minutes

#block host from sending TCP RST due to  wrong order non RFC tcp
sudo iptables -A OUTPUT -p tcp -d $1 --tcp-flags RST RST -j DROP

#install scapy
sudo apt-get install -y python3-scapy

#import
from scapy.all import IP, TCP, send
from datetime import datetime
import sys

duration=$(($2 * 60))

# Get the start time
start_time=$(date +%s)

src_port=12250
dst_port=5221

while [ $(( $(date +%s) - start_time )) -lt $duration ]; do
    # Create a TCP SYN packet
    syn_packet = IP(dst=$1) / TCP(sport=src_port, dport=dst_port, flags='S')

    # Send the TCP SYN packet
    send(syn_packet, verbose=0)
    #print("SENT TCP SYN ", dst_ip, ":", dst_port," and ",src_port)

    # Create a TCP ACK packet
    ack_packet = IP(dst=$1) / TCP(sport=src_port, dport=dst_port, flags='A')#, seq=syn_ack_response[TCP].ack, ack=syn_ack_response[TCP].seq + 1)

    # Send the ACK packet
    send(ack_packet, verbose=0)
    #print("SENT TCP ACK ", dst_ip, ":", dst_port," and ",src_port)

    # Sleep for 5.5 to wait for TCP RSTs from VFP half open state
    sleep 5.5
done


### add client sniffer with filter for TCP RSTs from dst IP

echo "Python script loop completed."
