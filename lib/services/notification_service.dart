import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../models/goal.dart';
import '../models/nagging_message.dart';

/// 로컬 알림 서비스
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// 서비스 초기화
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Timezone 초기화
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

    // Android 설정
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS 설정
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _isInitialized = true;
  }

  /// 알림 탭 핸들러
  void _onNotificationTapped(NotificationResponse response) {
    // 알림 탭 시 앱 열기 (필요시 특정 화면으로 이동)
    // TODO: 딥링크 처리
  }

  /// 권한 요청
  Future<bool> requestPermissions() async {
    // Android 13+ 권한 요청
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
      return granted ?? false;
    }

    // iOS 권한 요청
    final iosPlugin = _notifications
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    
    if (iosPlugin != null) {
      final granted = await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return true;
  }

  /// 목표 알림 스케줄
  Future<void> scheduleGoalNotification({
    required Goal goal,
    required bool isReminder,
  }) async {
    final timeParts = goal.deadlineTime.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);

    // 알림 시간 계산
    int notificationHour = hour;
    int notificationMinute = minute;
    
    if (isReminder) {
      // 리마인더는 설정된 시간 전에 알림
      final totalMinutes = hour * 60 + minute - goal.reminderMinutesBefore;
      notificationHour = totalMinutes ~/ 60;
      notificationMinute = totalMinutes % 60;
      
      if (notificationHour < 0) {
        notificationHour += 24; // 자정 넘어가는 경우 처리
      }
    }

    // 각 반복 요일에 대해 알림 스케줄
    for (final day in goal.repeatDays) {
      final notificationId = _generateNotificationId(goal.id, day, isReminder);
      
      // 잔소리 메시지 생성
      final message = MessageGenerator.generate(
        character: goal.character,
        completedCount: 0,
        totalCount: 1,
        hasOverdue: false,
      );

      final title = isReminder 
          ? '⏰ ${goal.title} 리마인더'
          : '🎯 ${goal.title}';
      
      final body = isReminder
          ? '${goal.reminderMinutesBefore}분 후가 마감이에요!'
          : '${goal.character.emoji} ${message.text}';

      await _notifications.zonedSchedule(
        notificationId,
        title,
        body,
        _nextInstanceOfWeekdayTime(day, notificationHour, notificationMinute),
        NotificationDetails(
          android: AndroidNotificationDetails(
            'goal_channel',
            '목표 알림',
            channelDescription: '목표 달성 알림',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }
  }

  /// 목표 관련 알림 취소
  Future<void> cancelGoalNotifications(String goalId) async {
    // 모든 요일 + 리마인더 알림 취소
    for (int day = 1; day <= 7; day++) {
      await _notifications.cancel(_generateNotificationId(goalId, day, false));
      await _notifications.cancel(_generateNotificationId(goalId, day, true));
    }
  }

  /// 모든 알림 취소
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  /// 즉시 알림 표시 (테스트용)
  Future<void> showInstantNotification({
    required String title,
    required String body,
  }) async {
    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'instant_channel',
          '즉시 알림',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  /// 알림 ID 생성 (goalId + 요일 + 리마인더 여부 조합)
  int _generateNotificationId(String goalId, int day, bool isReminder) {
    final hash = goalId.hashCode.abs();
    return hash * 100 + day * 10 + (isReminder ? 1 : 0);
  }

  /// 다음 특정 요일/시간 계산
  tz.TZDateTime _nextInstanceOfWeekdayTime(int weekday, int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // 해당 요일까지 날짜 이동
    while (scheduledDate.weekday != weekday) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // 이미 지난 시간이면 다음 주로
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 7));
    }

    return scheduledDate;
  }

  /// 예약된 알림 목록 조회 (디버깅용)
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }
}
