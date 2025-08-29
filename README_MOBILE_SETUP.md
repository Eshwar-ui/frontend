# Mobile Setup Instructions

## Login Issue on Mobile Devices

If you're experiencing login issues when running the app on a physical mobile device (while it works fine in Chrome as a web application), it's likely due to the network configuration.

## Why This Happens

When running as a web application in Chrome, the app connects to `localhost:5000` which works correctly. However, on a mobile device, `localhost` refers to the device itself, not your development machine where the backend server is running.

## Solution

You need to configure the app to use your development machine's actual IP address when running on a physical device.

### Step 1: Find Your Development Machine's IP Address

#### On Windows:
1. Open Command Prompt
2. Type `ipconfig` and press Enter
3. Look for the IPv4 Address under your active network connection (usually Wi-Fi or Ethernet)

#### On macOS:
1. Open System Preferences > Network
2. Select your active connection and look for the IP Address

### Step 2: Update the Network Configuration

Open the file `lib/utils/network_config.dart` and update the `_devMachineIp` variable with your actual IP address:

```dart
// Change this to your actual IP address when testing on physical devices
static const String _devMachineIp = '192.168.1.100'; // CHANGE THIS TO YOUR ACTUAL IP
```

Replace `192.168.1.100` with your development machine's IP address.

### Step 3: Important Requirements

1. **Same Network**: Your mobile device and development machine MUST be on the same network (e.g., connected to the same Wi-Fi).

2. **Firewall Settings**: Make sure your development machine's firewall allows incoming connections on port 5000 (or whatever port your backend server is using).

3. **Backend Server**: Ensure your backend server is running before attempting to log in from the mobile device.

## Testing

After making these changes:

1. Stop the app if it's running
2. Run `flutter clean` (optional but recommended)
3. Run `flutter pub get`
4. Rebuild and run the app on your physical device

You should now be able to log in successfully from your mobile device.

## Troubleshooting

If you're still experiencing issues:

1. **Check Network Connection**: Ensure both devices are on the same network

2. **Test Backend Accessibility**: From your mobile device's browser, try accessing `http://YOUR_IP_ADDRESS:5000` (replace with your actual IP). If you can't access it, there might be network/firewall issues.

3. **Debug Network Calls**: Check the console logs for network errors. The app prints response status and body information which can help diagnose issues.

4. **Temporary Solution**: If you can't resolve network issues, consider using a tool like ngrok to expose your local server to the internet temporarily for testing.