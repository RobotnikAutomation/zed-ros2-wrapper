#!/usr/bin/env bash

# Legacy/reference candidate; the active bringup.sh is unchanged.
# Full robot-integrated validation is still pending.

source "$HOME/jetson_params.env"

echo ""
echo "=============================================="
echo " Waiting for Jetson clock synchronization"
echo " Maximum waiting time: 5 minutes"
echo "=============================================="
echo ""

sync_ok=false
for ((attempt = 1; attempt <= 300; attempt++)); do
    if "$HOME/check_clock_sync.sh" >/dev/null 2>&1; then
        sync_ok=true
        break
    fi
    sleep 1
done

if [[ "$sync_ok" != true ]]; then
    echo ""
    echo "ERROR: Clock synchronization was not validated within 5 minutes."
    "$HOME/check_clock_sync.sh"
    echo "ROS 2 nodes will not be started."
    exit 1
fi

echo "Clock synchronization completed successfully."
echo ""

source /opt/ros/jazzy/setup.bash
source "$JETSON_WORKSPACE/install/setup.bash"

echo -e "ROS_DOMAIN_ID\t\t= ${ROS_DOMAIN_ID}"
echo -e "RMW_IMPLEMENTATION\t= ${RMW_IMPLEMENTATION}"
echo -e "WORKSPACE\t\t= ${JETSON_WORKSPACE}/install/setup.bash"
echo ""

screen -S zed -X quit 2>/dev/null || true

sleep 5

screen -S zed -d -m \
    ros2 launch zed_bringup zed_complete.launch.py

sleep 2

if screen -list | grep -q "[.]zed"; then
    echo "ZED bringup started successfully."
    exit 0
else
    echo "ERROR: the ZED screen session could not be started."
    exit 1
fi
