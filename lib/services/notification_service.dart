import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:alarm/alarm.dart';
import '../models/goal.dart';
import '../models/nagging_message.dart';
import 'settings_service.dart';

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
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'goal_channel',
            '목표 알림',
            channelDescription: '목표 달성 알림',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
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

  /// N분 후 예약 알람 (테스트용)
  /// 앱이 꺼져있어도 설정된 시간에 알람이 울립니다.
  Future<void> scheduleTestNotification({
    required int minutesFromNow,
    required String title,
    required String body,
  }) async {
    final scheduledTime = tz.TZDateTime.now(tz.local).add(
      Duration(minutes: minutesFromNow),
    );

    await _notifications.zonedSchedule(
      999999, // 테스트용 고정 ID
      title,
      body,
      scheduledTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'scheduled_test_channel',
          '예약 알림 테스트',
          channelDescription: '예약된 알림 테스트',
          importance: Importance.max,
          priority: Priority.max,
          playSound: true,
          enableVibration: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  /// 알림 ID 생성 (goalId + 요일 + 리마인더 여부 조합)
  int _generateNotificationId(String goalId, int day, bool isReminder) {
    final hash = goalId.hashCode.abs();
    return hash * 100 + day * 10 + (isReminder ? 1 : 0);
  }

  /// 다음 특정 요일/시간 계산 (가장 가까운 미래 시점)
  tz.TZDateTime _nextInstanceOfWeekdayTime(int weekday, int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);

    // 오늘부터 7일간 확인해서 가장 가까운 해당 요일 찾기
    for (int daysAhead = 0; daysAhead < 7; daysAhead++) {
      final checkDate = now.add(Duration(days: daysAhead));

      if (checkDate.weekday == weekday) {
        final scheduledDate = tz.TZDateTime(
          tz.local,
          checkDate.year,
          checkDate.month,
          checkDate.day,
          hour,
          minute,
        );

        // 아직 지나지 않은 시간이면 이 날짜 사용
        if (scheduledDate.isAfter(now)) {
          return scheduledDate;
        }
      }
    }

    // 이번 주에 해당 요일+시간이 모두 지났으면 다음 주로
    var nextWeekDate = now.add(const Duration(days: 7));
    while (nextWeekDate.weekday != weekday) {
      nextWeekDate = nextWeekDate.subtract(const Duration(days: 1));
    }

    return tz.TZDateTime(
      tz.local,
      nextWeekDate.year,
      nextWeekDate.month,
      nextWeekDate.day,
      hour,
      minute,
    );
  }

  /// 예약된 알림 목록 조회 (디버깅용)
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  // ============================================
  // 풀스크린 알람 (alarm 패키지)
  // ============================================

  /// 풀스크린 알람 스케줄 (마감 시간용)
  Future<void> scheduleFullscreenAlarm({
    required Goal goal,
  }) async {
    final timeParts = goal.deadlineTime.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);

    // 목표별 볼륨 사용 (사운드가 꺼져있으면 0)
    final settings = await SettingsService.getInstance();
    final soundEnabled = settings.soundEnabled;
    final volume = soundEnabled ? goal.alarmVolume : 0.0;

    // 각 반복 요일에 대해 알람 스케줄
    for (final day in goal.repeatDays) {
      final alarmId = _generateFullscreenAlarmId(goal.id, day);
      final scheduledTime = _nextInstanceOfWeekdayTime(day, hour, minute);

      // 잔소리 메시지 생성
      final message = MessageGenerator.generate(
        character: goal.character,
        completedCount: 0,
        totalCount: 1,
        hasOverdue: false,
      );

      final alarmSettings = AlarmSettings(
        id: alarmId,
        dateTime: scheduledTime,
        assetAudioPath: 'assets/sounds/alarm.mp3',
        loopAudio: soundEnabled && volume > 0,
        vibrate: true,
        volumeSettings: volume > 0
            ? VolumeSettings.fade(
                volume: volume,
                fadeDuration: const Duration(seconds: 3),
              )
            : const VolumeSettings.fixed(volume: 0),
        androidFullScreenIntent: true,
        notificationSettings: NotificationSettings(
          title: '🎯 ${goal.title}',
          body: '${goal.character.emoji} ${message.text}',
          stopButton: '확인',
        ),
      );

      await Alarm.set(alarmSettings: alarmSettings);
    }
  }

  /// 풀스크린 알람 취소
  Future<void> cancelFullscreenAlarm(String goalId) async {
    for (int day = 1; day <= 7; day++) {
      final alarmId = _generateFullscreenAlarmId(goalId, day);
      await Alarm.stop(alarmId);
    }
  }

  /// 특정 알람 중지
  Future<void> stopAlarm(int alarmId) async {
    await Alarm.stop(alarmId);
  }

  /// 풀스크린 알람 ID 생성
  int _generateFullscreenAlarmId(String goalId, int day) {
    // 기존 알림 ID와 충돌 방지를 위해 다른 범위 사용
    final hash = goalId.hashCode.abs();
    return (hash % 100000) * 10 + day;
  }

  /// 현재 울리는 알람 목록 조회
  Future<List<AlarmSettings>> getRingingAlarms() async {
    return Alarm.getAlarms();
  }
}
