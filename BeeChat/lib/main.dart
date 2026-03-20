import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/di/service_locator.dart';
import 'core/services/mesh_network_service.dart';
import 'core/services/emergency_service.dart';
import 'ui/screens/home_screen.dart';
import 'ui/theme/app_theme.dart';
import 'core/providers/liquid_glass_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize services
  await setupServiceLocator();
  
  runApp(const CrisisMeshApp());
}

class CrisisMeshApp extends StatelessWidget {
  const CrisisMeshApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<MeshNetworkService>(
          create: (_) => getIt<MeshNetworkService>(),
        ),
        ChangeNotifierProvider<EmergencyService>(
          create: (_) => getIt<EmergencyService>(),
        ),
        ChangeNotifierProvider<LiquidGlassProvider>(
          create: (_) => LiquidGlassProvider(),
        ),
      ],
      child: MaterialApp(
        title: 'Crisis Mesh',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        home: const HomeScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
