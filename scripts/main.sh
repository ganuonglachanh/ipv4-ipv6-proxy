#echo "Disable firewall"
#systemctl stop firewalld && systemctl disable firewalld && systemctl stop 3proxy && systemctl disable 3proxy
echo "installing apps"
yum -y install gcc make wget net-tools bsdtar zip >/dev/null

install_3proxy

echo "working folder = /home/proxy-installer"
WORKDIR="/home/proxy-installer"
WORKDATA="${WORKDIR}/data.txt"
DEFAULTNET=$(ip -o -4 route show to default | awk '{print $5}')
mkdir $WORKDIR && cd $_

IP4=$(curl -4 -s ifconfig.co)
IP6=$(curl -6 -s http://ip6only.me/api/ | cut -f2 -d',')
echo "Default net interface = ${DEFAULTNET}"
echo "Internal ip = ${IP4}. Exteranl sub for ip6 = ${IP6}"

echo "How many proxy do you want to create? Example 500"
read COUNT

FIRST_PORT=10000
LAST_PORT=$(($FIRST_PORT + $COUNT))
firewall-cmd --zone=public --permanent --add-port ${FIRST_PORT}-${LAST_PORT}/tcp
firewall-cmd --reload
gen_data >$WORKDIR/data.txt
#gen_iptables >$WORKDIR/boot_iptables.sh
gen_ifconfig >$WORKDIR/boot_ifconfig.sh
chmod +x $WORKDIR/boot_*.sh /etc/rc.local

gen_3proxy >/usr/local/etc/3proxy/3proxy.cfg

cat >>/etc/sysctl.conf <<EOF
fs.file-max=500000
EOF

sysctl -w fs.file-max=500000
sysctl -p

cat >>/etc/security/limits.conf <<EOF
* soft nproc 65535
* hard nproc 65535
* soft nofile 65535
* hard nofile 65535
EOF



cat >>/etc/rc.local <<EOF
#bash ${WORKDIR}/boot_iptables.sh
bash ${WORKDIR}/boot_ifconfig.sh
ulimit -n 65536
service 3proxy start
EOF

bash /etc/rc.local

gen_proxy_file_for_user

zip proxy.zip proxy.txt
echo "Done! ${WORKDATA}"

#upload_proxy
