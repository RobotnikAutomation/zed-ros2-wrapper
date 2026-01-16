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

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Function to copy a file relative to script location
copy_file() {
    local filename="$1"
    local src="$SCRIPT_DIR/$filename"
    local dst="$HOME/$filename"

    if [ ! -f "$src" ]; then
        echo "Error: File '$filename' not found in script directory ($SCRIPT_DIR). Skipping."
        return 1
    fi

    # Check if destination file exists
    if [ -f "$dst" ]; then
        read -p "File '$filename' already exists in $HOME. Overwrite? (y/N): " answer
        case "$answer" in
            [Yy]* ) ;;
            * ) echo "Skipping copy of '$filename'."; return 0 ;;
        esac
    fi

    cp "$src" "$dst"
    if [ $? -eq 0 ]; then
        echo "Copied '$filename' to $HOME."
    else
        echo "Failed to copy '$filename'."
        return 1
    fi
}

echo "Install jetson scripts to home directory"
copy_file bringup.sh
copy_file check_clock_sync.sh

echo "Install chrony to manage NTP"
sudo apt-get install chrony -y
sudo cp "$SCRIPT_DIR/chrony/chrony_client.conf" /etc/chrony/chrony.conf
sudo systemctl enable chrony
sudo systemctl start chrony

echo "Add robot-time-server to /etc/hosts"
if ! grep -q "robot-time-server" /etc/hosts; then
    echo "Adding entry to /etc/hosts"
    echo "192.168.1.200 robot-time-server" | sudo tee -a /etc/hosts > /dev/null
else
    echo "Entry for robot-time-server already exists in /etc/hosts"
fi


echo "Installation completed!"