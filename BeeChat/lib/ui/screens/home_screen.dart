import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/mesh_network_service.dart';
import '../../core/services/message_storage_service.dart';
import '../../core/services/emergency_service.dart';
import '../../core/di/service_locator.dart';
import '../widgets/conversation_list_item.dart';
import '../widgets/network_status_banner.dart';
import 'chat_screen.dart';
import 'network_status_screen.dart';
import 'emergency_alerts_screen.dart';
import 'settings_screen.dart';

/// Beautiful main screen in Telegram style
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _storageService = getIt<MessageStorageService>();
  int _currentIndex = 0;
  
  @override
  void initState() {
    super.initState();
    _initializeMeshNetwork();
  }

  Future<void> _initializeMeshNetwork() async {
    final meshService = context.read<MeshNetworkService>();
    
    // Initialize with device info
    final deviceId = 'user_${DateTime.now().millisecondsSinceEpoch}';
    const deviceName = 'My Device';
    
    await meshService.initialize(deviceId, deviceName);
    
    // Start scanning and advertising
    await meshService.startScanning();
    await meshService.startAdvertising();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: _buildAppBar(),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavBar(),
      floatingActionButton: _buildFAB(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Crisis Mesh',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      centerTitle: false,
      elevation: 0,
      backgroundColor: Theme.of(context).colorScheme.surface,
      actions: [
        // Search button
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {
            _showSearchDialog();
          },
          tooltip: 'Поиск',
        ),
        // Emergency alerts button with badge
        Consumer<EmergencyService>(
          builder: (context, emergencyService, child) {
            final criticalCount = emergencyService.criticalSignalsCount;
            return Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.warning_amber_rounded),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EmergencyAlertsScreen(),
                      ),
                    );
                  },
                  tooltip: 'Экстренные сигналы',
                ),
                if (criticalCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '$criticalCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildChatsTab();
      case 1:
        return _buildNetworkTab();
      case 2:
        return _buildSettingsTab();
      default:
        return _buildChatsTab();
    }
  }

  Widget _buildChatsTab() {
    return Column(
      children: [
        const NetworkStatusBanner(),
        Expanded(
          child: _buildConversationList(),
        ),
      ],
    );
  }

  Widget _buildNetworkTab() {
    return const NetworkStatusScreen();
  }

  Widget _buildSettingsTab() {
    return const SettingsScreen();
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: 'Чаты',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.wifi_tethering),
            activeIcon: Icon(Icons.wifi_tethering),
            label: 'Сеть',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Настройки',
          ),
        ],
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: _showNewConversationDialog,
      icon: const Icon(Icons.message),
      label: const Text('Новое сообщение'),
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Colors.white,
    );
  }

  Widget _buildConversationList() {
    final conversations = _storageService.getAllConversations();
    
    if (conversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No conversations yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the button below to start messaging',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: conversations.length,
      itemBuilder: (context, index) {
        final conversation = conversations[index];
        return ConversationListItem(
          conversation: conversation,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatScreen(
                  peerId: conversation.peerId,
                  peerName: conversation.peerName,
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showSearchDialog() {
    final meshService = context.read<MeshNetworkService>();
    final peers = meshService.peers;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Поиск устройств'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: 'Введите имя устройства...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (value) {
                  // TODO: Implement search
                },
              ),
              const SizedBox(height: 16),
              if (peers.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.devices_other, size: 48, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Устройства не найдены',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: peers.length,
                    itemBuilder: (context, index) {
                      final peer = peers[index];
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(peer.name[0].toUpperCase()),
                        ),
                        title: Text(peer.name),
                        subtitle: Text(peer.status.name),
                        trailing: Icon(
                          peer.isAvailable ? Icons.circle : Icons.circle_outlined,
                          color: peer.isAvailable ? Colors.green : Colors.grey,
                          size: 12,
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                peerId: peer.id,
                                peerName: peer.name,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  void _showNewConversationDialog() {
    final meshService = context.read<MeshNetworkService>();
    final peers = meshService.peers;

    if (peers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No nearby devices found. Make sure both devices have the app open.'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start Conversation'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: peers.length,
            itemBuilder: (context, index) {
              final peer = peers[index];
              return ListTile(
                leading: CircleAvatar(
                  child: Text(peer.name[0].toUpperCase()),
                ),
                title: Text(peer.name),
                subtitle: Text(peer.status.name),
                trailing: Icon(
                  peer.isAvailable ? Icons.circle : Icons.circle_outlined,
                  color: peer.isAvailable ? Colors.green : Colors.grey,
                  size: 12,
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        peerId: peer.id,
                        peerName: peer.name,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    final meshService = context.read<MeshNetworkService>();
    meshService.stopScanning();
    meshService.stopAdvertising();
    super.dispose();
  }
}
