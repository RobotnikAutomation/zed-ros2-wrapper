#!/bin/bash

SERVER_NAME="robot-time-server"
SERVER_IP="192.168.1.200"

# --- Check clock synchronization ---

sync_status=$(timedatectl show \
    -p NTPSynchronized \
    --value 2>/dev/null)

timesync_output=$(timedatectl timesync-status 2>/dev/null)

leap_status=$(echo "$timesync_output" |
    awk -F': *' '/^[[:space:]]*Leap:/ {print $2}')

current_server_ip=$(echo "$timesync_output" |
    awk '/^[[:space:]]*Server:/ {print $2}')

current_server_name=$(echo "$timesync_output" |
    awk -F'[()]' '/^[[:space:]]*Server:/ {print $2}')

# --- Check NTP server ---

if [[ "$current_server_ip" == "$SERVER_IP" ]] ||
   [[ "$current_server_name" == "$SERVER_NAME" ]]; then
    ntp_server_ok=1
else
    ntp_server_ok=0
fi

# --- Evaluate and print results ---

if [[ "$sync_status" == "yes" ]] &&
   [[ "$leap_status" == "normal" ]] &&
   [[ $ntp_server_ok -eq 1 ]]; then

    echo "Clock is synchronized and NTP server is correctly set to '$SERVER_NAME'."
    exit 0
else
    echo "Clock sync or NTP server check failed."
    echo "System synchronized: ${sync_status:-unknown}"
    echo "Leap status: ${leap_status:-unknown}"

    if [[ $ntp_server_ok -eq 1 ]]; then
        echo "Current NTP server is correctly set to '$SERVER_NAME'."
    else
        echo "Current NTP server is NOT '$SERVER_NAME'."
        echo "Selected server IP: ${current_server_ip:-none}"
        echo "Selected server name: ${current_server_name:-none}"
    fi

    exit 1
fi
