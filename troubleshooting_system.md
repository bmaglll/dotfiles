# System Troubleshooting

Common issues and fixes for this NixOS/Framework 13 setup.

## Touchpad Unresponsive (After Wiping/Cleaning)

**Symptoms:** Touchpad stops responding after cleaning keyboard/touchpad surface. Device still shows in `hyprctl devices` and `/proc/bus/input/devices`.

**Cause:** Moisture or static discharge disrupts the I2C-HID communication, putting the touchpad in a bad state. The kernel driver doesn't auto-recover because the device appears connected.

**Fix (requires sudo):**
```bash
# Unbind and rebind the HID driver
echo "0018:093A:0274.0002" | sudo tee /sys/bus/hid/drivers/hid-multitouch/unbind
echo "0018:093A:0274.0002" | sudo tee /sys/bus/hid/drivers/hid-multitouch/bind
```

**Alternative fix:** Suspend and resume the laptop (`systemctl suspend`), which resets the I2C bus.

**Note:** The device ID `0018:093A:0274.0002` is specific to this Framework 13's Pixart touchpad. If it changes after a kernel update, find the current ID with:
```bash
ls /sys/bus/hid/drivers/hid-multitouch/
```

**Quick alias** (add to shell config for convenience):
```bash
alias fix-touchpad='echo "0018:093A:0274.0002" | sudo tee /sys/bus/hid/drivers/hid-multitouch/unbind && echo "0018:093A:0274.0002" | sudo tee /sys/bus/hid/drivers/hid-multitouch/bind'
```
