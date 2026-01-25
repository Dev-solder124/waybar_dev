#!/bin/bash

# 1. Create the Caffeine Toggle Script
# This script toggles hypridle to prevent screen sleep
cat << 'SCRIPT' > "$HOME/.config/waybar/scripts/caffeine.sh"
#!/bin/bash

LOCK_FILE="/tmp/caffeine.lock"

# Function to update the module JSON
show_status() {
    if [ -f "$LOCK_FILE" ]; then
        echo '{"text": "☕ On", "tooltip": "Screen Awake (Caffeine Active)", "class": "active"}'
    else
        echo '{"text": "zzz", "tooltip": "Normal Power Saving", "class": "inactive"}'
    fi
}

# Function to toggle state
toggle() {
    if [ -f "$LOCK_FILE" ]; then
        # Turn Caffeine OFF (Allow sleep)
        rm "$LOCK_FILE"
        # Re-start hypridle if it's not running
        if ! pgrep -x "hypridle" > /dev/null; then
            hypridle &
        fi
        notify-send "Caffeine Disabled" "Screen will sleep normally." -i sleep
    else
        # Turn Caffeine ON (Prevent sleep)
        touch "$LOCK_FILE"
        # Kill hypridle to stop sleep timers
        killall hypridle
        notify-send "Caffeine Enabled" "Screen will stay awake." -i coffee
    fi
    # Signal Waybar to update immediately
    pkill -SIGRTMIN+9 waybar
}

case "$1" in
    toggle)
        toggle
        ;;
    *)
        show_status
        ;;
esac
SCRIPT

chmod +x "$HOME/.config/waybar/scripts/caffeine.sh"

# 2. Update config.jsonc
# Modifies Battery to show percentage and ensures Caffeine is configured
# We use a temporary file to rebuild the specific modules to avoid breaking the whole file structure

# Create a clean config with your requested changes
cat << 'CONFIG' > "$HOME/.config/waybar/config.jsonc"
{
  "reload_style_on_change": true,
  "layer": "top",
  "position": "top",
  "spacing": 0,
  "height": 26,
  "modules-left": ["custom/omarchy", "hyprland/workspaces"],
  "modules-center": ["custom/localsend", "custom/hyprwhspr", "clock", "custom/weather", "custom/update", "custom/caffeine", "custom/voxtype", "custom/screenrecording-indicator"],
  "modules-right": [
    "custom/btc",
    "custom/ram-disk",
    "custom/thermal",
    "group/tray-expander",
    "custom/network-speed",
    "network",
    "bluetooth",
    "pulseaudio",
    "battery"
  ],
  "hyprland/workspaces": {
    "on-click": "activate",
    "format": "{icon}",
    "format-icons": {
      "default": "",
      "1": "1",
      "2": "2",
      "3": "3",
      "4": "4",
      "5": "5",
      "6": "6",
      "7": "7",
      "8": "8",
      "9": "9",
      "10": "0"
    },
    "persistent-workspaces": {
      "1": [],
      "2": [],
      "3": [],
      "4": [],
      "5": []
    }
  },
  "custom/omarchy": {
    "format": "<span font='omarchy'>\ue900</span>",
    "on-click": "omarchy-menu",
    "on-click-right": "xdg-terminal-exec",
    "tooltip-format": "Omarchy Menu"
  },
  "custom/update": {
    "format": "",
    "exec": "omarchy-update-available",
    "on-click": "omarchy-launch-floating-terminal-with-presentation omarchy-update",
    "signal": 7,
    "interval": 21600
  },
  "custom/ram-disk": {
    "exec": "$HOME/.config/waybar/scripts/ram-disk-monitor.sh",
    "return-type": "json",
    "interval": 5,
    "format": "{}",
    "tooltip": true,
    "on-click": "omarchy-launch-floating-terminal-with-presentation btop"
  },
  "custom/thermal": {
    "exec": "$HOME/.config/waybar/scripts/thermal-monitor.sh",
    "return-type": "json",
    "interval": 5,
    "format": "{}",
    "tooltip": true,
    "on-click": "omarchy-launch-floating-terminal-with-presentation btop"
  },
  "clock": {
    "format": "{:L%A %H:%M}",
    "format-alt": "{:L%d %B W%V %Y}",
    "tooltip": false,
    "on-click-right": "omarchy-launch-floating-terminal-with-presentation omarchy-tz-select"
  },
  "custom/btc": {
    "format": "{}",
    "exec": "$HOME/.config/waybar/scripts/btc-ticker.sh",
    "return-type": "json",
    "interval": 60,
    "on-click": "omarchy-launch-floating-terminal-with-presentation python3 $HOME/.config/waybar/scripts/btc-chart.py"
  },
  "custom/weather": {
    "exec": "$HOME/.config/waybar/scripts/weather.sh",
    "return-type": "json",
    "interval": 300,
    "format": "{}",
    "tooltip": true,
    "on-click": "xdg-open 'https://wttr.in'"
  },
  "network": {
    "format-icons": ["󰤯", "󰤟", "󰤢", "󰤥", "󰤨"],
    "format": "{icon}",
    "format-wifi": "{icon}",
    "format-ethernet": "󰀂",
    "format-disconnected": "󰤮",
    "tooltip-format-wifi": "{essid} ({frequency} GHz)\n⇣{bandwidthDownBytes}  ⇡{bandwidthUpBytes}",
    "tooltip-format-ethernet": "⇣{bandwidthDownBytes}  ⇡{bandwidthUpBytes}",
    "tooltip-format-disconnected": "Disconnected",
    "interval": 3,
    "spacing": 1,
    "on-click": "omarchy-launch-wifi"
  },
  "custom/network-speed": {
    "exec": "$HOME/.config/waybar/scripts/network-speed.sh",
    "return-type": "json",
    "interval": 2,
    "format": "{}",
    "tooltip": true,
    "on-click": "omarchy-launch-wifi"
  },
  "battery": {
    "format": "{capacity}% {icon}",
    "format-time": "{H}:{M:02}",
    "format-discharging": "{capacity}% {icon}",
    "format-charging": "{capacity}% 󰂄 ({power}W)",
    "format-plugged": "{capacity}%  ({power}W)",
    "format-alt": "{time} {icon}",
    "format-icons": {
      "charging": ["󰢜", "󰂆", "󰂇", "󰂈", "󰢝", "󰂉", "󰢞", "󰂊", "󰂋", "󰂅"],
      "default": ["󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"]
    },
    "interval": 5,
    "on-click": "omarchy-menu power",
    "states": {
      "warning": 20,
      "critical": 10
    }
  },
  "bluetooth": {
    "format": "󰂯",
    "format-disabled": "󰂲",
    "format-connected": "󰂱",
    "format-no-controller": "",
    "tooltip-format": "Devices connected: {num_connections}",
    "on-click": "omarchy-launch-bluetooth"
  },
  "pulseaudio": {
    "format": "{icon}",
    "on-click": "omarchy-launch-audio",
    "on-click-right": "pamixer -t",
    "tooltip-format": "Playing at {volume}%",
    "scroll-step": 5,
    "format-muted": "󰝟",
    "format-icons": {
      "headphone": "",
      "default": ["󰕿", "󰖀", "󰕾"]
    }
  },
  "group/tray-expander": {
    "orientation": "inherit",
    "drawer": {
      "transition-duration": 600,
      "children-class": "tray-group-item"
    },
    "modules": ["custom/expand-icon", "tray"]
  },
  "custom/expand-icon": {
    "format": "",
    "tooltip": false
  },
  "custom/caffeine": {
    "exec": "$HOME/.config/waybar/scripts/caffeine.sh",
    "return-type": "json",
    "on-click": "$HOME/.config/waybar/scripts/caffeine.sh toggle",
    "interval": 5,
    "signal": 9
  },
  "custom/screenrecording-indicator": {
    "on-click": "omarchy-cmd-screenrecord",
    "exec": "$OMARCHY_PATH/default/waybar/indicators/screen-recording.sh",
    "signal": 8,
    "return-type": "json"
  },
  "custom/voxtype": {
    "exec": "omarchy-voxtype-status",
    "return-type": "json",
    "format": "{icon}",
    "format-icons": {
      "idle": "",
      "recording": "󰍬",
      "transcribing": "󰔟"
    },
    "tooltip": true,
    "on-click-right": "omarchy-voxtype-config",
    "on-click": "omarchy-voxtype-model"
  },
  "tray": {
    "icon-size": 12,
    "spacing": 17
  },
  "custom/localsend": {
    "format": "󰑫",
    "on-click": "localsend",
    "tooltip-format": "LocalSend"
  },
  "custom/hyprwhspr": {
    "format": "{}",
    "exec": "/usr/lib/hyprwhspr/config/hyprland/hyprwhspr-tray.sh status",
    "interval": 1,
    "return-type": "json",
    "exec-on-event": true,
    "on-click": "/usr/lib/hyprwhspr/config/hyprland/hyprwhspr-tray.sh toggle",
    "on-click-right": "/usr/lib/hyprwhspr/config/hyprland/hyprwhspr-tray.sh restart",
    "on-click-middle": "/usr/lib/hyprwhspr/config/hyprland/hyprwhspr-tray.sh restart",
    "tooltip": true
  }
}
CONFIG

# 3. Reload Waybar
echo ":: Reloading Waybar..."
killall waybar
nohup waybar > /dev/null 2>&1 &

echo ":: Update Complete"
echo "   - Battery now shows percentage (e.g., 95% 🔋)"
echo "   - Added 'Caffeine' toggle (Look for 'zzz' or '☕ On' in the center)"