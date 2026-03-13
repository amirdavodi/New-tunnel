#!/bin/bash
# Omni-Path Interactive Tunnel (Gost V3) - 2026 Edition

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

clear
echo -e "${CYAN}==================================================${NC}"
echo -e "${CYAN}    Omni-Path Professional Tunneling Script       ${NC}"
echo -e "${CYAN}==================================================${NC}"

if [ "$EUID" -ne 0 ]; then 
  echo -e "${RED}لطفا اسکریپت را با sudo اجرا کنید.${NC}"
  exit
fi

echo -e "${YELLOW}در حال نصب پیش‌نیازها...${NC}"
apt update && apt install -y curl wget tar sudo

echo -e "${YELLOW}نقش این سرور را انتخاب کنید:${NC}"
echo "1) سرور ایران (Destination)"
echo "2) سرور خارج (Origin)"
read -p "انتخاب [1-2]: " SERVER_TYPE

echo -e "${GREEN}فعال‌سازی BBR...${NC}"
if ! grep -q "net.ipv4.tcp_congestion_control=bbr" /etc/sysctl.conf; then
    echo "net.core.default_qdisc=fq" | tee -a /etc/sysctl.conf
    echo "net.ipv4.tcp_congestion_control=bbr" | tee -a /etc/sysctl.conf
    sysctl -p
fi

echo -e "${GREEN}در حال نصب Gost V3...${NC}"
ARCH=$(uname -m)
if [ "$ARCH" == "x86_64" ]; then
    VERSION="gost_3.0.0-rc10_linux_amd64.tar.gz"
else
    VERSION="gost_3.0.0-rc10_linux_arm64.tar.gz"
fi

wget -q "https://github.com/go-gost/gost/releases/download/v3.0.0-rc10/$VERSION"
tar -xvzf "$VERSION" && mv gost /usr/local/bin/
rm "$VERSION" LICENSE README.md 2>/dev/null

if [ "$SERVER_TYPE" == "1" ]; then
    read -p "پورت تانل را وارد کنید (مثلا 59103): " TUNNEL_PORT
    cat <<EOF > /etc/systemd/system/gost.service
[Unit]
Description=Gost V3 Iran
After=network.target
[Service]
Type=simple
ExecStart=/usr/local/bin/gost -L ws://admin:pass2026@:$TUNNEL_PORT?path=/v2-tunnel
Restart=always
[Install]
WantedBy=multi-user.target
EOF

elif [ "$SERVER_TYPE" == "2" ]; then
    read -p "آی‌پی سرور ایران: " IRAN_IP
    read -p "پورت تانل (مشابه ایران): " TUNNEL_PORT
    read -p "پورت پنل X-UI در ایران: " XUI_PORT
    read -p "پورت اتصال مشتری در خارج: " CLIENT_PORT

    cat <<EOF > /etc/systemd/system/gost.service
[Unit]
Description=Gost V3 Foreign
After=network.target
[Service]
Type=simple
ExecStart=/usr/local/bin/gost -L rtcp://:$CLIENT_PORT/127.0.0.1:$XUI_PORT -F ws://admin:pass2026@$IRAN_IP:$TUNNEL_PORT?path=/v2-tunnel
Restart=always
[Install]
WantedBy=multi-user.target
EOF
fi

systemctl daemon-reload && systemctl enable gost && systemctl start gost

echo -e "${GREEN}✅ نصب با موفقیت انجام شد!${NC}"
echo -e "${CYAN}وضعیت: systemctl status gost${NC}"
