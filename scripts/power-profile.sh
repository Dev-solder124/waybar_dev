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
