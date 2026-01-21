import 'package:flutter/foundation.dart';
import '../models/goal.dart';
import '../models/goal_record.dart';
import '../models/nagging_message.dart';
import '../services/local_storage_service.dart';
import '../services/notification_service.dart';

/// 목표 상태 관리 Provider
/// Spring의 @Service와 비슷한 역할
class GoalProvider extends ChangeNotifier {
  final LocalStorageService _storageService;
  final NotificationService _notificationService;

  List<Goal> _goals = [];
  Map<String, GoalRecord> _todayRecords = {}; // goalId -> record
  bool _isLoading = false;
  String? _error;

  GoalProvider({
    required LocalStorageService storageService,
    required NotificationService notificationService,
  })  : _storageService = storageService,
        _notificationService = notificationService;

  // Getters
  List<Goal> get goals => _goals;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// 오늘 활성화된 목표 목록
  List<Goal> get todayGoals {
    return _goals.where((goal) => goal.isActiveToday()).toList();
  }

  /// 오늘의 목표 + 달성 현황 조합
  List<TodayGoal> get todayGoalsWithStatus {
    return todayGoals.map((goal) {
      final record = _todayRecords[goal.id];
      return TodayGoal(
        goalId: goal.id,
        title: goal.title,
        type: goal.type.name,
        githubUsername: goal.githubUsername,
        deadlineTime: goal.deadlineTime,
        character: goal.character.name,
        isCompleted: record?.isCompleted ?? false,
        commitCount: record?.commitCount,
        completedAt: record?.completedAt,
      );
    }).toList()
      ..sort((a, b) => a.deadlineTime.compareTo(b.deadlineTime));
  }

  /// 완료된 목표 수
  int get completedCount {
    return todayGoalsWithStatus.where((g) => g.isCompleted).length;
  }

  /// 전체 오늘 목표 수
  int get totalCount => todayGoals.length;

  /// 마감 지난 미완료 목표가 있는지
  bool get hasOverdueGoals {
    return todayGoalsWithStatus.any((g) => g.isOverdue);
  }

  /// 현재 잔소리 메시지 생성
  NaggingMessage getCurrentMessage(CharacterType character) {
    return MessageGenerator.generate(
      character: character,
      completedCount: completedCount,
      totalCount: totalCount,
      hasOverdue: hasOverdueGoals,
      streakDays: 0, // TODO: 연속 달성 일수 계산
    );
  }

  /// 초기 데이터 로드
  Future<void> loadGoals() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _goals = await _storageService.getGoals();
      await _loadTodayRecords();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 오늘 기록 로드
  Future<void> _loadTodayRecords() async {
    final today = DateTime.now();
    final records = await _storageService.getRecordsForDate(today);
    
    _todayRecords = {
      for (var record in records) record.goalId: record
    };
  }

  /// 목표 추가
  Future<void> addGoal(Goal goal) async {
    try {
      await _storageService.saveGoal(goal);
      _goals.add(goal);
      
      // 알람 스케줄링
      await _scheduleNotifications(goal);
      
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// 목표 수정
  Future<void> updateGoal(Goal goal) async {
    try {
      await _storageService.saveGoal(goal);
      final index = _goals.indexWhere((g) => g.id == goal.id);
      if (index != -1) {
        _goals[index] = goal;
      }

      // 알람 재스케줄링
      await _cancelAllNotifications(goal.id);
      await _scheduleNotifications(goal);

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// 목표 삭제
  Future<void> deleteGoal(String goalId) async {
    try {
      await _storageService.deleteGoal(goalId);
      _goals.removeWhere((g) => g.id == goalId);

      // 알람 취소
      await _cancelAllNotifications(goalId);

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// 목표 완료 토글 (수동 목표용)
  Future<void> toggleGoalCompletion(String goalId) async {
    final goal = _goals.firstWhere((g) => g.id == goalId);
    if (goal.type != GoalType.manual) return;

    final existingRecord = _todayRecords[goalId];
    final now = DateTime.now();
    
    final newRecord = GoalRecord(
      id: existingRecord?.id ?? '${goalId}_${now.toIso8601String().split('T')[0]}',
      goalId: goalId,
      date: DateTime(now.year, now.month, now.day),
      isCompleted: !(existingRecord?.isCompleted ?? false),
      completedAt: existingRecord?.isCompleted == true ? null : now,
    );

    try {
      await _storageService.saveRecord(newRecord);
      _todayRecords[goalId] = newRecord;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// 특정 날짜의 달성률 조회 (캘린더용)
  Future<double> getCompletionRateForDate(DateTime date) async {
    final records = await _storageService.getRecordsForDate(date);
    if (records.isEmpty) return 0.0;
    
    final completedCount = records.where((r) => r.isCompleted).length;
    return completedCount / records.length;
  }

  /// 월별 달성 데이터 조회 (캘린더용)
  Future<Map<int, int>> getMonthlyAchievements(int year, int month) async {
    final records = await _storageService.getRecordsForMonth(year, month);
    
    // 일자별 달성률을 0-4 레벨로 변환
    final Map<int, List<GoalRecord>> recordsByDay = {};
    for (var record in records) {
      final day = record.date.day;
      recordsByDay.putIfAbsent(day, () => []).add(record);
    }

    final Map<int, int> achievements = {};
    for (var entry in recordsByDay.entries) {
      final dayRecords = entry.value;
      final completedCount = dayRecords.where((r) => r.isCompleted).length;
      final rate = completedCount / dayRecords.length;
      
      // 달성률을 0-4 레벨로 변환
      int level;
      if (rate == 0) {
        level = 0;
      } else if (rate < 0.25) {
        level = 1;
      } else if (rate < 0.5) {
        level = 2;
      } else if (rate < 1.0) {
        level = 3;
      } else {
        level = 4;
      }
      
      achievements[entry.key] = level;
    }

    return achievements;
  }

  /// 알람 스케줄링
  Future<void> _scheduleNotifications(Goal goal) async {
    // 마감 시간: 풀스크린 알람 (사운드 + 전체 화면)
    await _notificationService.scheduleFullscreenAlarm(goal: goal);

    // 리마인더: 팝업 알림 (설정된 경우)
    if (goal.reminderEnabled) {
      await _notificationService.scheduleGoalNotification(
        goal: goal,
        isReminder: true,
      );
    }
  }

  /// 모든 알람 취소 (목표 삭제/수정 시)
  Future<void> _cancelAllNotifications(String goalId) async {
    await _notificationService.cancelGoalNotifications(goalId);
    await _notificationService.cancelFullscreenAlarm(goalId);
  }
}
