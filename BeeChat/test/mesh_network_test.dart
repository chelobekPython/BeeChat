import 'package:flutter_test/flutter_test.dart';
import 'package:crisis_mesh/core/services/mesh_network_service.dart';
import 'package:crisis_mesh/core/models/peer.dart';
import 'package:crisis_mesh/core/models/message.dart';

void main() {
  late MeshNetworkService meshService;
  late List<Peer> discoveredPeers;
  late List<Message> receivedMessages;

  setUp(() {
    meshService = MeshNetworkService();
    discoveredPeers = [];
    receivedMessages = [];
    
    // Set up callbacks
    meshService.onPeerDiscovered = (peer) {
      discoveredPeers.add(peer);
    };
    
    meshService.onMessageReceived = (message) {
      receivedMessages.add(message);
    };
  });

  tearDown(() {
    meshService.dispose();
  });

  test('Mesh network service initialization', () {
    expect(meshService.peers, isEmpty);
    expect(meshService.isScanning, isFalse);
    expect(meshService.isAdvertising, isFalse);
  });

  test('Peer discovery and management', () async {
    // Initialize service
    await meshService.initialize('test-device-1', 'Test Device 1');
    
    // Create a test peer
    final testPeer = Peer(
      id: 'test-peer-1',
      name: 'Test Peer 1',
      deviceType: 'Android',
      lastSeen: DateTime.now(),
      status: PeerStatus.nearby,
      signalStrength: -60,
    );

    // Simulate peer discovery
    meshService.updatePeer(testPeer);

    // Verify peer was added
    expect(meshService.peers, hasLength(1));
    expect(meshService.peers.first.id, 'test-peer-1');
    expect(meshService.peers.first.name, 'Test Peer 1');
    expect(discoveredPeers, hasLength(1));
  });

  test('Message routing and forwarding', () async {
    // Initialize service
    await meshService.initialize('test-device-1', 'Test Device 1');
    
    // Create test peers
    final peer1 = Peer(
      id: 'peer-1',
      name: 'Peer 1',
      deviceType: 'Android',
      lastSeen: DateTime.now(),
      status: PeerStatus.online,
      signalStrength: -60,
    );

    final peer2 = Peer(
      id: 'peer-2',
      name: 'Peer 2',
      deviceType: 'iOS',
      lastSeen: DateTime.now(),
      status: PeerStatus.online,
      signalStrength: -70,
    );

    // Add peers to the network
    meshService.updatePeer(peer1);
    meshService.updatePeer(peer2);

    // Create a test message
    final testMessage = Message(
      id: 'msg-1',
      senderId: 'test-device-1',
      recipientId: 'peer-1',
      content: 'Hello, this is a test message!',
      timestamp: DateTime.now(),
      hopCount: 0,
      maxHops: 5,
    );

    // Test message sending
    final result = await meshService.sendMessage(testMessage);
    
    // Should succeed since peer-1 is online
    expect(result, isTrue);
  });

  test('Epidemic routing with multiple hops', () async {
    // Initialize service
    await meshService.initialize('test-device-1', 'Test Device 1');
    
    // Create test peers
    final peer1 = Peer(
      id: 'peer-1',
      name: 'Peer 1',
      deviceType: 'Android',
      lastSeen: DateTime.now(),
      status: PeerStatus.online,
      signalStrength: -60,
    );

    final peer2 = Peer(
      id: 'peer-2',
      name: 'Peer 2',
      deviceType: 'iOS',
      lastSeen: DateTime.now(),
      status: PeerStatus.online,
      signalStrength: -70,
    );

    // Add peers to the network
    meshService.updatePeer(peer1);
    meshService.updatePeer(peer2);

    // Create a message that should be forwarded
    final testMessage = Message(
      id: 'msg-2',
      senderId: 'test-device-1',
      recipientId: 'non-existent-peer',
      content: 'This message should be forwarded',
      timestamp: DateTime.now(),
      hopCount: 0,
      maxHops: 5,
    );

    // Test message forwarding
    final result = await meshService.sendMessage(testMessage);
    
    // Should succeed since message will be forwarded to connected peers
    expect(result, isTrue);
  });

  test('Peer status management', () async {
    // Initialize service
    await meshService.initialize('test-device-1', 'Test Device 1');
    
    // Create a test peer
    var testPeer = Peer(
      id: 'test-peer-1',
      name: 'Test Peer 1',
      deviceType: 'Android',
      lastSeen: DateTime.now(),
      status: PeerStatus.nearby,
      signalStrength: -60,
    );

    // Add peer
    meshService.updatePeer(testPeer);
    expect(meshService.peers.first.status, PeerStatus.nearby);

    // Update peer status to online
    testPeer = testPeer.copyWith(status: PeerStatus.online);
    meshService.updatePeer(testPeer);
    expect(meshService.peers.first.status, PeerStatus.online);

    // Update peer status to offline
    testPeer = testPeer.copyWith(status: PeerStatus.offline);
    meshService.updatePeer(testPeer);
    expect(meshService.peers.first.status, PeerStatus.offline);
  });

  test('Message handling for local recipient', () async {
    // Initialize service
    await meshService.initialize('test-device-1', 'Test Device 1');
    
    // Create a message for this device
    final testMessage = Message(
      id: 'msg-local',
      senderId: 'peer-1',
      recipientId: 'test-device-1',
      content: 'This message is for me!',
      timestamp: DateTime.now(),
      hopCount: 0,
      maxHops: 5,
    );

    // Handle received message
    meshService.handleReceivedMessage(testMessage);
    
    // Should trigger onMessageReceived callback
    expect(receivedMessages, hasLength(1));
    expect(receivedMessages.first.id, 'msg-local');
    expect(receivedMessages.first.content, 'This message is for me!');
  });

  test('Message dropping at max hops', () async {
    // Initialize service
    await meshService.initialize('test-device-1', 'Test Device 1');
    
    // Create a message that has reached max hops
    final testMessage = Message(
      id: 'msg-max-hops',
      senderId: 'peer-1',
      recipientId: 'peer-2',
      content: 'This message has reached max hops',
      timestamp: DateTime.now(),
      hopCount: 5,
      maxHops: 5,
    );

    // Handle received message
    meshService.handleReceivedMessage(testMessage);
    
    // Should not trigger onMessageReceived callback since it's not for us
    // and should not be forwarded (max hops reached)
    expect(receivedMessages, isEmpty);
  });
}