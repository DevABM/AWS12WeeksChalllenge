# Useful Commands 

## Suricata Commands

##### Add Suricata Rules - All Traffic
echo "alert ip any any -> any any (msg:\"traffic logged\";sid:999;rev:1;)" >> /var/lib/suricata/rules/suricata.rules

#### Restart Suricata in order to apply rules
systemctl restart suricata && systemctl status suricata

#### View logged Suricata Traffic
tail /var/log/suricata/fast.log -f

#### View logged Suricata ICMP Traffic
tail /var/log/suricata/fast.log -f | grep ICMP

#### Suricata rules to add: Drop Facebook
echo "drop tcp any any -> any 443 (msg: \"facebook rule\"; tls.sni; content:\"facebook.com\"; nocase; pcre:\"/facebook.com$/\"; sid:10; priority: 1; rev:1;)" >> /var/lib/suricata/rules/suricata.rules

#### Suricata rules to add: Drop Google
echo "drop tcp any any -> any 443 (msg: \"google rule\"; tls.sni; content:\"google.com\"; nocase; pcre:\"/google.com$/\"; sid:11; priority: 1; rev:1;)" >> /var/lib/suricata/rules/suricata.rules

#### Restart Suricata after rule changes
systemctl restart suricata

## Troubleshooting Commands

#### To check if you are receiving ICMP pings from another host: 
tcpdump -i any proto ICMP –nn 
 
#### To look at all of the data traversing a NIC: 
tcpdump -i eth0 
tcpdump -i eth0 icmp 
 
#### To check if the pings are going across the Suricata instance to the internet on the port 
sudo tcpdump -nvv port 6081 

## Installing and using Iperf

#### Command to install iPerf
yum -y install  https://dl.fedoraproject.org/pub/archive/epel/6/x86_64/epel-release-6-8.noarch.rpm  && yum -y install iperf

#### Command to install iPerf3 and iPerf
sudo yum --enablerepo=epel install iperf iperf3

#### Iperf command for server side 
iperf3 -s -p 5051 -i 2 
 
#### Iperf Command for sending 40GB file on client side 
iperf3 -c 10.1.2.10 -n 40000m -i 2 -p 5051