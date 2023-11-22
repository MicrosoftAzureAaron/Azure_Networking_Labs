#import scapy func
from scapy.all import IP, TCP, send, sniff

# Function to handle incoming SYN packets and send SYN-ACK responses
def syn_packet_handler(packet):
    #packet.show()
    if packet[TCP].flags == 2: # is packet TCP and from IP Prefix (filter) and is SYN Flag set?
        # Build the TCP SYN-ACK response
        syn_ack_response = IP(src=packet[IP].dst, dst=packet[IP].src) / TCP(sport=packet[TCP].dport, dport=packet[TCP].sport, flags='SA')

        # Send the SYN-ACK response
        send(syn_ack_response, verbose=0)

    if packet[TCP].flags == 4:
        print("TCP RST from Dest")
        
# Start sniffing for incoming SYN packets, ignore my ssh connection
sniff(filter="tcp and net $sourceIPPrefix", prn=syn_packet_handler, store=0)

