import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:alarm/alarm.dart';
import 'providers/goal_provider.dart';
import 'models/goal.dart';
import 'services/local_storage_service.dart';
import 'services/notification_service.dart';
import 'screens/splash_screen.dart';
import 'screens/main_screen.dart';
import 'screens/alarm_screen.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 서비스 초기화
  final storageService = LocalStorageService();
  final notificationService = NotificationService();

  await notificationService.initialize();
  await Alarm.init();

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
      child: CommitimeApp(storageService: storageService),
    ),
  );
}

class CommitimeApp extends StatefulWidget {
  final LocalStorageService storageService;

  const CommitimeApp({
    super.key,
    required this.storageService,
  });

  @override
  State<CommitimeApp> createState() => _CommitimeAppState();
}

class _CommitimeAppState extends State<CommitimeApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _setupAlarmListener();
  }

  void _setupAlarmListener() {
    // 알람이 울릴 때 풀스크린 화면으로 이동
    Alarm.ringing.listen((alarmSet) {
      final alarms = alarmSet.alarms;
      if (alarms.isNotEmpty) {
        _showAlarmScreen(alarms.first);
      }
    });
  }

  Future<void> _showAlarmScreen(AlarmSettings alarmSettings) async {
    // 알람 ID로 목표 찾기
    final goals = await widget.storageService.getGoals();
    Goal? matchedGoal;

    for (final goal in goals) {
      for (int day = 1; day <= 7; day++) {
        final expectedId = (goal.id.hashCode.abs() % 100000) * 10 + day;
        if (expectedId == alarmSettings.id) {
          matchedGoal = goal;
          break;
        }
      }
      if (matchedGoal != null) break;
    }

    _navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (context) => AlarmScreen(
          alarmSettings: alarmSettings,
          goal: matchedGoal,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
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
