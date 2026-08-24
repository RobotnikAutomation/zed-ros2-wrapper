#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Starting installation..."

echo "Install chrony to manage NTP"
sudo apt-get install chrony ntpdate -y
sudo mkdir -p /etc/chrony/conf.d
sudo cp "$SCRIPT_DIR/ntp/chrony_server.conf" /etc/chrony/conf.d/zed_time_server.conf
sudo systemctl enable chrony
sudo systemctl restart chrony

echo "Add robot-time-server to /etc/hosts"
if grep -Eq '^[[:space:]]*192\.168\.1\.200[[:space:]]+([^#]*[[:space:]])?robot-time-server([[:space:]]|$)' /etc/hosts; then
    echo "Entry for robot-time-server is correct"
else
    echo "Updating entry in /etc/hosts"
    sudo sed -i -E '/^[[:space:]]*[^#]+[[:space:]]robot-time-server([[:space:]]|$)/d' /etc/hosts
    echo "192.168.1.200 robot-time-server" | sudo tee -a /etc/hosts > /dev/null
fi

echo "Installation completed!"
