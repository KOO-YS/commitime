import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:alarm/alarm.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/goal.dart';
import '../models/nagging_message.dart';
import '../utils/constants.dart';

/// 풀스크린 알람 화면
class AlarmScreen extends StatefulWidget {
  final AlarmSettings alarmSettings;
  final Goal? goal;

  const AlarmScreen({
    super.key,
    required this.alarmSettings,
    this.goal,
  });

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  String _naggingMessage = '';

  @override
  void initState() {
    super.initState();

    // 화면 켜기 및 유지
    WakelockPlus.enable();

    // 풀스크린 모드 설정
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

    // 펄스 애니메이션 설정
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // 잔소리 메시지 생성
    if (widget.goal != null) {
      final message = MessageGenerator.generate(
        character: widget.goal!.character,
        completedCount: 0,
        totalCount: 1,
        hasOverdue: true,
      );
      _naggingMessage = message.text;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    // 화면 유지 해제
    WakelockPlus.disable();
    // 시스템 UI 복원
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    super.dispose();
  }

  Future<void> _dismissAlarm() async {
    await Alarm.stop(widget.alarmSettings.id);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _snoozeAlarm() async {
    await Alarm.stop(widget.alarmSettings.id);

    // 5분 후 다시 알람 설정
    final snoozeSettings = widget.alarmSettings.copyWith(
      dateTime: DateTime.now().add(const Duration(minutes: 5)),
    );
    await Alarm.set(alarmSettings: snoozeSettings);

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('5분 후에 다시 알려드릴게요'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  Color _getBackgroundColor() {
    if (widget.goal == null) return AppColors.primary;

    switch (widget.goal!.character) {
      case CharacterType.professor:
        return AppColors.professorCard;
      case CharacterType.mom:
        return AppColors.momCard;
      case CharacterType.friend:
        return AppColors.friendCard;
      case CharacterType.drill:
        return AppColors.drillCard;
    }
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = _getBackgroundColor();
    final title = widget.goal?.title ??
        widget.alarmSettings.notificationSettings.title;
    final emoji = widget.goal?.character.emoji ?? '🎯';

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              backgroundColor,
              backgroundColor.withOpacity(0.7),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // 캐릭터 이모지 (펄스 애니메이션)
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Text(
                      emoji,
                      style: const TextStyle(fontSize: 80),
                    ),
                  );
                },
              ),

              const SizedBox(height: 32),

              // 목표 제목
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 잔소리 메시지
              if (_naggingMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _naggingMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        height: 1.5,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),

              const Spacer(flex: 3),

              // 버튼 영역
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  children: [
                    // 확인 버튼
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _dismissAlarm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check, size: 28),
                            SizedBox(width: 12),
                            Text(
                              '확인했어요',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 스누즈 버튼
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _snoozeAlarm,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          side: const BorderSide(
                            color: AppColors.textSecondary,
                            width: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.snooze, size: 24),
                            SizedBox(width: 12),
                            Text(
                              '5분 뒤 다시 알림',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }
}
