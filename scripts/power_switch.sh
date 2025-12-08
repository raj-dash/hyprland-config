#!/bin/bash

MONITOR="eDP-2"
PLUGGED_RATE="165"        
BATTERY_RATE="60"          
RESOLUTION="2560x1600"    
BATTERY_STATUS="/sys/class/power_supply/BAT1/status"

# Check if the battery status file reports "Discharging" (on battery)
while true; do
	if [ "$(cat "$BATTERY_STATUS")" == "Discharging" ]; then
	    # Set to low refresh rate (Battery Mode)
	    hyprctl keyword monitor "$MONITOR,$RESOLUTION@$BATTERY_RATE,auto,1"
	    powerprofilesctl set power-saver
	else
	    # Set to high refresh rate (AC Power Mode)
	    hyprctl keyword monitor "$MONITOR,$RESOLUTION@$PLUGGED_RATE,auto,1"
	    powerprofilesctl set balanced
	fi
	sleep 5
done
