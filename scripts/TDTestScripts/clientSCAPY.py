# script.py
from scapy.all import IP, TCP, send
import sys
from datetime import datetime
import time

destIP = sys.argv[1]
dur = int(sys.argv[2])  # Convert duration to an integer

# Get the start time
start_time = time.time()

src_port = 12250
dst_port = 5221

# Start sending out-of-order TCP packets
while time.time() - start_time < dur:
    # Create a TCP SYN packet
    syn_packet = IP(dst=destIP) / TCP(sport=src_port, dport=dst_port, flags='S')

    # Send the TCP SYN packet
    send(syn_packet, verbose=0)
    # print("SENT TCP SYN ", destIP, ":", dst_port, " and ", src_port)

    # Create a TCP ACK packet
    ack_packet = IP(dst=destIP) / TCP(sport=src_port, dport=dst_port, flags='A')

    # Send the ACK packet
    send(ack_packet, verbose=0)
    # print("SENT TCP ACK ", destIP, ":", dst_port, " and ", src_port)

    # Sleep for 5.5 to wait for TCP RSTs from VFP half-open state
    time.sleep(5.5)
    # replace sleep with new source port and retry as fast as possible till the first port has been unused for 6 seconds

print("Python script loop completed.")