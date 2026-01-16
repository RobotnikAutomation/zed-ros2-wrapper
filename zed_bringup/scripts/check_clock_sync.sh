#!/bin/bash

SERVER="robot-time-server"
THRESHOLD=0.2

# --- Check clock synchronization ---

tracking_output=$(chronyc tracking)

leap_status=$(echo "$tracking_output" | grep "Leap status" | awk -F': ' '{print $2}')
time_offset=$(echo "$tracking_output" | grep "System time" | awk -F': ' '{print $2}' | awk '{print $1}')
abs_offset=$(echo "$time_offset" | sed 's/-//')

# --- Check NTP server ---

selected_source=$(chronyc sources | grep "^\^\*")

if [[ -z "$selected_source" ]]; then
    echo "No NTP source is currently selected."
    ntp_server_ok=0
else
    current_server=$(echo "$selected_source" | awk '{print $2}')
    if [[ "$current_server" == "$SERVER" ]]; then
        ntp_server_ok=1
    else
        ntp_server_ok=0
    fi
fi

# --- Evaluate and print results ---

if [[ "$leap_status" == "Normal" ]] && (( $(echo "$abs_offset < $THRESHOLD" | bc -l) )) && [[ $ntp_server_ok -eq 1 ]]; then
    echo "✅ Clocks are synchronized and NTP server is correctly set to '$SERVER'."
    echo "Leap status: $leap_status"
    echo "System time offset: $time_offset seconds"
    echo "Current NTP server: $current_server"
    exit 0
else
    echo "❌ Clock sync or NTP server check failed."
    echo "Leap status: $leap_status"
    echo "System time offset: $time_offset seconds"
    if [[ $ntp_server_ok -eq 1 ]]; then
        echo "Current NTP server is correctly set to '$SERVER'."
    else
        echo "Current NTP server is NOT '$SERVER'."
        if [[ -n "$current_server" ]]; then
            echo "Selected server: $current_server"
        else
            echo "No NTP server selected."
        fi
    fi
    exit 1
fi
