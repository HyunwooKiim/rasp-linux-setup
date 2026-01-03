#!/bin/bash
set -e

# Wi-Fi 연결(IP) 대기 (최대 120초)
for _ in {1..120}; do
  hostname -I | grep -qE '[0-9]+\.[0-9]+\.[0-9]+' && break
  sleep 1
done

# 기본 패키지
apt update
apt install -y \
  ca-certificates \
  curl \
  gnupg \
  lsb-release \
  iw \
  linux-firmware

# 무선 국가 코드 KR
iw reg set KR
echo "REGDOMAIN=KR" > /etc/default/crda

# Wi-Fi 절전 OFF (즉시)
iw dev wlan0 set power_save off || true

# 부팅 시에도 Wi-Fi 절전 OFF
cat > /etc/rc.local << 'EOF'
#!/bin/bash
iw dev wlan0 set power_save off || true
exit 0
EOF
chmod +x /etc/rc.local

# --------------------
# Docker 설치 (공식)
# --------------------
curl -fsSL https://get.docker.com | sh

# docker compose plugin
apt install -y docker-compose-plugin

# 현재 유저 docker 그룹 추가
usermod -aG docker "$SUDO_USER"

# --------------------
# Java 25 (Temurin)
# --------------------
curl -fsSL https://packages.adoptium.net/artifactory/api/gpg/key/public | gpg --dearmor -o /usr/share/keyrings/adoptium.gpg

echo "deb [signed-by=/usr/share/keyrings/adoptium.gpg] https://packages.adoptium.net/artifactory/deb jammy main" \
  > /etc/apt/sources.list.d/adoptium.list

apt update
apt install -y temurin-25-jdk