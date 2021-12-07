#!/bin/sh
#mayor prioridad va mas abajo!!!!

nic='eth0'

# Custom addresses
iaddr=`curl -s ipinfo.io/ip` #direccion internet
vpnuog="130.209.15.122" # gucsasa1.cent.gla.ac.uk
vpnsqa="212.219.242.194" # wportal.sqa.org.uk

#clean up
#iptables -t mangle -F # risky when using with other solutions
iptables -t mangle --new QOS_RULES || true # create chain
iptables -t mangle --flush QOS_RULES # flush chain
iptables -t mangle --check POSTROUTING -j QOS_RULES || iptables -t mangle --append POSTROUTING -j QOS_RULES # Appends to POSTROUTING


#### recorre la lista hasta al final y va marcando los paquetes. Se queda con la ultima clasificacion
#### otorgada. ej. paquete TCP 123 -> 345
#### -o $nic -p tcp --sport 123 -j CLASSIFY --set-class 0001:0150
#### -o $nic -p tcp --dport 345 -j CLASSIFY --set-class 0001:0130
#### se queda con la clasificacion 1:130 pues es la ultima que coincidio


# Default 170 (just in case)
iptables -t mangle -A QOS_RULES -o $nic -j CLASSIFY --set-class 0001:0170

## bulk traffic
iptables -t mangle -A QOS_RULES -o $nic -p tcp -m multiport --sport 20,21 -m length --length 101: -j CLASSIFY --set-class 0001:0150 -m comment --comment 'FTP'
iptables -t mangle -A QOS_RULES -o $nic -p tcp -m multiport --dport 20,21 -m length --length 101: -j CLASSIFY --set-class 0001:0150 -m comment --comment 'FTP'
iptables -t mangle -A QOS_RULES -o $nic -p tcp --dport ssh -j CLASSIFY --set-class 0001:0150 -m comment --comment 'Bulk SSH'

# ICMP, UDP
#iptables -t mangle -A QOS_RULES -o $nic -p udp -j CLASSIFY --set-class 0001:0140
iptables -t mangle -A QOS_RULES -o $nic -p udp -m length --length 1:1024 -j CLASSIFY --set-class 0001:0140 # small UDP
iptables -t mangle -A QOS_RULES -o $nic -p udp -m length --length 1024: -j CLASSIFY --set-class 0001:0140 # large UDP
iptables -t mangle -A QOS_RULES -o $nic -p icmp -m length --length 28:1500 -m limit --limit 2/s --limit-burst 5 -j CLASSIFY --set-class 0001:0140

# video calls
iptables -t mangle -A QOS_RULES -o $nic -p tcp -m multiport --dport 5222 -j CLASSIFY --set-class 0001:0140 # whatsapp ?
iptables -t mangle -A QOS_RULES -o $nic -p tcp -m multiport --dport 5223 -j CLASSIFY --set-class 0001:0140 # facetime ?


# mail and web traffic
iptables -t mangle -A QOS_RULES -o $nic -p tcp -m multiport --dport http,imap,https,imaps,8080,3128 -j CLASSIFY --set-class 0001:0130

# IoT Devices
iptables -t mangle -A QOS_RULES -s 192.168.8.123/32 -o $nic -j CLASSIFY --set-class 0001:0160 # smart-tv



# interactive SSH traffic and known VPNs
iptables -t mangle -A QOS_RULES -o $nic -p tcp --dport ssh -m length --length 1:300 -j CLASSIFY --set-class 0001:0120
iptables -t mangle -A QOS_RULES --destination $vpnuog/32 -o $nic -j CLASSIFY --set-class 0001:0120 # UoG
iptables -t mangle -A QOS_RULES --destination $vpnsqa/32 -o $nic -j CLASSIFY --set-class 0001:0120 # SQA

# dns lookups
iptables -t mangle -A QOS_RULES -o $nic -p tcp --dport 53 -j CLASSIFY --set-class 0001:0120 # standard port
iptables -t mangle -A QOS_RULES -o $nic -p tcp --dport 853 -j CLASSIFY --set-class 0001:0120 # TLS port

# give "overhead" packets highest priority
iptables -t mangle -A QOS_RULES -o $nic -p tcp --syn -m length --length 40:68 -j CLASSIFY --set-class 0001:0110
iptables -t mangle -A QOS_RULES -o $nic -p tcp --tcp-flags ALL SYN,ACK -m length --length 40:68 -j CLASSIFY --set-class 0001:0110
iptables -t mangle -A QOS_RULES -o $nic -p tcp --tcp-flags ALL ACK -m length --length 40:100 -j CLASSIFY --set-class 0001:0110
iptables -t mangle -A QOS_RULES -o $nic -p tcp --tcp-flags ALL RST -j CLASSIFY --set-class 0001:0110
iptables -t mangle -A QOS_RULES -o $nic -p tcp --tcp-flags ALL ACK,RST -j CLASSIFY --set-class 0001:0110
iptables -t mangle -A QOS_RULES -o $nic -p tcp --tcp-flags ALL ACK,FIN -j CLASSIFY --set-class 0001:0110


