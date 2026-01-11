/// 목표 달성 기록 모델
class GoalRecord {
  final String id;
  final String goalId;
  final DateTime date;
  final bool isCompleted;
  final int? commitCount; // GitHub 목표인 경우
  final DateTime? completedAt;
  final DateTime createdAt;

  GoalRecord({
    required this.id,
    required this.goalId,
    required this.date,
    this.isCompleted = false,
    this.commitCount,
    this.completedAt,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory GoalRecord.fromJson(Map<String, dynamic> json) {
    return GoalRecord(
      id: json['id'] as String,
      goalId: json['goal_id'] as String,
      date: DateTime.parse(json['date'] as String),
      isCompleted: json['is_completed'] as bool? ?? false,
      commitCount: json['commit_count'] as int?,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'goal_id': goalId,
      'date': date.toIso8601String().split('T')[0], // YYYY-MM-DD
      'is_completed': isCompleted,
      'commit_count': commitCount,
      'completed_at': completedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  GoalRecord copyWith({
    bool? isCompleted,
    int? commitCount,
    DateTime? completedAt,
  }) {
    return GoalRecord(
      id: id,
      goalId: goalId,
      date: date,
      isCompleted: isCompleted ?? this.isCompleted,
      commitCount: commitCount ?? this.commitCount,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt,
    );
  }
}

/// 오늘의 목표 + 달성 현황을 합친 뷰 모델
class TodayGoal {
  final String goalId;
  final String title;
  final String type;
  final String? githubUsername;
  final String deadlineTime;
  final String character;
  final bool isCompleted;
  final int? commitCount;
  final DateTime? completedAt;

  TodayGoal({
    required this.goalId,
    required this.title,
    required this.type,
    this.githubUsername,
    required this.deadlineTime,
    required this.character,
    this.isCompleted = false,
    this.commitCount,
    this.completedAt,
  });

  bool get isGithubGoal => type == 'github';
  bool get isOverdue {
    if (isCompleted) return false;
    
    final now = DateTime.now();
    final parts = deadlineTime.split(':');
    final deadline = DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
    return now.isAfter(deadline);
  }
}
