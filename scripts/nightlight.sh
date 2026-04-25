#!/bin/bash

SHADER_FILE="$HOME/.config/waybar/shaders/nightlight.frag"
STATE_FILE="/tmp/waybar-nightlight.lock"

is_active() {
    [ -f "$STATE_FILE" ]
}

set_shader() {
    hyprctl keyword decoration:screen_shader "$1" >/dev/null
}

if [ "$1" = "toggle" ]; then
    if ! command -v hyprctl >/dev/null 2>&1; then
        notify-send "Nightlight unavailable" "hyprctl is not installed." -i dialog-warning
    elif [ ! -f "$SHADER_FILE" ]; then
        notify-send "Nightlight unavailable" "Missing shader: $SHADER_FILE" -i dialog-warning
    elif is_active; then
        if set_shader ""; then
            rm -f "$STATE_FILE"
            notify-send "Nightlight Disabled" "Screen colors restored." -i weather-clear-night
        else
            notify-send "Nightlight failed" "Could not clear the Hyprland screen shader." -i dialog-warning
        fi
    else
        set_shader "" 2>/dev/null || true
        if set_shader "$SHADER_FILE"; then
            touch "$STATE_FILE"
            notify-send "Nightlight Enabled" "Warm screen shader applied." -i weather-clear-night
        else
            notify-send "Nightlight failed" "Could not apply the Hyprland screen shader." -i dialog-warning
        fi
    fi
    pkill -SIGRTMIN+10 waybar 2>/dev/null || true
fi

if is_active; then
    echo '{"text": " On", "tooltip": "Nightlight: On", "class": "active", "alt": "on"}'
else
    echo '{"text": " Off", "tooltip": "Nightlight: Off", "class": "inactive", "alt": "off"}'
fi
