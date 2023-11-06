#!/bin/bash

iptables -t nat -F
iptables -t mangle -F
iptables -F
iptables -X

iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT

iptables -I FORWARD -j NFQUEUE

export AGW_IP=10.0.4.152
export AGW2_IP=10.0.5.147
export INSTANCE_IP=$(ip -4 addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')

iptables -t nat -A PREROUTING -p udp -s $AGW_IP -d $INSTANCE_IP -i eth0 -j DNAT --to-destination $AGW_IP:6081
iptables -t nat -A PREROUTING -p udp -s $AGW2_IP -d $INSTANCE_IP -i eth0 -j DNAT --to-destination $AGW2_IP:6081
iptables -t nat -A POSTROUTING -p udp --dport 6081 -s $AGW_IP -d $AGW_IP -o eth0 -j MASQUERADE
iptables -t nat -A POSTROUTING -p udp --dport 6081 -s $AGW2_IP -d $AGW2_IP -o eth0 -j MASQUERADE

service iptables save
systemctl restart iptables
systemctl restart suricata