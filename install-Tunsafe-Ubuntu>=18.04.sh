#!/bin/bash
echo "安装相关组件"
    apt update -y
    apt- install -y git curl make rand clang-6.0 qrencode
echo "安装......"
    git clone https://github.com/TunSafe/TunSafe.git
    cd TunSafe
    make && sudo make install
echo "开启路由转发与BBR"
    echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
    echo "net.ipv6.conf.all.forwarding = 1" >> /etc/sysctl.conf
    echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
    echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
    sysctl -p
echo "配置"
    mkdir /etc/tunsafe
    cd /etc/tunsafe
    tunsafe genkey | tee sprivatekey | tunsafe pubkey > spublickey
    tunsafe genkey | tee cprivatekey | tunsafe pubkey > cpublickey
    s1=$(cat sprivatekey)
    s2=$(cat spublickey)
    c1=$(cat cprivatekey)
    c2=$(cat cpublickey)
    serverip=$(curl ipv4.icanhazip.com)
    obfsstr=$(cat /dev/urandom | head -1 | md5sum | head -c 8)
    port=443
    eth=$(ls /sys/class/net | awk '/^e/{print}')

sudo cat > /etc/tunsafe/TunSafe.conf <<-EOF
[Interface]
PrivateKey = $s1
Address = 10.0.0.1/24
ObfuscateKey = $obfsstr
ObfuscateTCP=tls-chrome
ListenPortTCP = $port
PostUp   = iptables -A FORWARD -i tun0 -j ACCEPT;iptables -A FORWARD -o tun0 -j ACCEPT;iptables -t nat -A POSTROUTING -o $eth -j MASQUERADE
PostDown = iptables -D FORWARD -i tun0 -j ACCEPT;iptables -D FORWARD -o tun0 -j ACCEPT;iptables -t nat -D POSTROUTING -o $eth -j MASQUERADE
BlockDNS = true
DNS = 1.1.1.1
MTU = 1420

[Peer]
PublicKey = $c2
AllowedIPs = 10.0.0.2/32
EOF


sudo cat > /etc/tunsafe/client.conf <<-EOF
[Interface]
PrivateKey = $c1
Address = 10.0.0.2/24
ObfuscateKey = $obfsstr
ObfuscateTCP=tls-chrome
BlockDNS = true
DNS = 1.1.1.1
MTU = 1420

[Peer]
PublicKey = $s2
Endpoint = tcp://$serverip:$port
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
EOF
echo "显示客户端配置"
echo "==============================================="
cat /etc/tunsafe/client.conf
echo "==============================================="
echo "开机自启"
echo "tunsafe start -d /etc/tunsafe/TunSafe.conf" >> /etc/rc.local
echo "启动"
tunsafe start -d /etc/tunsafe/TunSafe.conf
