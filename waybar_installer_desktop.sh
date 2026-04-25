#!/bin/bash

# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║                    🎨 Waybar Desktop Installer                            ║
# ║         Fixed for desktop PCs: no battery, no hardcoded username          ║
# ╚═══════════════════════════════════════════════════════════════════════════╝

set -e

readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly MAGENTA='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly BOLD='\033[1m'
readonly DIM='\033[2m'
readonly RESET='\033[0m'

print_header() {
    echo -e "\n${MAGENTA}${BOLD}╭─────────────────────────────────────────────────────────────╮${RESET}"
    echo -e "${MAGENTA}${BOLD}│${RESET} ${CYAN}$1${RESET}"
    echo -e "${MAGENTA}${BOLD}╰─────────────────────────────────────────────────────────────╯${RESET}"
}
print_step()    { echo -e "${GREEN}  ▸${RESET} $1"; }
print_success() { echo -e "${GREEN}  ✓${RESET} $1"; }
print_info()    { echo -e "${BLUE}  ℹ${RESET} ${DIM}$1${RESET}"; }
print_warn()    { echo -e "${YELLOW}  ⚠${RESET} $1"; }

# ────────────────────────────────────────────────────────────────────────────
# Resolve the real home directory (handles sudo runs)
# ────────────────────────────────────────────────────────────────────────────
REAL_HOME="${HOME}"
if [ -n "$SUDO_USER" ]; then
    REAL_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
    print_warn "Running as sudo — using home: $REAL_HOME"
fi

mkdir -p "$REAL_HOME/.config/waybar/scripts" "$REAL_HOME/.config/waybar/shaders"

# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║  Step 1: Caffeine Toggle Script                                           ║
# ╚═══════════════════════════════════════════════════════════════════════════╝
print_header "Creating Caffeine Toggle Script"
print_step "Writing caffeine.sh..."

cat << 'SCRIPT' > "$REAL_HOME/.config/waybar/scripts/caffeine.sh"
#!/bin/bash

LOCK_FILE="/tmp/caffeine.lock"

show_status() {
    if [ -f "$LOCK_FILE" ]; then
        echo '{"text": "☕ On", "tooltip": "Screen Awake (Caffeine Active)", "class": "active"}'
    else
        echo '{"text": "zzz", "tooltip": "Normal Power Saving", "class": "inactive"}'
    fi
}

toggle() {
    if [ -f "$LOCK_FILE" ]; then
        rm "$LOCK_FILE"
        if ! pgrep -x "hypridle" > /dev/null; then
            hypridle &
        fi
        notify-send "Caffeine Disabled" "Screen will sleep normally." -i sleep
    else
        touch "$LOCK_FILE"
        killall hypridle 2>/dev/null || true
        notify-send "Caffeine Enabled" "Screen will stay awake." -i coffee
    fi
    pkill -SIGRTMIN+9 waybar
}

case "$1" in
    toggle) toggle ;;
    *)      show_status ;;
esac
SCRIPT

chmod +x "$REAL_HOME/.config/waybar/scripts/caffeine.sh"
print_success "caffeine.sh created"

# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║  Step 1b: Nightlight Toggle Script                                        ║
# ╚═══════════════════════════════════════════════════════════════════════════╝
print_header "Creating Nightlight Toggle Script"
print_step "Writing nightlight.sh..."

cat << 'SHADER' > "$REAL_HOME/.config/waybar/shaders/nightlight.frag"
#version 320 es

precision highp float;
in vec2 v_texcoord;
uniform sampler2D tex;
layout(location = 0) out vec4 fragColor;

void main() {
    vec4 color = texture(tex, v_texcoord);
    color.r = min(color.r * 1.08, 1.0);
    color.g = color.g * 0.84;
    color.b = color.b * 0.58;
    fragColor = color;
}
SHADER

cat << 'SCRIPT' > "$REAL_HOME/.config/waybar/scripts/nightlight.sh"
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
    echo '{"text": " On", "tooltip": "Nightlight: On", "class": "active", "alt": "on"}'
else
    echo '{"text": " Off", "tooltip": "Nightlight: Off", "class": "inactive", "alt": "off"}'
fi
SCRIPT

chmod +x "$REAL_HOME/.config/waybar/scripts/nightlight.sh"
print_success "nightlight.sh created"

# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║  Step 1c: RAM & Disk Monitor Script                                       ║
# ╚═══════════════════════════════════════════════════════════════════════════╝
print_header "Creating RAM & Disk Monitor Script"
print_step "Writing ram-disk-monitor.sh..."

cat << 'SCRIPT' > "$REAL_HOME/.config/waybar/scripts/ram-disk-monitor.sh"
#!/bin/bash

# RAM usage
RAM_TOTAL=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
RAM_AVAIL=$(awk '/MemAvailable/ {print $2}' /proc/meminfo)
RAM_USED=$(( RAM_TOTAL - RAM_AVAIL ))
RAM_PCT=$(( RAM_USED * 100 / RAM_TOTAL ))
RAM_USED_GB=$(awk "BEGIN {printf \"%.1f\", $RAM_USED/1048576}")
RAM_TOTAL_GB=$(awk "BEGIN {printf \"%.1f\", $RAM_TOTAL/1048576}")

# Disk usage for root partition
DISK_INFO=$(df -h / | awk 'NR==2 {print $3, $5}')
DISK_USED=$(echo "$DISK_INFO" | awk '{print $1}')
DISK_PCT=$(echo "$DISK_INFO" | awk '{print $2}' | tr -d '%')

# Pick RAM icon based on usage
if   [ "$RAM_PCT" -ge 90 ]; then RAM_ICON="󰀦"
elif [ "$RAM_PCT" -ge 70 ]; then RAM_ICON="󰍛"
else                              RAM_ICON="󰍛"
fi

# Pick disk icon based on usage
if   [ "$DISK_PCT" -ge 90 ]; then DISK_ICON="󰋙"
elif [ "$DISK_PCT" -ge 70 ]; then DISK_ICON="󰋘"
else                               DISK_ICON="󰋗"
fi

TEXT="${RAM_ICON} ${RAM_PCT}%  ${DISK_ICON} ${DISK_USED}"
TOOLTIP="RAM: ${RAM_USED_GB}G / ${RAM_TOTAL_GB}G (${RAM_PCT}%)\nDisk (/): ${DISK_USED} used (${DISK_PCT}%)"

echo "{\"text\": \"$TEXT\", \"tooltip\": \"$TOOLTIP\"}"
SCRIPT

chmod +x "$REAL_HOME/.config/waybar/scripts/ram-disk-monitor.sh"
print_success "ram-disk-monitor.sh created"

# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║  Step 1d: CPU Thermal Monitor Script                                      ║
# ╚═══════════════════════════════════════════════════════════════════════════╝
print_header "Creating CPU Thermal Monitor Script"
print_step "Writing thermal-monitor.sh..."

cat << 'SCRIPT' > "$REAL_HOME/.config/waybar/scripts/thermal-monitor.sh"
#!/bin/bash

# Try to get CPU temp from multiple common sources
get_temp() {
    # Method 1: hwmon — works on most desktops with lm-sensors
    for zone in /sys/class/hwmon/hwmon*/temp*_input; do
        [ -f "$zone" ] || continue
        LABEL_FILE="${zone%_input}_label"
        if [ -f "$LABEL_FILE" ]; then
            LABEL=$(cat "$LABEL_FILE" 2>/dev/null | tr '[:upper:]' '[:lower:]')
            # Look for CPU-related sensors
            if echo "$LABEL" | grep -qE "cpu|core|tdie|tctl|package"; then
                TEMP_RAW=$(cat "$zone" 2>/dev/null)
                echo $(( TEMP_RAW / 1000 ))
                return
            fi
        fi
    done

    # Method 2: thermal_zone — fallback (common on some boards)
    for zone in /sys/class/thermal/thermal_zone*/temp; do
        [ -f "$zone" ] || continue
        TYPE_FILE="${zone%temp}type"
        if [ -f "$TYPE_FILE" ]; then
            TYPE=$(cat "$TYPE_FILE" 2>/dev/null | tr '[:upper:]' '[:lower:]')
            if echo "$TYPE" | grep -qE "cpu|x86|acpi"; then
                TEMP_RAW=$(cat "$zone" 2>/dev/null)
                echo $(( TEMP_RAW / 1000 ))
                return
            fi
        fi
    done

    # Method 3: first hwmon temp we can find, any label
    for zone in /sys/class/hwmon/hwmon*/temp1_input; do
        [ -f "$zone" ] || continue
        TEMP_RAW=$(cat "$zone" 2>/dev/null)
        echo $(( TEMP_RAW / 1000 ))
        return
    done

    echo "N/A"
}

TEMP=$(get_temp)

if [ "$TEMP" = "N/A" ]; then
    echo '{"text": "󰔏 N/A", "tooltip": "CPU temp unavailable — try: sudo pacman -S lm_sensors && sudo sensors-detect", "class": "normal"}'
    exit 0
fi

# Set icon and class based on temperature
if   [ "$TEMP" -ge 90 ]; then ICON="󰸁"; CLASS="critical"
elif [ "$TEMP" -ge 75 ]; then ICON="󱃂";  CLASS="warning"
elif [ "$TEMP" -ge 60 ]; then ICON="󰔏"; CLASS="warm"
else                           ICON="󰔏"; CLASS="normal"
fi

echo "{\"text\": \"${ICON} ${TEMP}°C\", \"tooltip\": \"CPU Temp: ${TEMP}°C\", \"class\": \"${CLASS}\"}"
SCRIPT

chmod +x "$REAL_HOME/.config/waybar/scripts/thermal-monitor.sh"
print_success "thermal-monitor.sh created"

print_header "Creating Power Profile Script"
print_step "Writing power-profile.sh..."

cat << 'SCRIPT' > "$REAL_HOME/.config/waybar/scripts/power-profile.sh"
#!/bin/bash

PROFILE=$(powerprofilesctl get 2>/dev/null)

case "$PROFILE" in
    power-saver)
        echo '{"text": "ECO", "tooltip": "Power profile: power-saver", "class": "eco"}'
        ;;
    performance)
        echo '{"text": "BOOST", "tooltip": "Power profile: performance", "class": "boost"}'
        ;;
    balanced)
        echo '{"text": "NORMAL", "tooltip": "Power profile: balanced", "class": "normal"}'
        ;;
    *)
        echo '{"text": "N/A", "tooltip": "Power profile unavailable", "class": "unknown"}'
        ;;
esac
SCRIPT

chmod +x "$REAL_HOME/.config/waybar/scripts/power-profile.sh"
print_success "power-profile.sh created"

# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║  Step 2: Waybar Configuration (no battery module)                         ║
# ╚═══════════════════════════════════════════════════════════════════════════╝
print_header "Creating Waybar Configuration"
print_step "Writing config.jsonc..."

cat << 'CONFIG' > "$REAL_HOME/.config/waybar/config.jsonc"
{
  "reload_style_on_change": true,
  "layer": "top",
  "position": "top",
  "spacing": 0,
  "height": 26,

  "modules-left": [
    "custom/omarchy",
    "hyprland/workspaces"
  ],
  "modules-center": [
    "custom/localsend",
    "custom/hyprwhspr",
    "clock",
    "custom/weather",
    "custom/update",
    "custom/caffeine",
    "custom/nightlight",
    "custom/voxtype",
    "custom/screenrecording-indicator"
  ],

  // Battery removed — desktop PC has no battery
  "modules-right": [
    "custom/ram-disk",
    "custom/thermal",
    "custom/power-profile",
    "group/tray-expander",
    "custom/network-speed",
    "network",
    "bluetooth",
    "pulseaudio"
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
  "custom/power-profile": {
    "exec": "$HOME/.config/waybar/scripts/power-profile.sh",
    "return-type": "json",
    "interval": 10,
    "format": "{}",
    "tooltip": true
  },

  "clock": {
    "format": "{:L%A %I:%M %p}",
    "format-alt": "{:L%d %B W%V %Y}",
    "tooltip": false,
    "on-click-right": "omarchy-launch-floating-terminal-with-presentation omarchy-tz-select"
  },

  "custom/weather": {
    "exec": "$HOME/.config/waybar/scripts/weather.sh",
    "return-type": "json",
    "interval": 300,
    "format": "{}",
    "tooltip": true,
    "on-click": "xdg-open 'https://wttr.in'"
  },

  "custom/nightlight": {
    "exec": "$HOME/.config/waybar/scripts/nightlight.sh",
    "return-type": "json",
    "on-click": "$HOME/.config/waybar/scripts/nightlight.sh toggle",
    "interval": 5,
    "signal": 10,
    "tooltip": true
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

print_success "config.jsonc created (no battery module)"

# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║  Step 3: Stylesheet                                                       ║
# ║  NOTE: The @import uses a quoted heredoc so $HOME won't expand —          ║
# ║         we write a placeholder and fix it with sed immediately after.     ║
# ╚═══════════════════════════════════════════════════════════════════════════╝
print_header "Creating Stylesheet"
print_step "Writing style.css..."

cat << 'STYLE' > "$REAL_HOME/.config/waybar/style.css"
/* ═══════════════════════════════════════════════════════════════════════════
   🎨 Aesthetic Waybar Theme - Omarchy Integrated
   ═══════════════════════════════════════════════════════════════════════════ */

/* Import omarchy theme colors — path fixed at install time by installer */
@import url("file://OMARCHY_THEME_PATH/.config/omarchy/current/theme/waybar.css");

@define-color bg-primary alpha(@background, 0.92);
@define-color bg-secondary alpha(@background, 0.95);
@define-color bg-tertiary alpha(@foreground, 0.08);
@define-color bg-hover alpha(@foreground, 0.15);

@define-color text-primary @foreground;
@define-color text-secondary alpha(@foreground, 0.7);
@define-color text-dim alpha(@foreground, 0.4);

@define-color accent #7d82d9;
@define-color accent-pink #c89dc1;
@define-color accent-mauve #c2c4f0;
@define-color accent-red #ED5B5A;
@define-color accent-peach #F99957;
@define-color accent-yellow #E9BB4F;
@define-color accent-green #92a593;
@define-color accent-teal #a3bfd1;
@define-color accent-sky #a3bfd1;
@define-color accent-sapphire #6d7db6;
@define-color accent-blue #7d82d9;
@define-color accent-lavender #c2c4f0;

@define-color border-color alpha(@foreground, 0.12);
@define-color shadow-color rgba(0, 0, 0, 0.4);

* {
    font-family: "JetBrainsMono Nerd Font", "Symbols Nerd Font", monospace;
    font-size: 13px;
    font-weight: 500;
    min-height: 0;
    padding: 0;
    margin: 0;
}

window#waybar {
    background: transparent;
    color: @text-primary;
}

window#waybar>box {
    background: @bg-primary;
    border-bottom: 1px solid @border-color;
    margin: 0;
    padding: 0 6px;
}

.modules-left,
.modules-center,
.modules-right {
    padding: 0;
}

#custom-omarchy,
#workspaces,
#clock,
#custom-weather,
#custom-caffeine,
#custom-nightlight,
#custom-ram-disk,
#custom-thermal,
#custom-power-profile,
#network,
#custom-network-speed,
#bluetooth,
#pulseaudio,
#tray,
#custom-update,
#custom-localsend,
#custom-hyprwhspr,
#custom-voxtype,
#custom-screenrecording-indicator,
#custom-expand-icon {
    background: transparent;
    padding: 0 8px;
    margin: 0 2px;
    border-bottom: 2px solid transparent;
    transition: all 0.2s ease;
}

#custom-omarchy:hover,
#clock:hover,
#custom-weather:hover,
#custom-caffeine:hover,
#custom-ram-disk:hover,
#custom-thermal:hover,
#custom-power-profile:hover,
#network:hover,
#custom-network-speed:hover,
#bluetooth:hover,
#pulseaudio:hover,
#custom-update:hover,
#custom-nightlight:hover,
#custom-localsend:hover,
#custom-hyprwhspr:hover,
#custom-voxtype:hover,
#custom-expand-icon:hover {
    background: @bg-tertiary;
    border-bottom-color: @accent;
    box-shadow: none;
}

#custom-omarchy {
    font-size: 16px;
    color: @accent-mauve;
    font-weight: bold;
    padding: 0 10px;
    background: transparent;
    border: none;
}

#custom-omarchy:hover {
    background: @bg-tertiary;
    box-shadow: none;
}

#workspaces {
    background: transparent;
    margin: 0;
    padding: 0;
}

#workspaces button {
    color: @text-secondary;
    background: transparent;
    border: 1px solid transparent;
    border-radius: 0;
    padding: 0 10px;
    margin: 0;
    transition: none;
}

#workspaces button:hover {
    color: @text-primary;
    background: @bg-tertiary;
}

#workspaces button.active {
    color: @bg-primary;
    background: @accent;
    border: 1px solid @accent;
    font-weight: bold;
    box-shadow: none;
}

#workspaces button.urgent {
    color: @bg-primary;
    background: @accent-red;
    border: 1px solid @accent-red;
}

#clock {
    color: @accent-sky;
    font-weight: 600;
    background: transparent;
    border: none;
    padding: 0 8px;
}

#clock:hover {
    background: @bg-tertiary;
}

#custom-weather {
    color: @accent-yellow;
    background: transparent;
    border: none;
}

#custom-weather:hover {
    background: @bg-tertiary;
}

#custom-caffeine {
    color: @text-dim;
}

#custom-caffeine.active {
    color: @accent-peach;
    background: transparent;
    border-bottom: 2px solid @accent-peach;
    box-shadow: none;
}

#custom-nightlight {
    color: @text-dim;
}

#custom-nightlight.active {
    color: @accent-peach;
    background: transparent;
    border-bottom: 2px solid @accent-peach;
    box-shadow: none;
}

#custom-ram-disk {
    color: @accent-green;
    background: transparent;
    border: none;
}

#custom-thermal {
    color: @accent-peach;
    background: transparent;
    border: none;
}

#custom-thermal.warm {
    color: @accent-yellow;
}

#custom-thermal.warning {
    color: @accent-peach;
    border-bottom: 2px solid @accent-peach;
}

#custom-thermal.critical {
    color: @accent-red;
    border-bottom: 2px solid @accent-red;
    animation: blink 1s infinite;
}

@keyframes blink {
    0%   { opacity: 1; }
    50%  { opacity: 0.4; }
    100% { opacity: 1; }
}

#network {
    color: @accent-sapphire;
}

#network.disconnected {
    color: @accent-red;
    background: transparent;
}

#custom-network-speed {
    color: @accent-teal;
    font-size: 11px;
}

#bluetooth {
    color: @accent-blue;
}

#bluetooth.connected {
    color: @accent-sapphire;
    background: transparent;
    border-bottom: 2px solid @accent-sapphire;
}

#bluetooth.disabled {
    color: @text-dim;
}

#pulseaudio {
    color: @accent-pink;
}

#pulseaudio.muted {
    color: @text-dim;
    background: @bg-tertiary;
}

#tray {
    background: transparent;
    border: none;
    padding: 2px 8px;
}

#tray>.passive {
    -gtk-icon-effect: dim;
}

#tray>.needs-attention {
    -gtk-icon-effect: highlight;
}

#custom-expand-icon {
    color: @text-dim;
    padding: 2px 8px;
    font-size: 10px;
}

#custom-update {
    color: @accent-green;
}

#custom-localsend {
    color: @accent-mauve;
}

#custom-hyprwhspr {
    color: @accent-lavender;
}

#custom-voxtype {
    color: @accent-pink;
}

#custom-screenrecording-indicator {
    color: @accent-red;
}

tooltip {
    background: @bg-secondary;
    border: 2px solid @border-color;
    border-radius: 0;
}

tooltip label {
    color: @text-primary;
    font-size: 12px;
}
STYLE

# ────────────────────────────────────────────────────────────────────────────
# Fix the @import path to use the actual current user's home directory.
# This was the root cause of the original breakage on the desktop.
# ────────────────────────────────────────────────────────────────────────────
print_step "Fixing @import path for user: $REAL_HOME ..."
sed -i "s|OMARCHY_THEME_PATH|${REAL_HOME}|g" "$REAL_HOME/.config/waybar/style.css"

# Verify the fix
IMPORT_LINE=$(grep "@import" "$REAL_HOME/.config/waybar/style.css")
print_success "style.css created"
print_info "Import line: $IMPORT_LINE"

# Also verify the omarchy theme file actually exists and warn if not
THEME_FILE="$REAL_HOME/.config/omarchy/current/theme/waybar.css"
if [ ! -f "$THEME_FILE" ]; then
    print_warn "Omarchy theme file not found at: $THEME_FILE"
    print_warn "Waybar colors may be broken until omarchy is set up correctly."
else
    print_success "Omarchy theme file found ✓"
fi

# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║  Step 4: Reload Waybar                                                    ║
# ╚═══════════════════════════════════════════════════════════════════════════╝
print_header "Reloading Waybar"
print_step "Stopping existing waybar process..."
killall waybar 2>/dev/null || true
sleep 0.5

print_step "Starting fresh waybar instance..."
nohup waybar > /dev/null 2>&1 &

sleep 1
print_success "Waybar started"

echo ""
echo -e "${MAGENTA}${BOLD}╔═══════════════════════════════════════════════════════════════════════════╗${RESET}"
echo -e "${MAGENTA}${BOLD}║${RESET}                    ${GREEN}${BOLD}✨ Installation Complete! ✨${RESET}                        ${MAGENTA}${BOLD}║${RESET}"
echo -e "${MAGENTA}${BOLD}╚═══════════════════════════════════════════════════════════════════════════╝${RESET}"
echo ""
echo -e "${CYAN}${BOLD}  What was fixed for desktop:${RESET}"
echo -e "${DIM}  ─────────────────────────────────────────────────────────────${RESET}"
echo -e "  ${GREEN}●${RESET} ${BOLD}@import path${RESET} now uses your actual username (${CYAN}$REAL_HOME${RESET})"
echo -e "  ${GREEN}●${RESET} ${BOLD}Battery module removed${RESET} — desktop PCs have no battery"
echo -e "  ${GREEN}●${RESET} ${BOLD}sudo-safe${RESET} — resolves correct home dir even when run with sudo"
echo -e "  ${GREEN}●${RESET} ${BOLD}RAM + Disk monitor${RESET} script created (ram-disk-monitor.sh)"
echo -e "  ${GREEN}●${RESET} ${BOLD}CPU Thermal monitor${RESET} script created (thermal-monitor.sh)"
echo -e "  ${DIM}    If temp shows N/A: sudo pacman -S lm_sensors && sudo sensors-detect${RESET}"
echo ""
echo -e "${DIM}  Enjoy your sharp waybar! 🚀${RESET}"
echo ""
