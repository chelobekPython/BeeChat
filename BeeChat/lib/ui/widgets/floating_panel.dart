import 'package:flutter/material.dart';
import '../../core/services/mesh_network_service.dart';
import '../../core/di/service_locator.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';

class FloatingPanel extends StatefulWidget {
  final bool isLiquidGlass;
  final Function() onAttach;
  final Function() onCamera;
  final Function() onEmoji;
  final Function() onVoice;
  final Function() onMore;

  const FloatingPanel({
    super.key,
    required this.isLiquidGlass,
    required this.onAttach,
    required this.onCamera,
    required this.onEmoji,
    required this.onVoice,
    required this.onMore,
  });

  @override
  State<FloatingPanel> createState() => _FloatingPanelState();
}

class _FloatingPanelState extends State<FloatingPanel> {
  final _meshService = getIt<MeshNetworkService>();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildButton(
              Icons.attach_file,
              'Attach',
              widget.onAttach,
            ),
            _buildButton(
              Icons.photo_camera,
              'Camera',
              widget.onCamera,
            ),
            _buildButton(
              Icons.emoji_emotions,
              'Emoji',
              widget.onEmoji,
            ),
            _buildButton(
              Icons.mic,
              'Voice',
              widget.onVoice,
            ),
            _buildButton(
              Icons.more_horiz,
              'More',
              widget.onMore,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(IconData icon, String tooltip, VoidCallback onPressed) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: AppTheme.liquidGlassDecoration(context, widget.isLiquidGlass),
      child: IconButton(
        icon: Icon(
          icon,
          size: 24,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        onPressed: onPressed,
        tooltip: tooltip,
      ),
    );
  }
}