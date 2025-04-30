# Connecting to WiFi from the Command Line

There are two ways to connect to WiFi from the minimal NixOS installer:

## Method 1: Using NetworkManager (Recommended)

```bash
# List available WiFi networks
nmcli device wifi list

# Connect to a WiFi network
nmcli device wifi connect "YOUR_SSID" password "YOUR_PASSWORD"

# Verify connection
ip addr
ping -c 3 google.com
```

## Method 2: Using wpa_supplicant directly

```bash
# Generate a hashed password for your network
wpa_passphrase "YOUR_SSID" "YOUR_PASSWORD" > /tmp/wpa_supplicant.conf

# Find your wireless interface
ip a

# Connect to WiFi (replace wlan0 with your interface name)
wpa_supplicant -B -i wlan0 -c /tmp/wpa_supplicant.conf
dhclient wlan0

# Verify connection
ip addr
ping -c 3 google.com
```

## Troubleshooting WiFi Issues

### 1. Check WiFi Hardware

```bash
# Check if your WiFi adapter is recognized
ip a
iw dev

# Check for detected WiFi networks
iw dev wlan0 scan | grep SSID
```

### 2. Debug Network Issues

```bash
# Check network status
ip link
systemctl status wpa_supplicant
systemctl status NetworkManager

# Check if you're getting an IP address
ip addr show wlan0
```

### 3. Manual IP Configuration

If DHCP isn't working, you can configure IP manually:

```bash
ip addr add 192.168.1.100/24 dev wlan0
ip route add default via 192.168.1.1
echo "nameserver 8.8.8.8" > /etc/resolv.conf
```

### 4. Try Restarting NetworkManager

```bash
systemctl restart NetworkManager
```

## After Connection

Once connected, you can proceed with the installation:

```bash
# Clone your repository
git clone https://github.com/yourusername/ask-nixos.git

# Or if you're using a local USB drive for installation
mount /dev/sdX1 /mnt/usb
cp -r /mnt/usb/ask-nixos /tmp/
``` 