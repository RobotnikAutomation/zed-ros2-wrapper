echo "Starting installation..."

echo "Install chrony to manage NTP"
sudo apt-get install chrony -y
sudo cp "$SCRIPT_DIR/chrony/chrony_server.conf" /etc/chrony/chrony.conf
sudo systemctl enable chrony
sudo systemctl start chrony

echo "Installation completed!"