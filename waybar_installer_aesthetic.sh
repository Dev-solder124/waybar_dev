#!/bin/bash

# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║                    🎨 Waybar Aesthetic Installer                          ║
# ║            A clean, modern waybar configuration without BTC               ║
# ╚═══════════════════════════════════════════════════════════════════════════╝

set -e

# ────────────────────────────────────────────────────────────────────────────
# Color definitions for pretty output
# ────────────────────────────────────────────────────────────────────────────
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly MAGENTA='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly BOLD='\033[1m'
readonly DIM='\033[2m'
readonly RESET='\033[0m'

# ────────────────────────────────────────────────────────────────────────────
# Helper functions
# ────────────────────────────────────────────────────────────────────────────
print_header() {
    echo -e "\n${MAGENTA}${BOLD}╭─────────────────────────────────────────────────────────────╮${RESET}"
    echo -e "${MAGENTA}${BOLD}│${RESET} ${CYAN}$1${RESET}"
    echo -e "${MAGENTA}${BOLD}╰─────────────────────────────────────────────────────────────╯${RESET}"
}

print_step() {
    echo -e "${GREEN}  ▸${RESET} $1"
}

print_success() {
    echo -e "${GREEN}  ✓${RESET} $1"
}

print_info() {
    echo -e "${BLUE}  ℹ${RESET} ${DIM}$1${RESET}"
}

# ────────────────────────────────────────────────────────────────────────────
# Ensure directories exist
# ────────────────────────────────────────────────────────────────────────────
mkdir -p "$HOME/.config/waybar/scripts" "$HOME/.config/waybar/shaders"

# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║                    Step 1: Caffeine Toggle Script                         ║
# ╚═══════════════════════════════════════════════════════════════════════════╝
print_header "Creating Caffeine Toggle Script"
print_step "Writing caffeine.sh..."

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
print_success "caffeine.sh created and made executable"

# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║                    Step 1b: Nightlight Toggle Script                      ║
# ╚═══════════════════════════════════════════════════════════════════════════╝
print_header "Creating Nightlight Toggle Script"
print_step "Writing nightlight.sh..."

cat << 'SHADER' > "$HOME/.config/waybar/shaders/nightlight.frag"
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

cat << 'SCRIPT' > "$HOME/.config/waybar/scripts/nightlight.sh"
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
SCRIPT

chmod +x "$HOME/.config/waybar/scripts/nightlight.sh"
print_success "nightlight.sh created and made executable"

print_header "Creating Power Profile Script"
print_step "Writing power-profile.sh..."

cat << 'SCRIPT' > "$HOME/.config/waybar/scripts/power-profile.sh"
#!/bin/bash

PROFILE=$(powerprofilesctl get 2>/dev/null)

toggle_profile() {
    case "$PROFILE" in
        power-saver) NEXT="balanced" ;;
        balanced) NEXT="performance" ;;
        performance) NEXT="power-saver" ;;
        *) NEXT="balanced" ;;
    esac

    powerprofilesctl set "$NEXT" 2>/dev/null
}

if [ "$1" = "toggle" ]; then
    toggle_profile
    PROFILE=$(powerprofilesctl get 2>/dev/null)
fi

case "$PROFILE" in
    power-saver)
        echo '{"text": "MID 🍏", "tooltip": "Power profile: power-saver", "class": "eco"}'
        ;;
    performance)
        echo '{"text": "HOT 🔥", "tooltip": "Power profile: performance", "class": "boost"}'
        ;;
    balanced)
        echo '{"text": "TEN 💎", "tooltip": "Power profile: balanced", "class": "normal"}'
        ;;
    *)
        echo '{"text": "N/A", "tooltip": "Power profile unavailable", "class": "unknown"}'
        ;;
esac
SCRIPT

chmod +x "$HOME/.config/waybar/scripts/power-profile.sh"
print_success "power-profile.sh created and made executable"

# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║                    Step 2: Waybar Configuration                           ║
# ╚═══════════════════════════════════════════════════════════════════════════╝
print_header "Creating Waybar Configuration"
print_step "Writing config.jsonc..."

cat << 'CONFIG' > "$HOME/.config/waybar/config.jsonc"
{
  "reload_style_on_change": true,
  "layer": "top",
  "position": "top",
  "spacing": 0,
  "height": 26,

  // ═══════════════════════════════════════════════════════════════════════════
  // Module Layout (No BTC - Clean & Minimal)
  // ═══════════════════════════════════════════════════════════════════════════
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
  "modules-right": [
    "custom/ram-disk",
    "custom/thermal",
    "custom/power-profile",
    "group/tray-expander",
    "network",
    "bluetooth",
    "pulseaudio",
    "battery"
  ],

  // ═══════════════════════════════════════════════════════════════════════════
  // Workspaces
  // ═══════════════════════════════════════════════════════════════════════════
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

  // ═══════════════════════════════════════════════════════════════════════════
  // Custom Modules
  // ═══════════════════════════════════════════════════════════════════════════
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
    "tooltip": true,
    "on-click": "$HOME/.config/waybar/scripts/power-profile.sh toggle"
  },

  // ═══════════════════════════════════════════════════════════════════════════
  // Clock & Weather
  // ═══════════════════════════════════════════════════════════════════════════
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

  // ═══════════════════════════════════════════════════════════════════════════
  // Network & Connectivity
  // ═══════════════════════════════════════════════════════════════════════════
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


  // ═══════════════════════════════════════════════════════════════════════════
  // Power & Audio
  // ═══════════════════════════════════════════════════════════════════════════
  "battery": {
    "format": "{capacity}% {icon}\n{power}W",
    "format-time": "{H}:{M:02}",
    "format-discharging": "{capacity}% {icon}\n{power}W",
    "format-charging": "{capacity}% 󰂄\n{power}W",
    "format-plugged": "{capacity}%\n{power}W",
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

  // ═══════════════════════════════════════════════════════════════════════════
  // System Tray & Utilities
  // ═══════════════════════════════════════════════════════════════════════════
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

print_success "config.jsonc created"

# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║                    Step 3: Aesthetic Stylesheet                           ║
# ╚═══════════════════════════════════════════════════════════════════════════╝
print_header "Creating Aesthetic Stylesheet"
print_step "Writing style.css..."

cat << 'STYLE' > "$HOME/.config/waybar/style.css"
/* ═══════════════════════════════════════════════════════════════════════════
   🎨 Aesthetic Waybar Theme - Omarchy Integrated
   Uses colors from current omarchy theme
   ═══════════════════════════════════════════════════════════════════════════ */

/* Import omarchy theme colors (foreground + background) */
@import url("file:///home/dev/.config/omarchy/current/theme/waybar.css");

/* ─────────────────────────────────────────────────────────────────────────────
   Color Palette - Derived from Omarchy Theme
   ───────────────────────────────────────────────────────────────────────────── */
@define-color bg-primary alpha(@background, 0.92);
@define-color bg-secondary alpha(@background, 0.95);
@define-color bg-tertiary alpha(@foreground, 0.08);
@define-color bg-hover alpha(@foreground, 0.15);

@define-color text-primary @foreground;
@define-color text-secondary alpha(@foreground, 0.7);
@define-color text-dim alpha(@foreground, 0.4);

/* Accent colors derived from omarchy colors.toml palette */
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

/* ─────────────────────────────────────────────────────────────────────────────
   Base Bar Styling - Full Width (No Outer Padding)
   ───────────────────────────────────────────────────────────────────────────── */
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

/* ─────────────────────────────────────────────────────────────────────────────
   Module Container Styling
   ───────────────────────────────────────────────────────────────────────────── */
.modules-left,
.modules-center,
.modules-right {
    padding: 0;
}

/* ─────────────────────────────────────────────────────────────────────────────
   Base Module Styling - Pill Design with Hover Effects
   ───────────────────────────────────────────────────────────────────────────── */
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
#battery,
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
    /* Prepare for hover underline */
    transition: all 0.2s ease;
}

/* Hover state for all modules */
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
#battery:hover,
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

/* ─────────────────────────────────────────────────────────────────────────────
   Omarchy Logo - Text Accent
   ───────────────────────────────────────────────────────────────────────────── */
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

/* ─────────────────────────────────────────────────────────────────────────────
   Workspaces - Terminal Blocks
   ───────────────────────────────────────────────────────────────────────────── */
#workspaces {
    background: transparent;
    margin: 0;
    padding: 0;
}

#workspaces button {
    color: @text-secondary;
    background: transparent;
    border: 1px solid transparent;
    /* Placeholder for layout stability */
    border-radius: 0;
    padding: 0 10px;
    /* Wider for block feel */
    margin: 0;
    transition: none;
    /* Instant terminal feel */
}

#workspaces button:hover {
    color: @text-primary;
    background: @bg-tertiary;
}

#workspaces button.active {
    color: @bg-primary;
    /* Inverted text */
    background: @accent;
    /* Solid block background */
    border: 1px solid @accent;
    font-weight: bold;
    box-shadow: none;
}

#workspaces button.urgent {
    color: @bg-primary;
    background: @accent-red;
    border: 1px solid @accent-red;
}

/* ─────────────────────────────────────────────────────────────────────────────
   Clock
   ───────────────────────────────────────────────────────────────────────────── */
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

/* ─────────────────────────────────────────────────────────────────────────────
   Weather Module
   ───────────────────────────────────────────────────────────────────────────── */
#custom-weather {
    color: @accent-yellow;
    background: transparent;
    border: none;
}

#custom-weather:hover {
    background: @bg-tertiary;
}

/* ─────────────────────────────────────────────────────────────────────────────
   Caffeine Toggle - Simple Text
   ───────────────────────────────────────────────────────────────────────────── */
#custom-caffeine {
    color: @text-dim;
}

#custom-caffeine.active {
    color: @accent-peach;
    background: transparent;
    border-bottom: 2px solid @accent-peach;
    box-shadow: none;
}

/* ─────────────────────────────────────────────────────────────────────────────
   Nightlight Toggle
   ───────────────────────────────────────────────────────────────────────────── */
#custom-nightlight {
    color: @text-dim;
}

#custom-nightlight.active {
    color: @accent-peach;
    background: transparent;
    border-bottom: 2px solid @accent-peach;
    box-shadow: none;
}

/* ─────────────────────────────────────────────────────────────────────────────
   System Monitors - RAM, Disk, Thermal
   ───────────────────────────────────────────────────────────────────────────── */
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

/* ─────────────────────────────────────────────────────────────────────────────
   Network & Connectivity
   ───────────────────────────────────────────────────────────────────────────── */
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

/* ─────────────────────────────────────────────────────────────────────────────
   Bluetooth
   ───────────────────────────────────────────────────────────────────────────── */
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

/* ─────────────────────────────────────────────────────────────────────────────
   Audio - PulseAudio
   ───────────────────────────────────────────────────────────────────────────── */
#pulseaudio {
    color: @accent-pink;
}

#pulseaudio.muted {
    color: @text-dim;
    background: @bg-tertiary;
}

/* ─────────────────────────────────────────────────────────────────────────────
   Battery - Simple Colors
   ───────────────────────────────────────────────────────────────────────────── */
#battery {
    color: @text-primary;
    background: transparent;
    border: none;
}

#battery.charging {
    color: @accent-teal;
    background: transparent;
    border: none;
}

#battery.warning:not(.charging) {
    color: @accent-yellow;
    background: transparent;
    border: none;
}

#battery.critical:not(.charging) {
    color: @accent-red;
    background: transparent;
    border: none;
    animation: blink 1s infinite;
}

@keyframes blink {
    0% {
        opacity: 1;
    }

    50% {
        opacity: 0.5;
    }

    100% {
        opacity: 1;
    }
}

/* ─────────────────────────────────────────────────────────────────────────────
   System Tray
   ───────────────────────────────────────────────────────────────────────────── */
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

/* ─────────────────────────────────────────────────────────────────────────────
   Utility Modules
   ───────────────────────────────────────────────────────────────────────────── */
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

/* ─────────────────────────────────────────────────────────────────────────────
   Tooltip Styling - Sharp Borders
   ───────────────────────────────────────────────────────────────────────────── */
tooltip {
    background: @bg-secondary;
    border: 2px solid @border-color;
    border-radius: 0;
}

tooltip label {
    color: @text-primary;
    font-size: 12px;
}

/* ─────────────────────────────────────────────────────────────────────────────
   End of Theme
   ───────────────────────────────────────────────────────────────────────────── */
STYLE

print_success "style.css created with aesthetic theme"

# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║                    Step 4: Reload Waybar                                  ║
# ╚═══════════════════════════════════════════════════════════════════════════╝
print_header "Reloading Waybar"
print_step "Stopping existing waybar process..."

killall waybar 2>/dev/null || true
sleep 0.5

print_step "Starting fresh waybar instance..."
nohup waybar > /dev/null 2>&1 &

sleep 1
print_success "Waybar reloaded successfully"

# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║                    Installation Complete                                   ║
# ╚═══════════════════════════════════════════════════════════════════════════╝
echo ""
echo -e "${MAGENTA}${BOLD}╔═══════════════════════════════════════════════════════════════════════════╗${RESET}"
echo -e "${MAGENTA}${BOLD}║${RESET}                    ${GREEN}${BOLD}✨ Installation Complete! ✨${RESET}                        ${MAGENTA}${BOLD}║${RESET}"
echo -e "${MAGENTA}${BOLD}╚═══════════════════════════════════════════════════════════════════════════╝${RESET}"
echo ""
echo -e "${CYAN}${BOLD}  What's Configured:${RESET}"
echo -e "${DIM}  ─────────────────────────────────────────────────────────────${RESET}"
echo -e "  ${GREEN}●${RESET} ${BOLD}Low-profile sharp design${RESET} (No Rounded Corners!)"
echo -e "  ${GREEN}●${RESET} ${BOLD}Solid Block Workspaces${RESET} for distinct terminal feel"
echo -e "  ${GREEN}●${RESET} ${BOLD}Omarchy Integrated${RESET} color palette"
echo -e "  ${GREEN}●${RESET} ${BOLD}Full-width bar${RESET} with no wasted space"
echo -e "  ${GREEN}●${RESET} Minimalist modules: ${BOLD}Text-focused${RESET}"
echo -e "  ${GREEN}●${RESET} Battery states: ${BOLD}Color-coded text${RESET} (no background)"
echo -e "  ${GREEN}●${RESET} Clean layout without BTC ticker"
echo ""
echo -e "${DIM}  Enjoy your sharp new waybar! 🚀${RESET}"
echo ""
