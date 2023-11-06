# Commands in order to install Suricata Manually

# Elevate and install updates
sudo -s
amazon-linux-extras install -y epel
yum update -y

yum -y install gcc libpcap-devel pcre-devel libyaml-devel file-devel zlib-devel jansson-devel nss-devel libcap-ng-devel libnet-devel tar make libnetfilter_queue-devel lua-devel PyYAML libmaxminddb-devel lz4-devel supervisor gzip

pip3 install pyaml

# Install Rust with required Version
curl https://sh.rustup.rs -sSf | sh -s -- --profile minimal --default-toolchain 1.52.1 --no-modify-path -y 

# Restart your shell
source "$HOME/.cargo/env"

# You can also manually downgrade Rust if needed, but command above does so already
rustup install 1.52.0
export RUSTUP_TOOLCHAIN=1.52.0

# Download Suricata to /tmp folder
wget -P /tmp https://www.openinfosecfoundation.org/download/suricata-6.0.0.tar.gz

# Navigate to /tmp folder and unzip file
cd /tmp
tar -zxvf suricata-6.0.0.tar.gz

# Start compiling Suricata
cd suricata-6.0.0/
./configure --prefix=/usr/ --sysconfdir=/etc --localstatedir=/var/ --enable-lua --enable-geoip --enable-nfqueue
make 
ldconfig
make install-full

# Copy Suricata service to systemd
cp /tmp/suricata-6.0.0/etc/suricata.service /etc/systemd/system/suricata.service

# Update local binaries
sed -i "/ExecStart=/c\ExecStart=/bin/suricata -c /etc/suricata/suricata.yaml --pidfile /var/run/suricata.pid -q 0" /etc/systemd/system/suricata.service

# Backup rules and empty the original rules
mv /var/lib/suricata/rules/suricata.rules /tmp/suricata-6.0.0/rulebackup.rules
cat /dev/null > /var/lib/suricata/rules/suricata.rules

# Configure forwarding on the EC2 instance
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
sysctl -p /etc/sysctl.conf

# Install IPtables
yum install iptables-services -y
systemctl start iptables
systemctl enable iptables

# Flush the nat and mangle tables, flush all chains (-F), and delete all non-default chains (-X):
iptables -t nat -F
iptables -t mangle -F
iptables -F
iptables -X

# Set the default policies for each of the built-in chains to ACCEPT:
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT

# Set a punt to Suricata via NFQUEUE
iptables -I FORWARD -j NFQUEUE

# Variables ( This will be specific to your GWLB deployment - this config supports x-zone load balancing)
export AGW_IP=x.x.x.x [This is  the GWLB LB IP in AZ1]
export AGW2_IP=x.x.x.x [This is the GWLB LB IP in AZ2]
export INSTANCE_IP=x.x.x.x [This is the local IP address of the instance]

# Configure nat table to hairpin traffic back to GWLB:
iptables -t nat -A PREROUTING -p udp -s $AGW_IP -d $INSTANCE_IP -i eth1 -j DNAT --to-destination $AGW_IP:6081
iptables -t nat -A PREROUTING -p udp -s $AGW2_IP -d $INSTANCE_IP -i eth1 -j DNAT --to-destination $AGW2_IP:6081
iptables -t nat -A POSTROUTING -p udp --dport 6081 -s $AGW_IP -d $AGW_IP -o eth1 -j MASQUERADE
iptables -t nat -A POSTROUTING -p udp --dport 6081 -s $AGW2_IP -d $AGW2_IP -o eth1 -j MASQUERADE

# Save iptables: 
service iptables save

# Restart Suricata
systemctl status suricata

# Add Suricata Rules - All Traffic
echo "alert ip any any -> any any (msg:\"traffic logged\";sid:999;rev:1;)" >> /var/lib/suricata/rules/suricata.rules

# Restart Suricata in order to apply rules
systemctl restart suricata && systemctl status suricata

# View logged Suricata Traffic
tail /var/log/suricata/fast.log -f

# View logged Suricata ICMP Traffic
tail /var/log/suricata/fast.log -f | grep ICMP

# Suricata rules to add: Drop Facebook
echo "drop tcp any any -> any 443 (msg: \"facebook rule\"; tls.sni; content:\"facebook.com\"; nocase; pcre:\"/facebook.com$/\"; sid:10; priority: 1; rev:1;)" >> /var/lib/suricata/rules/suricata.rules

# Suricata rules to add: Drop Google
echo "drop tcp any any -> any 443 (msg: \"google rule\"; tls.sni; content:\"google.com\"; nocase; pcre:\"/google.com$/\"; sid:11; priority: 1; rev:1;)" >> /var/lib/suricata/rules/suricata.rules

# Restart Suricata after rule changes
systemctl restart suricata

# Drop all ICMP traffic to 1.1.1.1
echo "drop icmp any any -> 1.1.1.1 any (msg: \"1.1.1.1 drop rule\"; sid:200; )" >> /var/lib/suricata/rules/suricata.rules

# Restart Suricata 
systemctl restart suricata


