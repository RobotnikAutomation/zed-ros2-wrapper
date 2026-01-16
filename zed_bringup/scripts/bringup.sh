#!/bin/bash

# Network configuration
export ROBOT_HOSTNAME=192.168.1.200
export JETSON_HOSTNAME=192.168.1.60
export JETSON_WORKSPACE=~/robot_ws

# Camera 1 configuration
export JETSON_CAMERA_1_MODEL=zed2i
export JETSON_CAMERA_1_ID=front_rgbd_camera
export JETSON_CAMERA_1_DEVICE_ID=0

# Camera 2 configuration
export JETSON_CAMERA_2_MODEL=none
export JETSON_CAMERA_2_ID=rear_rgbd_camera
export JETSON_CAMERA_2_DEVICE_ID=0

export ROS_DOMAIN_ID=38
export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp
source /opt/ros/$ROS_DISTRO/setup.bash
source $JETSON_WORKSPACE/install/setup.bash

TIMEOUT=60  # seconds to wait before giving up
START_TIME=$(date +%s)

while true; do
    if $HOME/check_clock_sync.sh; then
        echo "Clock sync successful!"
        break
    else
        echo "Waiting for clock sync..."
    fi

    sleep 1

    NOW=$(date +%s)
    ELAPSED=$(( NOW - START_TIME ))
    if (( ELAPSED >= TIMEOUT )); then
        echo "Timeout reached ($TIMEOUT seconds). Not restarting running screens."
        exit 1
    fi
done

echo ""
echo -e "ROS_DOMAIN_ID\t\t= ${ROS_DOMAIN_ID}"
echo -e "RMW_IMPLEMENTATION\t= $RMW_IMPLEMENTATION" 
echo -e "WORKSPACE\t\t= $JETSON_WORKSPACE/install/setup.bash"
echo ""

killall screen
sleep 2;
screen -S zed -d -m ros2 launch zed_bringup zed_complete.launch.py;
