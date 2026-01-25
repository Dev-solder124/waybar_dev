#!/bin/bash

# 1. Backup existing config
echo ":: Backing up current Waybar config..."
if [ -d "$HOME/.config/waybar" ]; then
    cp -r "$HOME/.config/waybar" "$HOME/.config/waybar.stock.bak.$(date +%s)"
else
    mkdir -p "$HOME/.config/waybar"
fi

# 2. Create script directory
mkdir -p "$HOME/.config/waybar/scripts"

# 3. Write config.jsonc (Apple Display removed)
cat << 'EOF' > "$HOME/.config/waybar/config.jsonc"
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
    "tooltip-format": "Omarchy Menu\n\nSuper + Alt + Space"
  },
  "custom/update": {
    "format": "",
    "exec": "omarchy-update-available",
    "on-click": "omarchy-launch-floating-terminal-with-presentation omarchy-update",
    "tooltip-format": "Omarchy update available",
    "signal": 7,
    "interval": 21600
  },
  "custom/ram-disk": {
    "exec": "$HOME/.config/waybar/scripts/ram-disk-monitor.sh",
    "return-type": "json",
    "interval": 5,
    "format": "{}",
    "tooltip": true,
    "on-click": "btop-float"
  },
  "custom/thermal": {
    "exec": "$HOME/.config/waybar/scripts/thermal-monitor.sh",
    "return-type": "json",
    "interval": 5,
    "format": "{}",
    "tooltip": true,
    "on-click": "btop-float"
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
    "format-discharging": "{icon} {time}",
    "format-charging": "{icon} {time}",
    "format-plugged": "{icon}",
    "format-not-charging": "{icon}",
    "format-icons": {
      "charging": ["󰢜", "󰂆", "󰂇", "󰂈", "󰢝", "󰂉", "󰢞", "󰂊", "󰂋", "󰂅"],
      "default": ["󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"]
    },
    "format-full": "󰂅",
    "tooltip-format-discharging": "{power:>1.0f}W↓ {capacity}%",
    "tooltip-format-charging": "{power:>1.0f}W↑ {capacity}%",
    "tooltip-format-full": "Fully charged",
    "tooltip-format-plugged": "{capacity}% plugged in",
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
    "on-click": "$HOME/.local/bin/omarchy-cmd-caffeine",
    "exec": "$HOME/.config/waybar/scripts/caffeine-indicator.sh",
    "signal": 9,
    "return-type": "json",
    "interval": 5
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
  },
  "custom/workspaces-monitor": {
    "exec": "$HOME/.config/waybar/scripts/workspaces-monitor.sh",
    "return-type": "json",
    "format": "{}",
    "tooltip": true
  }
}
EOF

# 4. Write style.css (Apple CSS removed)
cat << 'EOF' > "$HOME/.config/waybar/style.css"
@import "../omarchy/current/theme/waybar.css";

* {
  background-color: @background;
  color: @foreground;
  border: none;
  border-radius: 0;
  min-height: 0;
  font-family: 'JetBrainsMono Nerd Font';
  font-size: 12px;
}

.modules-left { margin-left: 8px; }
.modules-right { margin-right: 8px; }

#workspaces button {
  all: initial;
  padding: 0 4px;
  margin: 4px 2px;
  min-width: 14px;
  min-height: 14px;
  border: 1px solid transparent;
  border-radius: 5px;
}

#workspaces button.empty { opacity: 0.5; }
#workspaces button.active {
  border-color: @foreground;
  border-radius: 5px;
}
#workspaces button.hosting-monitor {
  box-shadow: inset 0 -2px 0 0 @foreground;
  padding-bottom: 2px;
}
#workspaces button.active.hosting-monitor {
  box-shadow: inset 0 -2px 0 0 @foreground;
}

#cpu, #battery, #pulseaudio, #custom-omarchy,
#custom-screenrecording-indicator, #custom-update {
  min-width: 12px;
  margin: 0 7.5px;
}

#tray { margin-right: 16px; }
#bluetooth { margin-right: 17px; }
#network { margin-right: 25px; }

#custom-network-speed {
  font-size: 9px;
  padding: 0 6px;
  margin-right: 4px;
  min-width: 45px;
}

#custom-expand-icon { margin-right: 18px; }
tooltip { padding: 2px; }
#custom-update { font-size: 10px; }
#clock { margin-left: 5px; }
.hidden { opacity: 0; }

#custom-screenrecording-indicator {
  min-width: 12px;
  margin-left: 5px;
  font-size: 10px;
  padding-bottom: 1px;
}
#custom-screenrecording-indicator.active { color: #a55555; }

#custom-caffeine {
  min-width: 12px;
  margin-left: 12.75px;
  margin-bottom: 0px;
  font-size: 13px;
}
#custom-caffeine.active { color: #55a555; }

#custom-weather { margin-left: 12px; margin-right: 8px; }
#custom-btc { margin-right: 12px; }
#image-syncthing { margin: 0 8px; }
#custom-localsend { margin-right: 12px; font-size: 14px; }
#custom-localsend:hover { opacity: 0.7; }

#custom-hyprwhspr {
  margin-right: 8.75px;
  font-size: 13px;
  font-weight: bold;
  border-top: 2px solid transparent;
  border-bottom: 2px solid transparent;
  transition: color 150ms ease-in-out, border-color 150ms ease-in-out;
}
#custom-hyprwhspr.ready { color: inherit; border-color: transparent; }
#custom-hyprwhspr.recording {
  color: #E75143;
  border-bottom-color: #E75143;
  font-family: monospace;
  letter-spacing: 0.5px;
}
#custom-hyprwhspr.stopped { color: inherit; border-color: transparent; }
#custom-hyprwhspr.error { color: #d97706; border-bottom-color: #d97706; }
#custom-hyprwhspr:hover { opacity: 0.8; }

#custom-thermal {
  font-size: 9px;
  padding: 0 8px;
  margin: 0 4px;
}
#custom-thermal.hot { color: #f38ba8; }

#custom-ram-disk {
  font-size: 9px;
  padding: 0 8px;
  margin: 0 4px;
}

#custom-voxtype {
  min-width: 12px;
  margin: 0 0 0 7.5px;
}
#custom-voxtype.recording { color: #a55555; }
EOF

# 5. Write scripts
# weather.sh
cat << 'EOF' > "$HOME/.config/waybar/scripts/weather.sh"
#!/bin/bash
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/waybar"
LOCATION_CACHE="$CACHE_DIR/weather_location.json"
LOCATION_CACHE_MAX_AGE=86400
mkdir -p "$CACHE_DIR"

get_location() {
    if [[ -f "$LOCATION_CACHE" ]]; then
        cache_age=$(( $(date +%s) - $(stat -c %Y "$LOCATION_CACHE") ))
        if (( cache_age < LOCATION_CACHE_MAX_AGE )); then
            cat "$LOCATION_CACHE"
            return 0
        fi
    fi
    location=$(curl -sf "http://ip-api.com/json/?fields=status,city,lat,lon")
    if [[ -z "$location" ]] || [[ $(echo "$location" | jq -r '.status') != "success" ]]; then
        if [[ -f "$LOCATION_CACHE" ]]; then cat "$LOCATION_CACHE"; return 0; fi
        return 1
    fi
    echo "$location" > "$LOCATION_CACHE"
    echo "$location"
}

get_weather_icon() {
    local code=$1; local is_day=${2:-1}
    case $code in
        0) [[ $is_day -eq 1 ]] && echo "󰖙" || echo "󰖔" ;;
        1|2|3) [[ $is_day -eq 1 ]] && echo "󰖕" || echo "󰼱" ;;
        45|48) echo "󰖑" ;;
        51|53|55|56|57) echo "󰖗" ;;
        61|63|65|66|67|80|81|82) echo "󰖖" ;;
        71|73|75|77|85|86) echo "󰖘" ;;
        95|96|99) echo "󰖓" ;;
        *) echo "󰖐" ;;
    esac
}

get_weather_description() {
    local code=$1
    case $code in
        0) echo "Clear" ;; 1) echo "Mainly clear" ;; 2) echo "Partly cloudy" ;; 3) echo "Overcast" ;;
        45|48) echo "Fog" ;; 51|53|55) echo "Drizzle" ;; 56|57) echo "Freezing drizzle" ;;
        61|63|65) echo "Rain" ;; 66|67) echo "Freezing rain" ;; 71|73|75) echo "Snow" ;;
        77) echo "Snow grains" ;; 80|81|82) echo "Rain showers" ;; 85|86) echo "Snow showers" ;;
        95) echo "Thunderstorm" ;; 96|99) echo "Thunderstorm with hail" ;; *) echo "Unknown" ;;
    esac
}

main() {
    location=$(get_location)
    if [[ -z "$location" ]]; then echo '{"text": " --", "tooltip": "Location unavailable", "class": "error"}'; exit 0; fi

    lat=$(echo "$location" | jq -r '.lat'); lon=$(echo "$location" | jq -r '.lon')
    city=$(echo "$location" | jq -r '.city')
    weather=$(curl -sf "https://api.open-meteo.com/v1/forecast?latitude=${lat}&longitude=${lon}&current=temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,wind_speed_10m,is_day&timezone=auto")

    if [[ -z "$weather" ]]; then echo '{"text": " --", "tooltip": "Weather unavailable", "class": "error"}'; exit 0; fi

    temp=$(echo "$weather" | jq -r '.current.temperature_2m // empty')
    feels_like=$(echo "$weather" | jq -r '.current.apparent_temperature // empty')
    humidity=$(echo "$weather" | jq -r '.current.relative_humidity_2m // empty')
    wind=$(echo "$weather" | jq -r '.current.wind_speed_10m // empty')
    weather_code=$(echo "$weather" | jq -r '.current.weather_code // 0')
    is_day=$(echo "$weather" | jq -r '.current.is_day // 1')

    icon=$(get_weather_icon "$weather_code" "$is_day")
    description=$(get_weather_description "$weather_code")
    temp_fmt=$(printf "%.0f" "$temp")
    feels_fmt=$(printf "%.0f" "$feels_like")
    wind_fmt=$(printf "%.0f" "$wind")

    if (( temp_fmt <= 0 )); then class="freezing"; elif (( temp_fmt <= 10 )); then class="cold"; elif (( temp_fmt <= 25 )); then class="moderate"; else class="hot"; fi
    tooltip="${city}\\n${description}\\n\\nTemperature: ${temp_fmt}°C\\nFeels like: ${feels_fmt}°C\\nHumidity: ${humidity}%\\nWind: ${wind_fmt} km/h"
    echo "{\"text\": \"${icon} ${temp_fmt}°C\", \"tooltip\": \"${tooltip}\", \"class\": \"${class}\"}"
}
main
EOF

# btc-ticker.sh
cat << 'EOF' > "$HOME/.config/waybar/scripts/btc-ticker.sh"
#!/bin/bash
data=$(curl -sf 'https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd&include_24hr_change=true')
if [ -z "$data" ]; then echo '{"text": "₿ --", "tooltip": "Unable to fetch price"}'; exit 0; fi
price=$(echo "$data" | jq -r '.bitcoin.usd // empty')
change=$(echo "$data" | jq -r '.bitcoin.usd_24h_change // 0')
if [ -z "$price" ]; then echo '{"text": "₿ --", "tooltip": "Unable to parse price"}'; exit 0; fi
price_fmt=$(printf "%'.0f" "$price")
change_fmt=$(printf "%+.1f" "$change")
if (( $(echo "$change >= 0" | bc -l) )); then class="up"; else class="down"; fi
echo "{\"text\": \"₿ \$${price_fmt}\", \"tooltip\": \"BTC/USD: \$${price}\\n24h: ${change_fmt}%\", \"class\": \"${class}\"}"
EOF

# btc-chart.py
cat << 'EOF' > "$HOME/.config/waybar/scripts/btc-chart.py"
#!/usr/bin/env python3
import json, sys, urllib.request, time
from datetime import datetime
BLOCKS = " ▁▂▃▄▅▆▇█"
RESET, BOLD, DIM, GREEN, RED, CYAN, YELLOW, GRAY, WHITE = "\033[0m", "\033[1m", "\033[2m", "\033[38;5;114m", "\033[38;5;210m", "\033[38;5;117m", "\033[38;5;222m", "\033[38;5;245m", "\033[38;5;255m"
CHART_WIDTH = 60

def fetch_data(days: int):
    try:
        url = f"https://api.coingecko.com/api/v3/coins/bitcoin/market_chart?vs_currency=usd&days={days}"
        with urllib.request.urlopen(url, timeout=10) as r: return json.loads(r.read().decode()).get("prices", [])
    except: return None

def fetch_current():
    try:
        url = "https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd&include_24hr_change=true"
        with urllib.request.urlopen(url, timeout=10) as r:
            d = json.loads(r.read().decode()).get("bitcoin", {})
            return d.get("usd"), d.get("usd_24h_change", 0)
    except: return None

def normalize(prices, width):
    if not prices: return []
    vals = [p[1] for p in prices]
    if len(vals) <= width: return vals
    step = len(vals) / width
    return [vals[int(i * step)] for i in range(width)]

def render(prices, height=8):
    if not prices: return [f"{DIM}  No data available{RESET}"]
    mn, mx = min(prices), max(prices)
    rng = mx - mn if mx - mn != 0 else 1
    lines = []
    col = GREEN if prices[-1] >= prices[0] else RED
    for r in range(height, 0, -1):
        th = mn + (rng * r / height)
        pth = mn + (rng * (r - 1) / height)
        line = ""
        for p in prices:
            if p >= th: line += "█"
            elif p >= pth: line += BLOCKS[int(((p - pth) / (th - pth)) * (len(BLOCKS) - 1))]
            else: line += " "
        lbl = f" ${mx:,.0f}" if r == height else (f" ${mn:,.0f}" if r == 1 else "")
        lines.append(f"{col}{line}{RESET}{GRAY}{lbl}{RESET}")
    return lines

def main():
    print(f"\033[2J\033[H\n  {DIM}Loading Bitcoin data...{RESET}\n")
    curr = fetch_current()
    if not curr: print(f"{RED}Error fetching data{RESET}"); input(); return
    price, change = curr
    daily, weekly, monthly = fetch_data(1), fetch_data(7), fetch_data(30)
    print("\033[2J\033[H")
    print(f"\n{BOLD}{YELLOW}  ₿ BITCOIN{RESET}\n{GRAY}  {'─'*(CHART_WIDTH+8)}{RESET}")
    print(f"  {WHITE}Current: {BOLD}${price:,.0f}{RESET}  {(GREEN if change>=0 else RED)}{change:+.2f}%{RESET}\n")
    for t, p, d in [("Daily", "24h", daily), ("Weekly", "7d", weekly), ("Monthly", "30d", monthly)]:
        print(f"  {BOLD}{CYAN}{t}{RESET} {DIM}({p}){RESET}")
        for l in render(normalize(d, CHART_WIDTH), 6): print(f"  {l}")
        print()
    print(f"{GRAY}  {'─'*(CHART_WIDTH+8)}{RESET}\n  {DIM}Press any key to exit{RESET}")
    try: input()
    except: pass

if __name__ == "__main__": main()
EOF

# thermal-monitor.sh
cat << 'EOF' > "$HOME/.config/waybar/scripts/thermal-monitor.sh"
#!/bin/bash
temp=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null); temp_c=$((temp / 1000))
thinkpad_hwmon=""
for hwmon in /sys/class/hwmon/hwmon*; do
    if [ "$(cat "$hwmon/name" 2>/dev/null)" = "thinkpad" ]; then thinkpad_hwmon="$hwmon"; break; fi
done
if [ -n "$thinkpad_hwmon" ]; then
    fan1=$(cat "$thinkpad_hwmon/fan1_input" 2>/dev/null); fan2=$(cat "$thinkpad_hwmon/fan2_input" 2>/dev/null)
else
    fan1=$(cat /sys/class/hwmon/hwmon*/fan*_input 2>/dev/null | head -1)
fi
fan1=${fan1:-0}; fan2=${fan2:-0}
if [ "$temp_c" -gt 70 ]; then class="hot"; else class="normal"; fi
fan1_fmt=$(printf "%'d" "$fan1"); fan2_fmt=$(printf "%'d" "$fan2")
echo "{\"text\": \"󰔏 ${temp_c}°C\\n󰈐 ${fan1_fmt}\", \"tooltip\": \"CPU: ${temp_c}°C\nFan 1: ${fan1_fmt} RPM\", \"class\": \"$class\"}"
EOF

# network-speed.sh
cat << 'EOF' > "$HOME/.config/waybar/scripts/network-speed.sh"
#!/bin/bash
INTERFACE=$(ip route | awk '/default/ {print $5; exit}')
if [[ -z "$INTERFACE" ]]; then echo '{"text": "󰤮\\n--", "class": "disconnected"}'; exit 0; fi
RX1=$(cat /sys/class/net/$INTERFACE/statistics/rx_bytes); TX1=$(cat /sys/class/net/$INTERFACE/statistics/tx_bytes)
sleep 1
RX2=$(cat /sys/class/net/$INTERFACE/statistics/rx_bytes); TX2=$(cat /sys/class/net/$INTERFACE/statistics/tx_bytes)
RX_SPD=$((RX2 - RX1)); TX_SPD=$((TX2 - TX1))
fmt() { if (($1>=1048576)); then printf "%.1fM" $(echo "$1/1048576"|bc -l); elif (($1>=1024)); then printf "%.0fK" $(echo "$1/1024"|bc); else printf "%dB" $1; fi; }
DOWN=$(fmt $RX_SPD); UP=$(fmt $TX_SPD)
CLASS="idle"; if ((RX_SPD > 102400 || TX_SPD > 102400)); then CLASS="active"; fi
echo "{\"text\": \"⇣${DOWN}\\n⇡${UP}\", \"tooltip\": \"If: $INTERFACE\\nD: $DOWN/s\\nU: $UP/s\", \"class\": \"$CLASS\"}"
EOF

# ram-disk-monitor.sh
cat << 'EOF' > "$HOME/.config/waybar/scripts/ram-disk-monitor.sh"
#!/bin/bash
ram_info=$(free -h | awk '/Mem:/ {gsub(/i/,"",$3); gsub(/i/,"",$2); print $3, $2}')
ram_used=$(echo "$ram_info" | awk '{print $1}'); ram_total=$(echo "$ram_info" | awk '{print $2}')
disk_info=$(df -h / | awk 'NR==2 {print $3, $2}')
disk_used=$(echo "$disk_info" | awk '{print $1}'); disk_total=$(echo "$disk_info" | awk '{print $2}')
echo "{\"text\": \"󰍛 ${ram_used}/${ram_total}\\n󰋊 ${disk_used}/${disk_total}\", \"tooltip\": \"RAM: ${ram_used}/${ram_total}\nDisk: ${disk_used}/${disk_total}\"}"
EOF

# caffeine-indicator.sh
cat << 'EOF' > "$HOME/.config/waybar/scripts/caffeine-indicator.sh"
#!/bin/bash
if pgrep -x "caffeine" >/dev/null; then
    echo '{"text": "󰅶", "tooltip": "Caffeine active", "class": "active"}'
else
    echo '{"text": "󰛊", "tooltip": "Caffeine inactive", "class": ""}'
fi
EOF

# workspaces-monitor.sh
cat << 'EOF' > "$HOME/.config/waybar/scripts/workspaces-monitor.sh"
#!/bin/bash
# You may need to adjust LAPTOP_MONITOR via 'hyprctl monitors'
LAPTOP_MONITOR="eDP-1"
workspaces=$(hyprctl workspaces -j)
active=$(hyprctl activeworkspace -j | jq -r '.id')
out=""
for i in {1..5}; do
    ws=$(echo "$workspaces" | jq -r ".[] | select(.id == $i)")
    mon=$(echo "$ws" | jq -r '.monitor // empty')
    ind=""
    if [ "$mon" = "$LAPTOP_MONITOR" ]; then ind="<sub>•</sub>"; elif [ -n "$mon" ]; then ind="<sup>•</sup>"; fi
    cls="empty"; if [ -n "$ws" ]; then cls="occupied"; fi; if [ "$i" -eq "$active" ]; then cls="active"; fi
    out+="<span class='ws $cls'>${i}${ind}</span>"
done
echo "{\"text\": \"${out}\", \"tooltip\": \"Workspaces\", \"class\": \"workspaces\"}"
socat -U - "UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" | while read -r line; do
    case "$line" in workspace*|focusedmon*) exit 0 ;; esac
done
EOF

# 6. Make scripts executable
chmod +x "$HOME/.config/waybar/scripts/"*

# 7. Reload Waybar
echo ":: Reloading Waybar..."
killall waybar
nohup waybar > /dev/null 2>&1 &

echo ":: Done! Setup complete."
EOF
