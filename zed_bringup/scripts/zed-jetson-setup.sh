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

echo "Install jetson bringup"
cp bringup.sh ~/bringup.sh

echo "Installation completed!"