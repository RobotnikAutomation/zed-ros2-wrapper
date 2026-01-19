# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Starting installation..."

echo "Install chrony to manage NTP"
sudo apt-get install chrony -y
sudo cp "$SCRIPT_DIR/chrony/chrony_server.conf" /etc/chrony/conf.d/allowed_clients.conf
sudo systemctl enable chrony
sudo systemctl start chrony

echo "Installation completed!"