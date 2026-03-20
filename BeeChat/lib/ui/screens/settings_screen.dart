import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/mesh_network_service.dart';
import '../../core/services/emergency_service.dart';
import 'network_status_screen.dart';
import '../../core/providers/liquid_glass_provider.dart';

/// Beautiful settings screen in Telegram style
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
bool _darkMode = false;
bool _notifications = true;
bool _vibration = true;
bool _autoConnect = true;
bool _showOnlineStatus = true;
bool _encryptMessages = true;
bool _liquidGlass = true;
String _language = 'Русский';
String _connectionStrategy = 'P2P Cluster';
final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final meshService = context.watch<MeshNetworkService>();
    final emergencyService = context.watch<EmergencyService>();
    final liquidGlassProvider = Provider.of<LiquidGlassProvider>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'Настройки',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // Profile Section
          _buildProfileSection(context, meshService),
          
          const SizedBox(height: 8),
          
          // Network Section
          _buildSection(
            context,
            'Сеть',
            [
              _buildListTile(
                context,
                Icons.wifi_tethering,
                'Статус сети',
                '${meshService.peers.length} устройств найдено',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NetworkStatusScreen(),
                    ),
                  );
                },
              ),
              _buildListTile(
                context,
                Icons.search,
                'Поиск устройств',
                meshService.isScanning ? 'Активен' : 'Остановлен',
                trailing: Switch(
                  value: meshService.isScanning,
                  onChanged: (value) {
                    if (value) {
                      meshService.startScanning();
                    } else {
                      meshService.stopScanning();
                    }
                  },
                ),
              ),
              _buildListTile(
                context,
                Icons.broadcast_on_personal,
                'Реклама',
                meshService.isAdvertising ? 'Активна' : 'Остановлена',
                trailing: Switch(
                  value: meshService.isAdvertising,
                  onChanged: (value) {
                    if (value) {
                      meshService.startAdvertising();
                    } else {
                      meshService.stopAdvertising();
                    }
                  },
                ),
              ),
              _buildListTile(
                context,
                Icons.settings_ethernet,
                'Стратегия подключения',
                _connectionStrategy,
                onTap: () => _showConnectionStrategyDialog(),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Privacy Section
          _buildSection(
            context,
            'Приватность',
            [
              _buildListTile(
                context,
                Icons.lock_outline,
                'Шифрование сообщений',
                _encryptMessages ? 'Включено' : 'Выключено',
                trailing: Switch(
                  value: _encryptMessages,
                  onChanged: (value) {
                    setState(() {
                      _encryptMessages = value;
                    });
                  },
                ),
              ),
              _buildListTile(
                context,
                Icons.visibility_outlined,
                'Показывать статус',
                _showOnlineStatus ? 'Виден всем' : 'Скрыт',
                trailing: Switch(
                  value: _showOnlineStatus,
                  onChanged: (value) {
                    setState(() {
                      _showOnlineStatus = value;
                    });
                  },
                ),
              ),
              _buildListTile(
                context,
                Icons.auto_awesome,
                'Автоподключение',
                _autoConnect ? 'Включено' : 'Выключено',
                trailing: Switch(
                  value: _autoConnect,
                  onChanged: (value) {
                    setState(() {
                      _autoConnect = value;
                    });
                  },
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Notifications Section
          _buildSection(
            context,
            'Уведомления',
            [
              _buildListTile(
                context,
                Icons.notifications_outlined,
                'Уведомления',
                _notifications ? 'Включены' : 'Выключены',
                trailing: Switch(
                  value: _notifications,
                  onChanged: (value) {
                    setState(() {
                      _notifications = value;
                    });
                  },
                ),
              ),
              _buildListTile(
                context,
                Icons.vibration,
                'Вибрация',
                _vibration ? 'Включена' : 'Выключена',
                trailing: Switch(
                  value: _vibration,
                  onChanged: (value) {
                    setState(() {
                      _vibration = value;
                    });
                  },
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
// Appearance Section
_buildSection(
  context,
  'Внешний вид',
  [
    _buildListTile(
      context,
      Icons.dark_mode_outlined,
      'Тёмная тема',
      _darkMode ? 'Включена' : 'Выключена',
      trailing: Switch(
        value: _darkMode,
        onChanged: (value) {
          setState(() {
            _darkMode = value;
          });
        },
      ),
    ),
    _buildListTile(
      context,
      Icons.opacity,
      'Жидкое стекло',
      liquidGlassProvider.isLiquidGlass ? 'Включено' : 'Выключено',
      trailing: Switch(
        value: liquidGlassProvider.isLiquidGlass,
        onChanged: (value) {
          // Update provider
          liquidGlassProvider.toggleLiquidGlass(value);
        },
      ),
    ),
    _buildListTile(
      context,
      Icons.language,
      'Язык',
      _language,
      onTap: () => _showLanguageDialog(),
    ),
  ],
),
          
          const SizedBox(height: 8),
          
          // Emergency Section
          _buildSection(
            context,
            'Экстренные ситуации',
            [
              _buildListTile(
                context,
                Icons.warning_amber_rounded,
                'Экстренные сигналы',
                '${emergencyService.criticalSignalsCount} критических',
                onTap: () {
                  // Navigate to emergency alerts
                },
              ),
              _buildListTile(
                context,
                Icons.sos,
                'SOS кнопка',
                'Быстрый вызов помощи',
                onTap: () {
                  // Navigate to SOS screen
                },
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // About Section
          _buildSection(
            context,
            'О приложении',
            [
              _buildListTile(
                context,
                Icons.info_outline,
                'Версия',
                '1.0.0',
              ),
              _buildListTile(
                context,
                Icons.description_outlined,
                'Лицензия',
                'MIT License',
              ),
              _buildListTile(
                context,
                Icons.code,
                'Исходный код',
                'GitHub',
                onTap: () {
                  // Open GitHub
                },
              ),
            ],
          ),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context, MeshNetworkService meshService) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person,
              size: 32,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meshService.deviceName ?? 'Пользователь',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ID: ${meshService.deviceId?.substring(0, 8) ?? 'Неизвестно'}...',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${meshService.onlinePeers.length} устройств онлайн',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              _showEditProfileDialog(context, meshService);
            },
            icon: const Icon(
              Icons.edit,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, MeshNetworkService meshService) {
    _nameController.text = meshService.deviceName ?? '';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Редактировать профиль'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Имя устройства',
                hintText: 'Введите имя',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.person),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            Text(
              'Это имя будет видно другим устройствам в сети',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = _nameController.text.trim();
              if (newName.isNotEmpty) {
                meshService.updateDeviceName(newName);
                setState(() {});
              }
              Navigator.pop(context);
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildListTile(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle, {
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 22,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          fontSize: 13,
        ),
      ),
      trailing: trailing ?? (onTap != null ? const Icon(Icons.chevron_right) : null),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  void _showConnectionStrategyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Стратегия подключения'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStrategyOption('P2P Cluster', 'Рекомендуется'),
            _buildStrategyOption('P2P Star', 'Для небольших сетей'),
            _buildStrategyOption('P2P Point to Point', 'Прямое соединение'),
          ],
        ),
      ),
    );
  }

  Widget _buildStrategyOption(String strategy, String description) {
    return ListTile(
      title: Text(strategy),
      subtitle: Text(description),
      trailing: _connectionStrategy == strategy
          ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
          : null,
      onTap: () {
        setState(() {
          _connectionStrategy = strategy;
        });
        Navigator.pop(context);
      },
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выберите язык'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLanguageOption('Русский'),
            _buildLanguageOption('English'),
            _buildLanguageOption('Español'),
            _buildLanguageOption('Deutsch'),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(String language) {
    return ListTile(
      title: Text(language),
      trailing: _language == language
          ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
          : null,
      onTap: () {
        setState(() {
          _language = language;
        });
        Navigator.pop(context);
      },
    );
  }
}