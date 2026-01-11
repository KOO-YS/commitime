import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/goal.dart';
import '../models/goal_record.dart';

/// 로컬 데이터베이스 서비스
/// Spring의 Repository와 비슷한 역할
class LocalStorageService {
  static Database? _database;
  static const String _dbName = 'commitime.db';
  static const int _dbVersion = 1;

  /// 데이터베이스 초기화
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
    );
  }

  /// 테이블 생성
  Future<void> _createDatabase(Database db, int version) async {
    // Goals 테이블
    await db.execute('''
      CREATE TABLE goals (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        type TEXT NOT NULL,
        github_username TEXT,
        repeat_days TEXT NOT NULL,
        exclude_holidays INTEGER DEFAULT 0,
        deadline_time TEXT NOT NULL,
        reminder_enabled INTEGER DEFAULT 0,
        reminder_minutes_before INTEGER DEFAULT 60,
        character TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Goal Records 테이블
    await db.execute('''
      CREATE TABLE goal_records (
        id TEXT PRIMARY KEY,
        goal_id TEXT NOT NULL,
        date TEXT NOT NULL,
        is_completed INTEGER DEFAULT 0,
        commit_count INTEGER,
        completed_at TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (goal_id) REFERENCES goals (id) ON DELETE CASCADE
      )
    ''');

    // 인덱스 생성
    await db.execute(
      'CREATE INDEX idx_records_goal_date ON goal_records (goal_id, date)'
    );
    await db.execute(
      'CREATE INDEX idx_records_date ON goal_records (date)'
    );
  }

  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    // 버전 업그레이드 로직 (필요시)
  }

  // ==================== Goals CRUD ====================

  /// 모든 목표 조회
  Future<List<Goal>> getGoals() async {
    final db = await database;
    final maps = await db.query('goals', orderBy: 'created_at DESC');

    return maps.map((map) {
      // repeat_days는 JSON 문자열로 저장되어 있음
      final repeatDaysStr = map['repeat_days'] as String;
      final repeatDays = repeatDaysStr
          .split(',')
          .where((s) => s.isNotEmpty)
          .map((s) => int.parse(s))
          .toList();

      return Goal(
        id: map['id'] as String,
        title: map['title'] as String,
        type: GoalType.values.firstWhere(
          (e) => e.name == map['type'],
          orElse: () => GoalType.manual,
        ),
        githubUsername: map['github_username'] as String?,
        repeatDays: repeatDays,
        excludeHolidays: (map['exclude_holidays'] as int) == 1,
        deadlineTime: map['deadline_time'] as String,
        reminderEnabled: (map['reminder_enabled'] as int) == 1,
        reminderMinutesBefore: map['reminder_minutes_before'] as int,
        character: CharacterType.values.firstWhere(
          (e) => e.name == map['character'],
          orElse: () => CharacterType.professor,
        ),
        createdAt: DateTime.parse(map['created_at'] as String),
        updatedAt: DateTime.parse(map['updated_at'] as String),
      );
    }).toList();
  }

  /// 목표 저장 (추가/수정)
  Future<void> saveGoal(Goal goal) async {
    final db = await database;

    await db.insert(
      'goals',
      {
        'id': goal.id,
        'title': goal.title,
        'type': goal.type.name,
        'github_username': goal.githubUsername,
        'repeat_days': goal.repeatDays.join(','),
        'exclude_holidays': goal.excludeHolidays ? 1 : 0,
        'deadline_time': goal.deadlineTime,
        'reminder_enabled': goal.reminderEnabled ? 1 : 0,
        'reminder_minutes_before': goal.reminderMinutesBefore,
        'character': goal.character.name,
        'created_at': goal.createdAt.toIso8601String(),
        'updated_at': goal.updatedAt.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 목표 삭제
  Future<void> deleteGoal(String goalId) async {
    final db = await database;

    // 관련 기록도 함께 삭제 (CASCADE로 자동 처리되지만 명시적으로)
    await db.delete('goal_records', where: 'goal_id = ?', whereArgs: [goalId]);
    await db.delete('goals', where: 'id = ?', whereArgs: [goalId]);
  }

  // ==================== Goal Records CRUD ====================

  /// 특정 날짜의 기록 조회
  Future<List<GoalRecord>> getRecordsForDate(DateTime date) async {
    final db = await database;
    final dateStr = date.toIso8601String().split('T')[0]; // YYYY-MM-DD

    final maps = await db.query(
      'goal_records',
      where: 'date = ?',
      whereArgs: [dateStr],
    );

    return maps.map((map) => GoalRecord(
      id: map['id'] as String,
      goalId: map['goal_id'] as String,
      date: DateTime.parse(map['date'] as String),
      isCompleted: (map['is_completed'] as int) == 1,
      commitCount: map['commit_count'] as int?,
      completedAt: map['completed_at'] != null
          ? DateTime.parse(map['completed_at'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
    )).toList();
  }

  /// 월별 기록 조회
  Future<List<GoalRecord>> getRecordsForMonth(int year, int month) async {
    final db = await database;
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0); // 해당 월의 마지막 날

    final maps = await db.query(
      'goal_records',
      where: 'date >= ? AND date <= ?',
      whereArgs: [
        startDate.toIso8601String().split('T')[0],
        endDate.toIso8601String().split('T')[0],
      ],
    );

    return maps.map((map) => GoalRecord(
      id: map['id'] as String,
      goalId: map['goal_id'] as String,
      date: DateTime.parse(map['date'] as String),
      isCompleted: (map['is_completed'] as int) == 1,
      commitCount: map['commit_count'] as int?,
      completedAt: map['completed_at'] != null
          ? DateTime.parse(map['completed_at'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
    )).toList();
  }

  /// 기록 저장
  Future<void> saveRecord(GoalRecord record) async {
    final db = await database;

    await db.insert(
      'goal_records',
      {
        'id': record.id,
        'goal_id': record.goalId,
        'date': record.date.toIso8601String().split('T')[0],
        'is_completed': record.isCompleted ? 1 : 0,
        'commit_count': record.commitCount,
        'completed_at': record.completedAt?.toIso8601String(),
        'created_at': record.createdAt.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 데이터베이스 닫기
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
