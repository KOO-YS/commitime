import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/goal_provider.dart';
import 'services/local_storage_service.dart';
import 'services/notification_service.dart';
import 'screens/splash_screen.dart';
import 'screens/main_screen.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 서비스 초기화
  final storageService = LocalStorageService();
  final notificationService = NotificationService();
  
  await notificationService.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => GoalProvider(
            storageService: storageService,
            notificationService: notificationService,
          ),
        ),
      ],
      child: const CommitimeApp(),
    ),
  );
}

class CommitimeApp extends StatelessWidget {
  const CommitimeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Commitime',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/main': (context) => const MainScreen(),
      },
    );
  }
}
