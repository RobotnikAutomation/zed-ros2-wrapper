#!/bin/bash

echo "Starting installation..."

echo "Install screen"
sudo apt-get install screen -y
touch ~/.screenrc
echo "termcapinfo xterm* ti@:te@
shell -\$SHELL
setenv LD_LIBRARY_PATH echo \$CMAKE_PREFIX_PATH | awk '{split(\$1, a, \":\"); print a[1];}'\"/lib\":/opt/ros/$ROS_DISTRO/lib:/opt/ros/$ROS_DISTRO/lib/x86_64-linux-gnu
zombie kr
verbose on" > ~/.screenrc

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

copy_file() {
    local source_path="$1"
    local destination_name="${2:-$1}"
    local src="$SCRIPT_DIR/$source_path"
    local dst="$HOME/$destination_name"

    if [ ! -f "$src" ]; then
        echo "Error: File '$source_path' not found in script directory ($SCRIPT_DIR). Skipping."
        return 1
    fi

    if [ -f "$dst" ]; then
        read -p "File '$destination_name' already exists in $HOME. Overwrite? (y/N): " answer
        case "$answer" in
            [Yy]* ) ;;
            * ) echo "Skipping copy of '$destination_name'."; return 0 ;;
        esac
    fi

    cp "$src" "$dst"
    if [ $? -eq 0 ]; then
        echo "Copied '$source_path' to '$dst'."
    else
        echo "Failed to copy '$source_path'."
        return 1
    fi
}

echo "Install jetson scripts to home directory"
copy_file bringup.sh
copy_file jetson_params.env
copy_file ntp/check_clock_sync.sh check_clock_sync.sh
chmod +x "$HOME/check_clock_sync.sh"

echo "Install systemd-timesyncd to manage NTP"
sudo apt-get install systemd-timesyncd -y
sudo cp "$SCRIPT_DIR/ntp/timesyncd.conf" /etc/systemd/timesyncd.conf

echo "Install ROS 2 Zenoh RMW"
sudo apt-get install ros-jazzy-rmw-zenoh-cpp -y

# Avoid competing clock managers.
if systemctl list-unit-files chrony.service --no-legend 2>/dev/null |
   grep -q '^chrony.service'; then
    sudo systemctl disable --now chrony
fi

sudo timedatectl set-ntp true
sudo systemctl enable --now systemd-timesyncd
sudo systemctl restart systemd-timesyncd

echo "Add robot-time-server to /etc/hosts"
if grep -Eq '^[[:space:]]*192\.168\.1\.200[[:space:]]+([^#]*[[:space:]])?robot-time-server([[:space:]]|$)' /etc/hosts; then
    echo "Entry for robot-time-server is correct"
else
    echo "Updating entry in /etc/hosts"
    sudo sed -i -E '/^[[:space:]]*[^#]+[[:space:]]robot-time-server([[:space:]]|$)/d' /etc/hosts
    echo "192.168.1.200 robot-time-server" | sudo tee -a /etc/hosts > /dev/null
fi


echo "Installation completed!"
