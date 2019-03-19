green "给新用户起个名字，不能和已有用户重复"
    read -p "请输入用户名：" newname
    cd /etc/tunsafe/
    cp client.conf $newname.conf
    tunsafe genkey | tee temprikey | tunsafe pubkey > tempubkey
    ipnum=$(grep Allowed /etc/tunsafe/TunSafe.conf | tail -1 | awk -F '[ ./]' '{print $6}')
    newnum=$((10#${ipnum}+1))
    sed -i 's%^PrivateKey.*$%'"PrivateKey = $(cat temprikey)"'%' $newname.conf
    sed -i 's%^Address.*$%'"Address = 10.0.0.$newnum\/24"'%' $newname.conf

cat >> /etc/tunsafe/TunSafe.conf <<-EOF
[Peer]
PublicKey = $(cat tempubkey)
AllowedIPs = 10.0.0.$newnum/32
EOF
    tunsafe set tun0 peer $(cat tempubkey) allowed-ips 10.0.0.$newnum/32
    green "添加完成，文件：/etc/tunsafe/$newname.conf"
    rm -f temprikey tempubkey
