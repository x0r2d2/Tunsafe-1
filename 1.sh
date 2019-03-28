#!/bin/bash
#echo "更换国内源"
#echo "deb https://mirrors.ustc.edu.cn/ubuntu/ cosmic main restricted universe multiverse
#deb-src https://mirrors.ustc.edu.cn/ubuntu/ cosmic main restricted universe multiverse
#deb https://mirrors.ustc.edu.cn/ubuntu/ cosmic-updates main restricted universe multiverse
#deb-src https://mirrors.ustc.edu.cn/ubuntu/ cosmic-updates main restricted universe multiverse
#deb https://mirrors.ustc.edu.cn/ubuntu/ cosmic-backports main restricted universe multiverse
#deb-src https://mirrors.ustc.edu.cn/ubuntu/ cosmic-backports main restricted universe multiverse
#deb https://mirrors.ustc.edu.cn/ubuntu/ cosmic-security main restricted universe multiverse
#deb-src https://mirrors.ustc.edu.cn/ubuntu/ cosmic-security main restricted universe multiverse
#deb https://mirrors.ustc.edu.cn/ubuntu/ cosmic-proposed main restricted universe multiverse
#deb-src https://mirrors.ustc.edu.cn/ubuntu/ cosmic-proposed main restricted universe multiverse" > /etc/apt/sources.list
echo "安装相关组件"
    apt-get update -y
    sudo apt-get install -y git curl make rand clang-6.0 qrencode
echo "安装......"
    git clone https://github.com/TunSafe/TunSafe.git
    cd TunSafe
    sudo make && sudo make install
echo "开启路由转发"
    echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
    sysctl -w net.ipv6.conf.all.forwarding=1
    echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
    sysctl net.ipv4.tcp_available_congestion_control
    sudo echo net.ipv4.ip_forward = 1 >> /etc/sysctl.conf
    echo "1"> /proc/sys/net/ipv4/ip_forward
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
    port=65080
    eth=$(ls /sys/class/net | awk '/^e/{print}')

sudo cat > /etc/tunsafe/TunSafe.conf <<-EOF
[Interface]
PrivateKey = $s1
Address = 10.0.0.1/24,fd10:db31:203:ab31::1/64 
ListenPortTCP = $port
PostUp   = iptables -A FORWARD -i tun0 -j ACCEPT; ip6tables -A FORWARD -i tun0 -j ACCEPT; iptables -A FORWARD -o tun0 -j ACCEPT; ip6tables -A FORWARD -o tun0 -j ACCEPT; iptables -t nat -A POSTROUTING -o $eth -j MASQUERADE;ip6tables -t nat -A POSTROUTING -o $eth -j MASQUERADE
PostDown = iptables -D FORWARD -i tun0 -j ACCEPT; ip6tables -D FORWARD -i tun0 -j ACCEPT; iptables -D FORWARD -o tun0 -j ACCEPT; ip6tables -D FORWARD -o tun0 -j ACCEPT; iptables -t nat -D POSTROUTING -o $eth -j MASQUERADE;ip6tables -t nat -D POSTROUTING -o $eth -j MASQUERADE
DNS = 1.1.1.1,2606:4700:4700::1111
MTU = 1420

[Peer]
PublicKey = $c2
AllowedIPs = 10.0.0.2/32,fd10:db31:203:ab31::2/64
EOF


sudo cat > /etc/tunsafe/client.conf <<-EOF
[Interface]
PrivateKey = $c1
Address = 10.0.0.2/24,fd10:db31:203:ab31::2/64
DNS = 1.1.1.1,2606:4700:4700::1111
MTU = 1420

[Peer]
PublicKey = $s2
Endpoint = tcp://$serverip:$port
AllowedIPs = 0.0.0.0/0, ::0/0
PersistentKeepalive = 25
EOF
echo "显示客户端配置"
echo "==============================================="
cat /etc/tunsafe/client.conf
echo "==============================================="

sudo cat > /etc/init.d/tunstart <<-EOF
#! /bin/bash
cd /etc/tunsafe/
tunsafe start -d TunSafe.conf
EOF

    chmod +x /etc/init.d/tunstart
    cd /etc/init.d
    update-rc.d tunstart defaults
echo "启动"
    cd /etc/tunsafe
    tunsafe start -d TunSafe.conf
