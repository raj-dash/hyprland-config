#!/bin/bash
# Script: power_switch_gpu.sh
# Location: ~/bin/power_switch_gpu.sh

# --- CONFIGURE THIS VALUE ---
# Replace with the PCI bus address you found in Step 2.
NVIDIA_PCI_ID="01:00.0" 
# ----------------------------

# Path to the directory where the driver is bound
NVIDIA_PATH="/sys/bus/pci/devices/$NVIDIA_PCI_ID"

# The location of the AC power status
AC_POWER_STATUS="/sys/class/power_supply/ACAD/online"

# Function to turn off the dGPU (unbind/remove from PCI)
turn_off_dgpu() {
    echo "Disabling NVIDIA dGPU ($NVIDIA_PCI_ID) for power saving."
    # 1. First, tell the kernel to remove the device (put into D3cold state)
    echo 1 | sudo tee "$NVIDIA_PATH/remove" > /dev/null
    
    # 2. As a fallback, try to unbind if the remove command failed/didn't work fully
    # Get the driver name (usually 'nvidia')
    DRIVER_PATH="$NVIDIA_PATH/driver"
    if [ -d "$DRIVER_PATH" ]; then
        DRIVER_NAME=$(basename "$(realpath "$DRIVER_PATH")")
        echo "$NVIDIA_PCI_ID" | sudo tee "$DRIVER_PATH/unbind" > /dev/null
        
        # 3. Final method: Force D3cold state directly
        echo 'auto' | sudo tee "$NVIDIA_PATH/power/control" > /dev/null
        echo "Successfully unbound and set power to auto."
    fi
}

# Function to turn on the dGPU (re-scan the PCI bus)
turn_on_dgpu() {
    echo "Enabling NVIDIA dGPU ($NVIDIA_PCI_ID) as AC power is connected."
    # This command tells the kernel to rescan the PCI bus and re-add the device
    echo 1 | sudo tee /sys/bus/pci/rescan > /dev/null
    
    # You may also need to explicitly bind the device if rescan doesn't work perfectly
    # echo "$NVIDIA_PCI_ID" | sudo tee "$NVIDIA_PATH/driver/bind" > /dev/null
    
    # Optional: Stop and restart the power daemon for stability
    sudo systemctl restart nvidia-powerd.service 2>/dev/null
    
    echo "NVIDIA dGPU should now be available for prime-run applications."
}

# --- MAIN LOGIC ---

if [ -f "$AC_POWER_STATUS" ]; then
    AC_STATUS=$(cat "$AC_POWER_STATUS")
    
    if [ "$AC_STATUS" -eq 0 ]; then
        # On Battery
        turn_off_dgpu
    elif [ "$AC_STATUS" -eq 1 ]; then
        # On AC Power
        turn_on_dgpu
    fi
else
    echo "Error: Could not find AC power status file. Check your system's power supply naming."
fi
