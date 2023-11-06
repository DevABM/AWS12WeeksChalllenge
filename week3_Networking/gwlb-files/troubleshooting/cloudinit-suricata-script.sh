Content-Type: multipart/mixed; boundary="//"
MIME-Version: 1.0

--//
Content-Type: text/cloud-config; charset="us-ascii"
MIME-Version: 1.0
Content-Transfer-Encoding: 7bit
Content-Disposition: attachment; filename="cloud-config.txt"

#cloud-config
cloud_final_modules:
- [scripts-user, always]

--//
Content-Type: text/x-shellscript; charset="us-ascii"
MIME-Version: 1.0
Content-Transfer-Encoding: 7bit
Content-Disposition: attachment; filename="userdata.txt"

#!/bin/bash -xe
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
echo "Installing Necessary Updates"
yum update -y
amazon-linux-extras install epel -y
yum -y install gcc libpcap-devel pcre-devel libyaml-devel file-devel zlib-devel jansson-devel nss-devel libcap-ng-devel libnet-devel tar make libnetfilter_queue-devel lua-devel PyYAML libmaxminddb-devel lz4-devel supervisor gzip
pip3 install pyaml
echo "Installing Rust and downgrading to 1.52.1"
curl https://sh.rustup.rs -sSf | sh -s -- --profile minimal --default-toolchain 1.52.1 --no-modify-path -y
#cargo update -p lexical-core
echo "Setting Home Path"
####Causing Issues with Script
#echo "export PATH="$HOME/.cargo/bin:$PATH"" >> ~/.bash_profile
PATH="/root/.cargo/bin:$PATH"
export PATH
source "/root/.cargo/env"
#export PATH="$HOME/.cargo/bin:$PATH"
#export PATH="root/.cargo/bin:$PATH"
yum clean all
#rm -rf /var/cache/yum /var/lib/suricata/rules /etc/cron.*/*
echo "Implenenting change to rust source configuration"
#Exporting Suricata files and unziping
if [ ! -d "/tmp/suricata-6.0.0" ]; then
    echo "Downloading and Creating Suricata Folder"
    curl -s https://www.openinfosecfoundation.org/download/suricata-6.0.0.tar.gz -o /tmp/suricata-6.0.0.tar.gz
    tar -zxvf /tmp/suricata-6.0.0.tar.gz -C /tmp/
else
    echo "Suricata Folder Already Created"
fi
echo "Configuring Suricata"
cd "/tmp/suricata-6.0.0/"
./configure --prefix=/usr/ --sysconfdir=/etc --localstatedir=/var/ --enable-lua --enable-geoip --enable-nfqueue
echo "Configuring Make"
make
echo "Configuring ldconfig"
ldconfig
echo "Configuring Full Install"
make install-full
#Configures Suricata Service
echo "Configuring systemctl configurations"
cp "/tmp/suricata-6.0.0/etc/suricata.service" "/etc/systemd/system/suricata.service"
sed -i "/ExecStart=/c\ExecStart=/bin/suricata -c /etc/suricata/suricata.yaml --pidfile /var/run/suricata.pid -q 0" "/etc/systemd/system/suricata.service"
mv "/var/lib/suricata/rules/suricata.rules" "/tmp/suricata-6.0.0/rulebackup.rules"
cat "/dev/null" > "/var/lib/suricata/rules/suricata.rules"
#Initialise Suricata
echo "Initialise Suricata"
systemctl daemon-reload
systemctl start suricata
systemctl enable suricata
#Adds to the end of the file systl.conf file
# netforward="net.ipv4.ip_forward = 1"
# sysctlfile="/etc/sysctl.conf"
# isinfile=$(cat $sysctlfile | grep -c "$netforward")
# if [ $isinfile -eq 0 ]; then
#     echo "Netforward being added"
#     echo "net.ipv4.ip_forward = 1" >> "/etc/sysctl.conf"
#     sysctl -p "$sysctlfile"
# else
#     echo "Netforward Rule added already"
#     sysctl -p "$sysctlfile"
# fi
echo "net.ipv4.ip_forward = 1" >> "/etc/sysctl.conf"
sysctl -p "/etc/sysctl.conf"
# Install IPtables
yum install iptables-services -y
systemctl start iptables
systemctl enable iptables
echo "Installed IP Tables"
#Configure Base IP Tables
iptables -t nat -F
iptables -t mangle -F
iptables -F
iptables -X
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT
iptables -I FORWARD -j NFQUEUE
echo "Base configuration for IP tables completed"
#Define GWLB Variables
AGW_IP=10.0.4.67
AGW2_IP=10.0.5.9
INSTANCE_IP=$(ip -4 addr show eth1 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
export AGW_IP
export AGW2_IP
export INSTANCE_IP
#Add to IP Table Configuration
iptables -t nat -A PREROUTING -p udp -s $AGW_IP -d "$INSTANCE_IP" -i eth1 -j DNAT --to-destination $AGW_IP:6081
iptables -t nat -A PREROUTING -p udp -s $AGW2_IP -d "$INSTANCE_IP" -i eth1 -j DNAT --to-destination $AGW2_IP:6081
iptables -t nat -A POSTROUTING -p udp --dport 6081 -s $AGW_IP -d $AGW_IP -o eth1 -j MASQUERADE
iptables -t nat -A POSTROUTING -p udp --dport 6081 -s $AGW2_IP -d $AGW2_IP -o eth1 -j MASQUERADE
echo "IP Table Forwarding Complete"
#Save results and restart services
service iptables save
ldconfig
systemctl restart iptables
systemctl restart suricata.service
#Adding Alert rules to Suricata Rules
echo "alert ip any any -> any any (msg:\"traffic logged\";sid:999;rev:1;)" > /var/lib/suricata/rules/suricata.rules
systemctl restart suricata && systemctl status suricata
echo "Installation Complete"