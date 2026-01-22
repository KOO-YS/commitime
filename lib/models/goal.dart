import 'package:uuid/uuid.dart';

/// 목표 타입
enum GoalType {
  manual,  // 수동 체크
  github,  // GitHub 커밋 자동 체크
}

/// 잔소리 캐릭터 타입
enum CharacterType {
  professor,
  mom,
  friend,
  drill,
}

extension CharacterTypeExtension on CharacterType {
  String get displayName {
    switch (this) {
      case CharacterType.professor:
        return '교수님';
      case CharacterType.mom:
        return '엄마';
      case CharacterType.friend:
        return '친구';
      case CharacterType.drill:
        return '조교관';
    }
  }

  String get emoji {
    switch (this) {
      case CharacterType.professor:
        return '👨‍🏫';
      case CharacterType.mom:
        return '👩';
      case CharacterType.friend:
        return '😊';
      case CharacterType.drill:
        return '🪖';
    }
  }

  String get style {
    switch (this) {
      case CharacterType.professor:
        return '분석적';
      case CharacterType.mom:
        return '따뜻한';
      case CharacterType.friend:
        return '편한';
      case CharacterType.drill:
        return '엄격한';
    }
  }
}

/// 목표 모델
class Goal {
  final String id;
  final String title;
  final GoalType type;
  final String? githubUsername;
  final List<int> repeatDays; // 1=월, 2=화, ..., 7=일
  final bool excludeHolidays;
  final String deadlineTime; // "HH:mm" 형식
  final bool reminderEnabled;
  final int reminderMinutesBefore;
  final CharacterType character;
  final double alarmVolume; // 0.0 ~ 1.0 (목표별 알람 볼륨)
  final DateTime createdAt;
  final DateTime updatedAt;

  Goal({
    String? id,
    required this.title,
    required this.type,
    this.githubUsername,
    required this.repeatDays,
    this.excludeHolidays = false,
    required this.deadlineTime,
    this.reminderEnabled = false,
    this.reminderMinutesBefore = 60,
    this.character = CharacterType.professor,
    this.alarmVolume = 0.8,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// JSON에서 Goal 객체 생성
  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['id'] as String,
      title: json['title'] as String,
      type: GoalType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => GoalType.manual,
      ),
      githubUsername: json['github_username'] as String?,
      repeatDays: (json['repeat_days'] as List<dynamic>).cast<int>(),
      excludeHolidays: json['exclude_holidays'] as bool? ?? false,
      deadlineTime: json['deadline_time'] as String,
      reminderEnabled: json['reminder_enabled'] as bool? ?? false,
      reminderMinutesBefore: json['reminder_minutes_before'] as int? ?? 60,
      character: CharacterType.values.firstWhere(
        (e) => e.name == json['character'],
        orElse: () => CharacterType.professor,
      ),
      alarmVolume: (json['alarm_volume'] as num?)?.toDouble() ?? 0.8,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Goal 객체를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type.name,
      'github_username': githubUsername,
      'repeat_days': repeatDays,
      'exclude_holidays': excludeHolidays,
      'deadline_time': deadlineTime,
      'reminder_enabled': reminderEnabled,
      'reminder_minutes_before': reminderMinutesBefore,
      'character': character.name,
      'alarm_volume': alarmVolume,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// 복사본 생성 (일부 필드 수정)
  Goal copyWith({
    String? title,
    GoalType? type,
    String? githubUsername,
    List<int>? repeatDays,
    bool? excludeHolidays,
    String? deadlineTime,
    bool? reminderEnabled,
    int? reminderMinutesBefore,
    CharacterType? character,
    double? alarmVolume,
  }) {
    return Goal(
      id: id,
      title: title ?? this.title,
      type: type ?? this.type,
      githubUsername: githubUsername ?? this.githubUsername,
      repeatDays: repeatDays ?? this.repeatDays,
      excludeHolidays: excludeHolidays ?? this.excludeHolidays,
      deadlineTime: deadlineTime ?? this.deadlineTime,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderMinutesBefore: reminderMinutesBefore ?? this.reminderMinutesBefore,
      character: character ?? this.character,
      alarmVolume: alarmVolume ?? this.alarmVolume,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  /// 오늘 해당 목표가 활성화되어 있는지 확인
  bool isActiveToday() {
    final today = DateTime.now().weekday; // 1=월, 7=일
    return repeatDays.contains(today);
  }
}
