import sys
from scapy.all import IP, TCP, send, sniff

sourceIPPrefix = sys.argv[1]

# Function to handle incoming SYN packets and send SYN-ACK responses
def syn_packet_handler(packet):
    # packet.show()
    if packet.haslayer(TCP) and packet.haslayer(IP) and packet[IP].src.startswith(sourceIPPrefix):
        # Check if the packet is a TCP packet, from the specified IP prefix, and has SYN flag set
        if packet[TCP].flags == 2:
            # Build the TCP SYN-ACK response
            syn_ack_response = IP(src=packet[IP].dst, dst=packet[IP].src) / TCP(sport=packet[TCP].dport, dport=packet[TCP].sport, flags='SA')

            # Send the SYN-ACK response
            send(syn_ack_response, verbose=0)

        elif packet[TCP].flags == 4:
            print("TCP RST from Dest")

# Start sniffing for incoming SYN packets, ignore my ssh connection
sniff(filter="tcp and net {}".format(sourceIPPrefix), prn=syn_packet_handler, store=0)
