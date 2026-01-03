#!/bin/bash
set -e

USER_NAME="${SUDO_USER:-$(whoami)}"
HOME_DIR="/home/$USER_NAME"

for _ in {1..120}; do
  hostname -I | grep -qE '[0-9]+\.[0-9]+\.[0-9]+' && break
  sleep 1
done

if ! hostname -I | grep -qE '[0-9]+\.[0-9]+\.[0-9]+'; then
  echo "❌ DHCP로 IP를 받지 못했습니다."
  exit 1
fi

CURRENT_IP=$(hostname -I | awk '{print $1}')
GATEWAY=$(ip route | awk '/default/ {print $3}')

mv /etc/netplan/50-cloud-init.yaml /etc/netplan/50-cloud-init.yaml.bak 2>/dev/null || true
rm -f /etc/netplan/99-fixed-ip.yaml

cat > /etc/netplan/99-fixed-ip.yaml << EOF
network:
  version: 2
  wifis:
    wlan0:
      dhcp4: false
      addresses:
        - ${CURRENT_IP}/24
      routes:
        - to: default
          via: ${GATEWAY}
      nameservers:
        addresses:
          - 8.8.8.8
          - 1.1.1.1
EOF

echo
echo "현재 IP: ${CURRENT_IP}"
echo "연결이 유지되면 ENTER를 누르세요"
echo

if ! netplan try; then
  echo "고정 IP 적용 실패."
  exit 1
fi

apt update
apt install -y \
  ca-certificates \
  curl \
  gnupg \
  lsb-release \
  iw \
  linux-firmware

iw reg set KR
echo "REGDOMAIN=KR" > /etc/default/crda
iw dev wlan0 set power_save off || true

cat > /etc/rc.local << 'EOF'
#!/bin/bash
iw dev wlan0 set power_save off || true
exit 0
EOF
chmod +x /etc/rc.local

curl -fsSL https://get.docker.com | sh
apt install -y docker-compose-plugin
usermod -aG docker "$USER_NAME"

curl -fsSL https://packages.adoptium.net/artifactory/api/gpg/key/public \
  | gpg --dearmor -o /usr/share/keyrings/adoptium.gpg

echo "deb [signed-by=/usr/share/keyrings/adoptium.gpg] https://packages.adoptium.net/artifactory/deb jammy main" \
  > /etc/apt/sources.list.d/adoptium.list

apt update
apt install -y temurin-25-jdk