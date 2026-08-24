#!/bin/bash

SERVER_NAME="robot-time-server"
SERVER_IP="192.168.1.200"

if ! command -v timedatectl >/dev/null 2>&1; then
    echo "Clock sync check failed: timedatectl is not available."
    exit 1
fi

sync_status=$(timedatectl show -p NTPSynchronized --value 2>/dev/null)
timesync_properties=$(timedatectl show-timesync --all 2>/dev/null)
timesync_status=$(timedatectl timesync-status 2>/dev/null)

current_server_name=$(awk -F= '$1 == "ServerName" {print $2}' <<< "$timesync_properties")
current_server_ip=$(awk -F= '$1 == "ServerAddress" {print $2}' <<< "$timesync_properties")
leap_status=$(awk -F= '$1 == "Leap" {print $2}' <<< "$timesync_properties")

# Older systemd releases may expose these values only in the formatted status.
if [[ -z "$current_server_ip" ]]; then
    current_server_ip=$(awk '/^[[:space:]]*Server:/ {print $2}' <<< "$timesync_status")
fi
if [[ -z "$current_server_name" ]]; then
    current_server_name=$(awk -F'[()]' '/^[[:space:]]*Server:/ {print $2}' <<< "$timesync_status")
fi
if [[ -z "$leap_status" ]]; then
    leap_status=$(awk -F': *' '/^[[:space:]]*Leap:/ {print $2}' <<< "$timesync_status")
fi

if [[ "$current_server_ip" == "$SERVER_IP" ]] ||
   [[ "$current_server_name" == "$SERVER_IP" ]] ||
   [[ "$current_server_name" == "$SERVER_NAME" ]]; then
    ntp_server_ok=1
else
    ntp_server_ok=0
fi

# Some systemd versions do not report leap status. When present, require normal.
if [[ -z "$leap_status" ]] || [[ "${leap_status,,}" == "normal" ]]; then
    leap_status_ok=1
else
    leap_status_ok=0
fi

if [[ "$sync_status" == "yes" ]] &&
   [[ $ntp_server_ok -eq 1 ]] &&
   [[ $leap_status_ok -eq 1 ]]; then
    echo "Clock is synchronized with '$SERVER_NAME' ($SERVER_IP)."
    if [[ -n "$leap_status" ]]; then
        echo "Leap status: $leap_status"
    else
        echo "Leap status: not reported by this systemd version"
    fi
    exit 0
fi

echo "Clock synchronization validation failed."
echo "System synchronized: ${sync_status:-unknown}"
echo "Selected server IP: ${current_server_ip:-none}"
echo "Selected server name: ${current_server_name:-none}"
echo "Leap status: ${leap_status:-not reported}"
exit 1
