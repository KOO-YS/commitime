import 'package:flutter/material.dart';
import '../models/goal_record.dart';
import '../utils/constants.dart';

/// 목표 리스트 아이템 카드
class GoalItem extends StatelessWidget {
  final TodayGoal goal;
  final VoidCallback? onTap;
  final VoidCallback? onToggle;

  const GoalItem({
    super.key,
    required this.goal,
    this.onTap,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: goal.isCompleted ? AppColors.level1 : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            // 체크 버튼
            _buildCheckButton(),
            const SizedBox(width: 16),
            // 목표 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          goal.title,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                            decoration: goal.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                            color: goal.isCompleted
                                ? AppColors.textLight
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (goal.isGithubGoal)
                        const Icon(
                          Icons.code,
                          size: 18,
                          color: AppColors.textLight,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // 마감 시간
                      _buildTimeChip(),
                      const SizedBox(width: 8),
                      // GitHub 커밋 수 (해당하는 경우)
                      if (goal.isGithubGoal && goal.commitCount != null)
                        _buildCommitChip(),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // 상태 이모지
            Text(
              goal.isCompleted ? '🎉' : (goal.isOverdue ? '😰' : '⏰'),
              style: const TextStyle(fontSize: 24),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckButton() {
    final isManual = !goal.isGithubGoal;

    return GestureDetector(
      onTap: isManual ? onToggle : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: goal.isCompleted ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: goal.isCompleted ? AppColors.primary : AppColors.textLight,
            width: 2,
          ),
          boxShadow: goal.isCompleted
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: goal.isCompleted
            ? const Icon(
                Icons.check,
                color: Colors.white,
                size: 20,
              )
            : null,
      ),
    );
  }

  Widget _buildTimeChip() {
    final isOverdue = goal.isOverdue;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isOverdue
            ? AppColors.error.withOpacity(0.1)
            : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.access_time,
            size: 14,
            color: isOverdue ? AppColors.error : AppColors.textSecondary,
          ),
          const SizedBox(width: 4),
          Text(
            goal.deadlineTime,
            style: TextStyle(
              fontSize: 12,
              color: isOverdue ? AppColors.error : AppColors.textSecondary,
              fontWeight: isOverdue ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommitChip() {
    final hasCommits = (goal.commitCount ?? 0) > 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: hasCommits ? AppColors.level1 : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.commit,
            size: 14,
            color: hasCommits ? AppColors.primaryDark : AppColors.textSecondary,
          ),
          const SizedBox(width: 4),
          Text(
            '${goal.commitCount} commits',
            style: TextStyle(
              fontSize: 12,
              color:
                  hasCommits ? AppColors.primaryDark : AppColors.textSecondary,
              fontWeight: hasCommits ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          if (hasCommits) ...[
            const SizedBox(width: 4),
            const Text('✓', style: TextStyle(fontSize: 12)),
          ],
        ],
      ),
    );
  }
}

/// 진행률 바 위젯
class ProgressBar extends StatelessWidget {
  final int completed;
  final int total;

  const ProgressBar({
    super.key,
    required this.completed,
    required this.total,
  });

  double get _progress => total > 0 ? completed / total : 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // 헤더
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Daily Progress',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700,
                ),
              ),
              Text(
                '$completed/$total',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 프로그레스 바
          Container(
            height: 16,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutCubic,
                      width: constraints.maxWidth * _progress,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          // 단계별 인디케이터
          Row(
            children: List.generate(total, (index) {
              return Expanded(
                child: Container(
                  height: 8,
                  margin: EdgeInsets.only(right: index < total - 1 ? 6 : 0),
                  decoration: BoxDecoration(
                    color: index < completed
                        ? AppColors.primary
                        : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
