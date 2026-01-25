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
mkdir -p "$HOME/.config/waybar/scripts"

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
    "custom/voxtype",
    "custom/screenrecording-indicator"
  ],
  "modules-right": [
    "custom/ram-disk",
    "custom/thermal",
    "group/tray-expander",
    "custom/network-speed",
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

  // ═══════════════════════════════════════════════════════════════════════════
  // Clock & Weather
  // ═══════════════════════════════════════════════════════════════════════════
  "clock": {
    "format": "{:L%A %H:%M}",
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

  "custom/network-speed": {
    "exec": "$HOME/.config/waybar/scripts/network-speed.sh",
    "return-type": "json",
    "interval": 2,
    "format": "{}",
    "tooltip": true,
    "on-click": "omarchy-launch-wifi"
  },

  // ═══════════════════════════════════════════════════════════════════════════
  // Power & Audio
  // ═══════════════════════════════════════════════════════════════════════════
  "battery": {
    "format": "{capacity}% {icon}",
    "format-time": "{H}:{M:02}",
    "format-discharging": "{capacity}% {icon}",
    "format-charging": "{capacity}% 󰂄 ({power}W)",
    "format-plugged": "{capacity}%  ({power}W)",
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
   🎨 Aesthetic Waybar Theme
   A modern, glassmorphic design with smooth gradients and animations
   ═══════════════════════════════════════════════════════════════════════════ */

/* ─────────────────────────────────────────────────────────────────────────────
   Color Palette (Catppuccin-inspired with custom tweaks)
   ───────────────────────────────────────────────────────────────────────────── */
@define-color bg-primary rgba(30, 30, 46, 0.85);
@define-color bg-secondary rgba(49, 50, 68, 0.9);
@define-color bg-tertiary rgba(69, 71, 90, 0.8);
@define-color bg-hover rgba(88, 91, 112, 0.9);

@define-color text-primary #cdd6f4;
@define-color text-secondary #a6adc8;
@define-color text-dim #6c7086;

@define-color accent-pink #f5c2e7;
@define-color accent-mauve #cba6f7;
@define-color accent-red #f38ba8;
@define-color accent-peach #fab387;
@define-color accent-yellow #f9e2af;
@define-color accent-green #a6e3a1;
@define-color accent-teal #94e2d5;
@define-color accent-sky #89dceb;
@define-color accent-sapphire #74c7ec;
@define-color accent-blue #89b4fa;
@define-color accent-lavender #b4befe;

@define-color border-color rgba(180, 190, 254, 0.15);
@define-color shadow-color rgba(0, 0, 0, 0.3);

/* ─────────────────────────────────────────────────────────────────────────────
   Base Bar Styling - Floating Glassmorphic Design
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

window#waybar > box {
    background: @bg-primary;
    border: 1px solid @border-color;
    border-radius: 14px;
    margin: 6px 10px 0 10px;
    padding: 0 8px;
    box-shadow: 0 4px 20px @shadow-color,
                inset 0 1px 0 rgba(255, 255, 255, 0.05);
}

/* ─────────────────────────────────────────────────────────────────────────────
   Module Container Styling
   ───────────────────────────────────────────────────────────────────────────── */
.modules-left,
.modules-center,
.modules-right {
    padding: 0 4px;
}

/* ─────────────────────────────────────────────────────────────────────────────
   Base Module Styling - Pill Design with Hover Effects
   ───────────────────────────────────────────────────────────────────────────── */
#custom-omarchy,
#workspaces,
#clock,
#custom-weather,
#custom-caffeine,
#custom-ram-disk,
#custom-thermal,
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
    background: @bg-secondary;
    border: 1px solid @border-color;
    border-radius: 10px;
    padding: 2px 12px;
    margin: 4px 3px;
    transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}

/* Hover state for all modules */
#custom-omarchy:hover,
#clock:hover,
#custom-weather:hover,
#custom-caffeine:hover,
#custom-ram-disk:hover,
#custom-thermal:hover,
#network:hover,
#custom-network-speed:hover,
#bluetooth:hover,
#pulseaudio:hover,
#battery:hover,
#custom-update:hover,
#custom-localsend:hover,
#custom-hyprwhspr:hover,
#custom-voxtype:hover,
#custom-expand-icon:hover {
    background: @bg-hover;
    border-color: rgba(180, 190, 254, 0.3);
    box-shadow: 0 0 12px rgba(180, 190, 254, 0.15);
}

/* ─────────────────────────────────────────────────────────────────────────────
   Omarchy Logo - Gradient Accent
   ───────────────────────────────────────────────────────────────────────────── */
#custom-omarchy {
    font-size: 16px;
    color: @accent-mauve;
    padding: 2px 14px;
    background: linear-gradient(135deg, 
        rgba(203, 166, 247, 0.2), 
        rgba(180, 190, 254, 0.1));
    border-color: rgba(203, 166, 247, 0.3);
}

#custom-omarchy:hover {
    background: linear-gradient(135deg, 
        rgba(203, 166, 247, 0.35), 
        rgba(180, 190, 254, 0.2));
    box-shadow: 0 0 16px rgba(203, 166, 247, 0.25);
}

/* ─────────────────────────────────────────────────────────────────────────────
   Workspaces - Modern Indicator Pills
   ───────────────────────────────────────────────────────────────────────────── */
#workspaces {
    padding: 2px 6px;
    background: @bg-tertiary;
}

#workspaces button {
    color: @text-dim;
    background: transparent;
    border: none;
    border-radius: 8px;
    padding: 2px 10px;
    margin: 2px;
    min-width: 20px;
    transition: all 0.25s cubic-bezier(0.4, 0, 0.2, 1);
}

#workspaces button:hover {
    color: @text-secondary;
    background: rgba(180, 190, 254, 0.15);
}

#workspaces button.active {
    color: @bg-primary;
    background: linear-gradient(135deg, @accent-lavender, @accent-blue);
    font-weight: 700;
    box-shadow: 0 2px 8px rgba(137, 180, 250, 0.35);
}

#workspaces button.urgent {
    color: @bg-primary;
    background: linear-gradient(135deg, @accent-red, @accent-peach);
}

/* ─────────────────────────────────────────────────────────────────────────────
   Clock - Central Focus with Gradient Text
   ───────────────────────────────────────────────────────────────────────────── */
#clock {
    font-weight: 600;
    font-size: 13px;
    color: @accent-sky;
    background: linear-gradient(135deg, 
        rgba(137, 220, 235, 0.15), 
        rgba(116, 199, 236, 0.08));
    border-color: rgba(137, 220, 235, 0.25);
    padding: 2px 16px;
}

#clock:hover {
    background: linear-gradient(135deg, 
        rgba(137, 220, 235, 0.25), 
        rgba(116, 199, 236, 0.15));
}

/* ─────────────────────────────────────────────────────────────────────────────
   Weather Module
   ───────────────────────────────────────────────────────────────────────────── */
#custom-weather {
    color: @accent-yellow;
    background: linear-gradient(135deg, 
        rgba(249, 226, 175, 0.12), 
        rgba(250, 179, 135, 0.08));
    border-color: rgba(249, 226, 175, 0.2);
}

#custom-weather:hover {
    background: linear-gradient(135deg, 
        rgba(249, 226, 175, 0.22), 
        rgba(250, 179, 135, 0.15));
}

/* ─────────────────────────────────────────────────────────────────────────────
   Caffeine Toggle - Dynamic States
   ───────────────────────────────────────────────────────────────────────────── */
#custom-caffeine {
    color: @text-dim;
}

#custom-caffeine.active {
    color: @accent-peach;
    background: linear-gradient(135deg, 
        rgba(250, 179, 135, 0.2), 
        rgba(249, 226, 175, 0.12));
    border-color: rgba(250, 179, 135, 0.35);
    box-shadow: 0 0 10px rgba(250, 179, 135, 0.3);
}

/* ─────────────────────────────────────────────────────────────────────────────
   System Monitors - RAM, Disk, Thermal
   ───────────────────────────────────────────────────────────────────────────── */
#custom-ram-disk {
    color: @accent-green;
    background: linear-gradient(135deg, 
        rgba(166, 227, 161, 0.12), 
        rgba(148, 226, 213, 0.08));
    border-color: rgba(166, 227, 161, 0.2);
}

#custom-thermal {
    color: @accent-peach;
    background: linear-gradient(135deg, 
        rgba(250, 179, 135, 0.12), 
        rgba(243, 139, 168, 0.08));
    border-color: rgba(250, 179, 135, 0.2);
}

/* ─────────────────────────────────────────────────────────────────────────────
   Network & Connectivity
   ───────────────────────────────────────────────────────────────────────────── */
#network {
    color: @accent-sapphire;
}

#network.disconnected {
    color: @accent-red;
    background: linear-gradient(135deg, 
        rgba(243, 139, 168, 0.15), 
        rgba(243, 139, 168, 0.08));
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
    background: linear-gradient(135deg, 
        rgba(116, 199, 236, 0.15), 
        rgba(137, 180, 250, 0.1));
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
   Battery - Color-coded States with Gradients
   ───────────────────────────────────────────────────────────────────────────── */
#battery {
    color: @accent-green;
    background: linear-gradient(135deg, 
        rgba(166, 227, 161, 0.12), 
        rgba(166, 227, 161, 0.06));
    border-color: rgba(166, 227, 161, 0.2);
}

#battery.charging {
    color: @accent-teal;
    background: linear-gradient(135deg, 
        rgba(148, 226, 213, 0.18), 
        rgba(166, 227, 161, 0.1));
    border-color: rgba(148, 226, 213, 0.3);
}

#battery.warning:not(.charging) {
    color: @accent-yellow;
    background: linear-gradient(135deg, 
        rgba(249, 226, 175, 0.2), 
        rgba(250, 179, 135, 0.12));
    border-color: rgba(249, 226, 175, 0.35);
}

#battery.critical:not(.charging) {
    color: @accent-red;
    background: linear-gradient(135deg, 
        rgba(243, 139, 168, 0.25), 
        rgba(243, 139, 168, 0.12));
    border-color: rgba(243, 139, 168, 0.4);
    box-shadow: 0 0 12px rgba(243, 139, 168, 0.4);
}

/* ─────────────────────────────────────────────────────────────────────────────
   System Tray
   ───────────────────────────────────────────────────────────────────────────── */
#tray {
    background: transparent;
    border: none;
    padding: 2px 8px;
}

#tray > .passive {
    -gtk-icon-effect: dim;
}

#tray > .needs-attention {
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
   Tooltip Styling - Glassmorphic
   ───────────────────────────────────────────────────────────────────────────── */
tooltip {
    background: @bg-primary;
    border: 1px solid @border-color;
    border-radius: 10px;
    padding: 8px 14px;
    box-shadow: 0 4px 16px @shadow-color;
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
echo -e "  ${GREEN}●${RESET} ${BOLD}Glassmorphic floating bar${RESET} with rounded corners"
echo -e "  ${GREEN}●${RESET} ${BOLD}Catppuccin-inspired${RESET} color palette"
echo -e "  ${GREEN}●${RESET} ${BOLD}Smooth animations${RESET} and hover effects"
echo -e "  ${GREEN}●${RESET} ${BOLD}Gradient accents${RESET} on workspaces, clock, battery"
echo -e "  ${GREEN}●${RESET} Battery states: ${BOLD}green${RESET} → ${YELLOW}yellow${RESET} → ${RED}red${RESET}"
echo -e "  ${GREEN}●${RESET} Caffeine toggle: ${BOLD}zzz${RESET} / ${BOLD}☕ On${RESET}"
echo -e "  ${GREEN}●${RESET} Clean layout without BTC ticker"
echo ""
echo -e "${DIM}  Enjoy your beautiful new waybar! 🎨✨${RESET}"
echo ""
