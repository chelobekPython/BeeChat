import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:logger/logger.dart';
import '../models/peer.dart';
import '../models/message.dart' as CrisisMessage;

class MeshNetworkService extends ChangeNotifier {
  final Logger _logger = Logger();

  final Map<String, Peer> _peers = {};
  final Map<String, DateTime> _lastPeerUpdate = {};
  bool _isScanning = false;
  bool _isAdvertising = false;
  String? _deviceId;
  String? _deviceName;
  Timer? _simulationTimer;

  Function(CrisisMessage.Message)? onMessageReceived;
  Function(Peer)? onPeerDiscovered;
  Function(String)? onPeerDisconnected;

  List<Peer> get peers => _peers.values.toList();
  List<Peer> get onlinePeers =>
      _peers.values.where((p) => p.status == PeerStatus.online).toList();
  bool get isScanning => _isScanning;
  bool get isAdvertising => _isAdvertising;
  String? get deviceId => _deviceId;
  String? get deviceName => _deviceName;

  Future<void> initialize(String deviceId, String deviceName) async {
    _deviceId = deviceId;
    _deviceName = deviceName;
  }

  /// Update device name
  void updateDeviceName(String newName) {
    _deviceName = newName;
    notifyListeners();
  }

  Future<void> startScanning() async {
    if (_isScanning) return;

    _isScanning = true;
    notifyListeners();

    // On web, always use simulation mode
    if (kIsWeb) {
      _logger.i('Web platform detected, starting simulation mode');
      _startSimulationMode();
      return;
    }

    final hasPermissions = await _requestPermissions();
    if (!hasPermissions) {
      _logger.w('Required permissions not granted, no peers will be discovered');
      return;
    }

    await _startRealPeerDiscovery();
  }

  Future<void> stopScanning() async {
    _isScanning = false;
    notifyListeners();
  }

  Future<void> startAdvertising() async {
    if (_isAdvertising) return;

    _isAdvertising = true;
    notifyListeners();

    // On web, skip advertising
    if (kIsWeb) {
      _logger.i('Web platform detected, advertising not available');
      return;
    }

    final hasPermissions = await _requestPermissions();
    if (!hasPermissions) {
      _logger.w('Required permissions not granted for advertising, simulation mode active');
      return;
    }

    await _startRealAdvertising();
  }

  Future<void> stopAdvertising() async {
    _isAdvertising = false;
    notifyListeners();
  }

  /// Start simulation mode when real discovery is not available
  void _startSimulationMode() {
    _logger.i('Starting simulation mode for peer discovery');

    // Add some simulated peers immediately
    _addSimulatedPeer('peer_1', 'Александр', 'Android');
    _addSimulatedPeer('peer_2', 'Мария', 'iPhone');
    _addSimulatedPeer('peer_3', 'Дмитрий', 'Android');

    // Continue adding peers periodically
    _simulationTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (!_isScanning) {
        timer.cancel();
        return;
      }

      final names = ['Елена', 'Сергей', 'Анна', 'Михаил', 'Ольга', 'Николай'];
      final devices = ['Android', 'iPhone', 'Windows', 'Mac'];
      final randomName = names[DateTime.now().millisecond % names.length];
      final randomDevice = devices[DateTime.now().second % devices.length];

      _addSimulatedPeer(
        'peer_${DateTime.now().millisecondsSinceEpoch}',
        randomName,
        randomDevice,
      );
    });
  }

  void _addSimulatedPeer(String id, String name, String deviceType) {
    if (_peers.containsKey(id)) return;

    final peer = Peer(
      id: id,
      name: name,
      deviceType: deviceType,
      lastSeen: DateTime.now(),
      status: PeerStatus.nearby,
      signalStrength: -50 - (DateTime.now().millisecond % 40),
    );

    updatePeer(peer);
    _logger.i('Simulated peer discovered: $name ($deviceType)');
  }

  Future<void> _startRealPeerDiscovery() async {
    try {
      final deviceName = _deviceName ?? 'Unknown Device';

      // On Windows, location permissions are not required for Bluetooth
      if (!Platform.isWindows) {
        // Double-check location permission before starting discovery
        final locationStatus = await Permission.location.status;
        final fineLocationStatus = await Permission.locationWhenInUse.status;
        _logger.i('Location permission status before discovery: $locationStatus');
        _logger.i('Fine location permission status before discovery: $fineLocationStatus');

        if (!locationStatus.isGranted && !fineLocationStatus.isGranted) {
          _logger.e('Location permission not granted before starting discovery');
          // Instead of starting simulation mode, just log the error and return
          _logger.e('Real discovery requires location permissions. No peers will be discovered.');
          return;
        }
      } else {
        _logger.i('Windows platform detected, skipping location permission check');
      }

      // Add additional delay to ensure permissions are fully processed by the system
      await Future.delayed(const Duration(milliseconds: 1000));
      _logger.i('Starting peer discovery after permission verification...');

      await Nearby().startDiscovery(
        deviceName,
        Strategy.P2P_CLUSTER,
        onEndpointFound: (id, name, serviceId) {
          final peer = Peer(
            id: id,
            name: name,
            deviceType: 'Android',
            lastSeen: DateTime.now(),
            status: PeerStatus.nearby,
            signalStrength: -60,
          );

          updatePeer(peer);
          _logger.i('Real peer discovered: $name');
        },
        onEndpointLost: (id) {
          _peers.remove(id);
          _lastPeerUpdate.remove(id);
          if (id != null) {
            onPeerDisconnected?.call(id);
          }
          notifyListeners();
        },
      );
    } catch (e) {
      _logger.e('Discovery error: $e');

      // Check if it's a permission error
      if (e.toString().contains('MISSING_PERMISSION') ||
          e.toString().contains('8034')) {
        _logger.e('Permission error detected. Real discovery requires location permissions.');
        _logger.e('To enable real discovery:');
        _logger.e('1. Grant location permission in Settings');
        _logger.e('2. Enable Bluetooth');
        _logger.e('3. Restart the app');
      }

      // Instead of starting simulation mode, just log the error and return
      _logger.e('Real discovery failed. No peers will be discovered.');
    }
  }

  Future<void> _startRealAdvertising() async {
    try {
      final deviceName = _deviceName ?? 'Unknown Device';

      // On Windows, location permissions are not required for Bluetooth
      if (!Platform.isWindows) {
        // Double-check location permission before starting advertising
        final locationStatus = await Permission.location.status;
        final fineLocationStatus = await Permission.locationWhenInUse.status;
        _logger.i('Location permission status before advertising: $locationStatus');
        _logger.i('Fine location permission status before advertising: $fineLocationStatus');

        if (!locationStatus.isGranted && !fineLocationStatus.isGranted) {
          _logger.e('Location permission not granted before starting advertising');
          return;
        }
      } else {
        _logger.i('Windows platform detected, skipping location permission check');
      }

      // Add additional delay to ensure permissions are fully processed by the system
      await Future.delayed(const Duration(milliseconds: 1000));
      _logger.i('Starting advertising after permission verification...');

      await Nearby().startAdvertising(
        deviceName,
        Strategy.P2P_CLUSTER,
        onConnectionInitiated: (id, info) {
          Nearby().acceptConnection(
            id,
            onPayLoadRecieved: (endpointId, payload) {},
            onPayloadTransferUpdate: (endpointId, update) {},
          );
        },
        onConnectionResult: (id, status) {
          if (status == 0) {
            final peer = _peers[id];
            if (peer != null) {
              updatePeer(peer.copyWith(status: PeerStatus.online));
            }
          }
        },
        onDisconnected: (id) {
          final peer = _peers[id];
          if (peer != null) {
            updatePeer(peer.copyWith(status: PeerStatus.nearby));
          }
        },
      );
    } catch (e) {
      _logger.e('Advertising error: $e');

      // Check if it's a permission error
      if (e.toString().contains('MISSING_PERMISSION') ||
          e.toString().contains('8034')) {
        _logger.e('Permission error detected for advertising.');
        _logger.e('To enable real advertising:');
        _logger.e('1. Grant location permission in Settings');
        _logger.e('2. Enable Bluetooth');
        _logger.e('3. Restart the app');
      }
    }
  }

  void updatePeer(Peer peer) {
    _peers[peer.id] = peer;
    _lastPeerUpdate[peer.id] = DateTime.now();
    notifyListeners();
  }

  /// Connect to a specific peer
  Future<bool> connectToPeer(String peerId) async {
    final peer = _peers[peerId];
    if (peer == null) {
      return false;
    }

    updatePeer(peer.copyWith(status: PeerStatus.connecting));

    // Simulate connection
    await Future.delayed(const Duration(seconds: 1));
    updatePeer(peer.copyWith(status: PeerStatus.online));

    return true;
  }

  /// Disconnect from a peer
  Future<void> disconnectFromPeer(String peerId) async {
    final peer = _peers[peerId];
    if (peer != null) {
      updatePeer(peer.copyWith(status: PeerStatus.offline));
    }
  }

  /// Send a message through the mesh network
  Future<bool> sendMessage(CrisisMessage.Message message) async {
    final recipient = _peers[message.recipientId];
    if (recipient?.status == PeerStatus.online) {
      return await _sendDirectMessage(message, recipient!);
    }

    return await _broadcastMessage(message);
  }

  /// Send message directly to a connected peer
  Future<bool> _sendDirectMessage(CrisisMessage.Message message, Peer peer) async {
    try {
      // Simulate sending
      await Future.delayed(const Duration(milliseconds: 100));
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Broadcast message to all connected peers (epidemic routing)
  Future<bool> _broadcastMessage(CrisisMessage.Message message) async {
    if (!message.canForward) {
      return false;
    }

    final deviceId = _deviceId;
    if (deviceId == null) {
      return false;
    }

    final onlinePeersList = onlinePeers;
    if (onlinePeersList.isEmpty) {
      return false;
    }

    int successCount = 0;
    for (final peer in onlinePeersList) {
      final forwarded = message.incrementHop(deviceId);
      if (await _sendDirectMessage(forwarded, peer)) {
        successCount++;
      }
    }

    return successCount > 0;
  }

  /// Handle received message
  void handleReceivedMessage(CrisisMessage.Message message) {
    if (message.recipientId == _deviceId) {
      onMessageReceived?.call(message);
      return;
    }

    if (message.canForward) {
      _broadcastMessage(message);
    }
  }

  Future<bool> _requestPermissions() async {
    _logger.i('Requesting permissions for mesh networking...');

    // On web, skip permission requests
    if (kIsWeb) {
      _logger.i('Web platform detected, skipping permission request');
      return false;
    }

    // On Windows, location permissions are not required for Bluetooth
    if (Platform.isWindows) {
      _logger.i('Windows platform detected, skipping location permission request');
      // Only request Bluetooth permissions on Windows
      final bluetoothStatus = await Permission.bluetooth.request();
      final bluetoothConnectStatus = await Permission.bluetoothConnect.request();
      final bluetoothScanStatus = await Permission.bluetoothScan.request();
      final bluetoothAdvertiseStatus = await Permission.bluetoothAdvertise.request();

      _logger.i('Bluetooth permission status: $bluetoothStatus');
      _logger.i('Bluetooth Connect permission status: $bluetoothConnectStatus');
      _logger.i('Bluetooth Scan permission status: $bluetoothScanStatus');
      _logger.i('Bluetooth Advertise permission status: $bluetoothAdvertiseStatus');

      final allGranted = bluetoothStatus.isGranted &&
          bluetoothConnectStatus.isGranted &&
          bluetoothScanStatus.isGranted &&
          bluetoothAdvertiseStatus.isGranted;

      if (!allGranted) {
        _logger.w('Some Bluetooth permissions were not granted:');
        if (!bluetoothStatus.isGranted) _logger.w('  - Bluetooth: ${bluetoothStatus}');
        if (!bluetoothConnectStatus.isGranted) _logger.w('  - Bluetooth Connect: ${bluetoothConnectStatus}');
        if (!bluetoothScanStatus.isGranted) _logger.w('  - Bluetooth Scan: ${bluetoothScanStatus}');
        if (!bluetoothAdvertiseStatus.isGranted) _logger.w('  - Bluetooth Advertise: ${bluetoothAdvertiseStatus}');
      } else {
        _logger.i('All Bluetooth permissions granted successfully');
      }

      return allGranted;
    }

    // On Android, request location permissions
    // Check current permission status first
    final currentLocationStatus = await Permission.location.status;
    final currentFineLocationStatus = await Permission.locationWhenInUse.status;
    _logger.i('Current location permission status: $currentLocationStatus');
    _logger.i('Current fine location permission status: $currentFineLocationStatus');

    // Request both coarse and fine location permissions (required for Bluetooth scanning on Android)
    final locationStatus = await Permission.location.request();
    final fineLocationStatus = await Permission.locationWhenInUse.request();
    _logger.i('Location permission status after request: $locationStatus');
    _logger.i('Fine location permission status after request: $fineLocationStatus');

    // Check if at least one location permission is granted
    final hasLocationPermission = locationStatus.isGranted || fineLocationStatus.isGranted;

    if (!hasLocationPermission) {
      _logger.e('Location permission is required for Bluetooth discovery');
      if (locationStatus.isPermanentlyDenied || fineLocationStatus.isPermanentlyDenied) {
        _logger.e('Location permission permanently denied. Please enable in Settings.');
      }
      return false;
    }

    // Request Bluetooth permissions
    final bluetoothStatus = await Permission.bluetooth.request();
    final bluetoothConnectStatus = await Permission.bluetoothConnect.request();
    final bluetoothScanStatus = await Permission.bluetoothScan.request();
    final bluetoothAdvertiseStatus = await Permission.bluetoothAdvertise.request();

    _logger.i('Bluetooth permission status: $bluetoothStatus');
    _logger.i('Bluetooth Connect permission status: $bluetoothConnectStatus');
    _logger.i('Bluetooth Scan permission status: $bluetoothScanStatus');
    _logger.i('Bluetooth Advertise permission status: $bluetoothAdvertiseStatus');

    // Request Nearby WiFi Devices permission for Android 13+
    final nearbyWifiStatus = await Permission.nearbyWifiDevices.request();
    _logger.i('Nearby WiFi Devices permission status: $nearbyWifiStatus');

    // Check if all required permissions are granted
    final allGranted = hasLocationPermission &&
        bluetoothStatus.isGranted &&
        bluetoothConnectStatus.isGranted &&
        bluetoothScanStatus.isGranted &&
        bluetoothAdvertiseStatus.isGranted &&
        nearbyWifiStatus.isGranted;

    if (!allGranted) {
      _logger.w('Some permissions were not granted:');
      if (!hasLocationPermission) _logger.w('  - Location: ${locationStatus} / ${fineLocationStatus}');
      if (!bluetoothStatus.isGranted) _logger.w('  - Bluetooth: ${bluetoothStatus}');
      if (!bluetoothConnectStatus.isGranted) _logger.w('  - Bluetooth Connect: ${bluetoothConnectStatus}');
      if (!bluetoothScanStatus.isGranted) _logger.w('  - Bluetooth Scan: ${bluetoothScanStatus}');
      if (!bluetoothAdvertiseStatus.isGranted) _logger.w('  - Bluetooth Advertise: ${bluetoothAdvertiseStatus}');
      if (!nearbyWifiStatus.isGranted) _logger.w('  - Nearby WiFi: ${nearbyWifiStatus}');

      // Check for permanently denied permissions
      if (locationStatus.isPermanentlyDenied ||
          fineLocationStatus.isPermanentlyDenied ||
          bluetoothStatus.isPermanentlyDenied ||
          bluetoothConnectStatus.isPermanentlyDenied ||
          bluetoothScanStatus.isPermanentlyDenied ||
          bluetoothAdvertiseStatus.isPermanentlyDenied ||
          nearbyWifiStatus.isPermanentlyDenied) {
        _logger.e('Some permissions are permanently denied. Please enable them in Settings.');
      }
    } else {
      _logger.i('All permissions granted successfully');
      // Add a small delay to ensure permissions are fully processed by the system
      await Future.delayed(const Duration(milliseconds: 500));
      _logger.i('Permissions fully processed, ready for Bluetooth operations');
    }

    return allGranted;
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
    stopScanning();
    stopAdvertising();
    super.dispose();
  }
}