#!/bin/bash
set -e

USER_NAME="${SUDO_USER:-$(whoami)}"
HOME_DIR="/home/$USER_NAME"
SCRIPT_PATH="$(realpath "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"

for _ in {1..120}; do
  hostname -I | grep -qE '[0-9]+\.[0-9]+\.[0-9]+' && break
  sleep 1
done

if ! hostname -I | grep -qE '[0-9]+\.[0-9]+\.[0-9]+'; then
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

netplan try

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

SSH_DIR="$HOME_DIR/.ssh"
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"
chown "$USER_NAME:$USER_NAME" "$SSH_DIR"

if [ ! -f "$SSH_DIR/id_ed25519" ]; then
  sudo -u "$USER_NAME" ssh-keygen -t ed25519 -N "" -f "$SSH_DIR/id_ed25519"
fi

cat "$SSH_DIR/id_ed25519.pub" >> "$SSH_DIR/authorized_keys"
chmod 600 "$SSH_DIR/authorized_keys"
chown "$USER_NAME:$USER_NAME" "$SSH_DIR/authorized_keys"

cat > "$HOME_DIR/secrets.txt" << EOF
# ===============================
# GitHub Actions Secrets
# ===============================

# ---- Server SSH ----
PI_HOST=${CURRENT_IP}
PI_USER=${USER_NAME}

# ---- SSH PRIVATE KEY (copy & paste into GitHub Secret: PI_SSH_KEY) ----
# Run this command on the server:
cat ~/.ssh/id_ed25519

# ---- SSH PUBLIC KEY (reference only) ----
$(cat "$SSH_DIR/id_ed25519.pub")

# ---- Docker Registry ----
GHCR_TOKEN=<< generate GitHub Personal Access Token >>

# ---- Application (.env) ----
MYSQL_ROOT_PASSWORD=\$\$root_is_king\$\$
MYSQL_DATABASE=jagalchi_user
MYSQL_USER=jagalchi
MYSQL_PASSWORD=\$\$jagalchi_is_king\$\$
SPRING_PROFILES_ACTIVE=prod
TZ=Asia/Seoul
EOF

chown "$USER_NAME:$USER_NAME" "$HOME_DIR/secrets.txt"

(
  sleep 2
  rm -f "$SCRIPT_PATH"
) &

if [[ "$SCRIPT_DIR" == *"rasp-linux-setup"* ]]; then
  (
    sleep 2
    rm -rf "$SCRIPT_DIR"
  ) &
fi