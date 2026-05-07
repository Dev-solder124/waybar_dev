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
