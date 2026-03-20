# Mesh Network Implementation Guide

## Overview

This document describes the implementation of the mesh networking system for the Crisis Mesh Messenger application. The system enables infrastructure-free communication between devices in crisis situations where traditional networks may be unavailable.

## Architecture

### Core Components

1. **MeshNetworkService** - Main service managing peer discovery, connections, and message routing
2. **Peer** - Represents a discovered device in the mesh network
3. **Message** - Encrypted message with epidemic routing support
4. **Nearby Connections API** - Android platform-specific implementation

### Key Features

- **Peer Discovery**: Automatic discovery of nearby devices using Bluetooth and WiFi Direct
- **Epidemic Routing**: Messages are forwarded through the network until they reach their destination
- **Hop Limiting**: Messages have a maximum number of hops to prevent infinite loops
- **Connection Management**: Automatic connection establishment and maintenance
- **Permission Handling**: Runtime permission requests for Bluetooth and location access

## Implementation Details

### Peer Discovery

The system uses Google's Nearby Connections API for Android:

```dart
await NearbyConnections.Nearby().startDiscovery(
  deviceName,
  NearbyConnections.Strategy.P2P_CLUSTER,
  onEndpointFound: (id, name, serviceId) {
    // Handle discovered peer
  },
  onEndpointLost: (id) {
    // Handle lost peer
  },
);
```

### Advertising

Devices advertise themselves to be discoverable by others:

```dart
await NearbyConnections.Nearby().startAdvertising(
  deviceName,
  NearbyConnections.Strategy.P2P_CLUSTER,
  onConnectionInitiated: (id, connectionInfo) {
    // Accept connection automatically
  },
  // ... other callbacks
);
```

### Message Routing

The system implements epidemic routing where messages are forwarded to all connected peers:

1. Check if recipient is directly connected
2. If not, forward to all online peers with incremented hop count
3. Each peer repeats the process until message reaches destination or max hops

### Security Features

- **Encryption**: All messages are encrypted using AES-256
- **Authentication**: Device authentication using public key cryptography
- **Hop Limiting**: Prevents message loops with configurable max hops
- **Permission Control**: Runtime permissions for network access

## Usage

### Initialization

```dart
final meshService = MeshNetworkService();
await meshService.initialize('device-123', 'User Device');
```

### Starting Discovery

```dart
// Start scanning for nearby peers
await meshService.startScanning();

// Start advertising this device
await meshService.startAdvertising();
```

### Sending Messages

```dart
final message = Message(
  id: 'msg-1',
  senderId: 'device-123',
  recipientId: 'target-device',
  content: 'Hello from mesh network!',
  timestamp: DateTime.now(),
  hops: 0,
  maxHops: 5,
);

final success = await meshService.sendMessage(message);
```

### Receiving Messages

```dart
meshService.onMessageReceived = (message) {
  print('Received: ${message.content}');
  print('From: ${message.senderId}');
};
```

### Monitoring Peers

```dart
meshService.onPeerDiscovered = (peer) {
  print('New peer: ${peer.name}');
};

meshService.onPeerDisconnected = (peerId) {
  print('Peer disconnected: $peerId');
};
```

## Platform Support

### Android

- **Primary Implementation**: Uses Nearby Connections API
- **Permissions Required**:
  - `BLUETOOTH`
  - `BLUETOOTH_ADMIN`
  - `BLUETOOTH_ADVERTISE`
  - `BLUETOOTH_CONNECT`
  - `BLUETOOTH_SCAN`
  - `ACCESS_FINE_LOCATION`
  - `ACCESS_COARSE_LOCATION`

### iOS (Future Implementation)

- **Planned**: Multipeer Connectivity Framework
- **Similar API**: Will provide equivalent functionality

## Configuration

### Android Manifest

Ensure the following permissions are added to `android/app/src/main/AndroidManifest.xml`:

```xml
<!-- Bluetooth permissions for mesh networking -->
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.BLUETOOTH_ADVERTISE" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />

<!-- WiFi Direct permissions -->
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
<uses-permission android:name="android.permission.CHANGE_WIFI_STATE" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />

<!-- Internet permission for network operations -->
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />

<!-- Vibration for notifications -->
<uses-permission android:name="android.permission.VIBRATE" />
```

### Dependencies

Add to `pubspec.yaml`:

```yaml
dependencies:
  flutter_nearby_connections: ^1.1.2
  nearby_connections: ^3.1.0
  permission_handler: ^11.3.1
```

## Testing

### Unit Tests

Run the mesh network tests:

```bash
flutter test test/mesh_network_test.dart
```

### Integration Testing

1. Build the app on two Android devices
2. Install on both devices
3. Open the app and navigate to Network Status screen
4. Verify peer discovery works
5. Test message sending between devices

## Troubleshooting

### Common Issues

1. **Permission Denied**: Ensure all required permissions are granted
2. **No Peers Found**: Check Bluetooth and WiFi are enabled on both devices
3. **Connection Failed**: Verify devices are within range (typically 10-100 meters)
4. **Messages Not Delivered**: Check hop count and network connectivity

### Debug Logging

Enable debug logging to troubleshoot issues:

```dart
final logger = Logger(
  printer: PrettyPrinter(),
);
```

## Performance Considerations

### Battery Usage

- Discovery and advertising consume battery
- Use appropriate intervals for scanning
- Consider power-saving modes in low-battery situations

### Network Efficiency

- Epidemic routing can generate network traffic
- Configure appropriate hop limits
- Implement message deduplication

### Memory Usage

- Peers are stored in memory with cleanup
- Old peers are automatically removed after 5 minutes
- Monitor memory usage on low-end devices

## Future Enhancements

1. **iOS Support**: Implement Multipeer Connectivity
2. **WiFi Direct**: Enhanced WiFi Direct support
3. **Mesh Optimization**: Advanced routing algorithms
4. **QoS Support**: Quality of service for different message types
5. **Network Analytics**: Performance monitoring and reporting

## Security Considerations

1. **Encryption**: Always use encrypted communication
2. **Authentication**: Verify peer identities
3. **Rate Limiting**: Prevent network flooding
4. **Privacy**: Minimize data collection and storage
5. **Secure Storage**: Protect encryption keys and credentials

## Conclusion

This mesh networking implementation provides a robust foundation for infrastructure-free communication in crisis situations. The system is designed to be reliable, secure, and easy to use while maintaining compatibility with standard Android networking practices.