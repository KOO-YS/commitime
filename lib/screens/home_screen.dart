import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/goal_provider.dart';
import '../models/goal.dart';
import '../widgets/clover_logo.dart';
import '../widgets/nagging_card.dart';
import '../widgets/goal_item.dart';
import '../utils/constants.dart';

/// 홈 화면 - 오늘의 목표 리스트
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  CharacterType _selectedCharacter = CharacterType.professor;

  @override
  void initState() {
    super.initState();
    // 데이터 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GoalProvider>().loadGoals();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Consumer<GoalProvider>(
          builder: (context, goalProvider, child) {
            if (goalProvider.isLoading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            return RefreshIndicator(
              onRefresh: () => goalProvider.loadGoals(),
              color: AppColors.primary,
              child: CustomScrollView(
                slivers: [
                  // 헤더
                  SliverToBoxAdapter(
                    child: _buildHeader(),
                  ),
                  // 잔소리 카드
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: NaggingCard(
                        message: goalProvider.getCurrentMessage(_selectedCharacter),
                        onTap: _showCharacterPicker,
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 20)),
                  // 진행률 바
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: ProgressBar(
                        completed: goalProvider.completedCount,
                        total: goalProvider.totalCount,
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  // 목표 리스트 헤더
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "TODAY'S TASKS",
                            style: AppTextStyles.label,
                          ),
                          Text(
                            '${goalProvider.completedCount}/${goalProvider.totalCount} 완료',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 12)),
                  // 목표 리스트
                  if (goalProvider.todayGoalsWithStatus.isEmpty)
                    SliverToBoxAdapter(child: _buildEmptyState())
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final goal = goalProvider.todayGoalsWithStatus[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: GoalItem(
                                goal: goal,
                                onToggle: () {
                                  goalProvider.toggleGoalCompletion(goal.goalId);
                                },
                              ),
                            );
                          },
                          childCount: goalProvider.todayGoalsWithStatus.length,
                        ),
                      ),
                    ),
                  // 하단 여백
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final now = DateTime.now();
    final dateFormat = DateFormat('EEEE, MMMM d', 'en_US');

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dateFormat.format(now),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 4),
              const Row(
                children: [
                  Text(
                    "Today's Goals",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text('✨', style: TextStyle(fontSize: 24)),
                ],
              ),
            ],
          ),
          const CloverLogo(size: 48),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            '🌱',
            style: TextStyle(fontSize: 48),
          ),
          const SizedBox(height: 16),
          const Text(
            '오늘의 목표가 없어요',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '+ 버튼을 눌러 새 목표를 추가해보세요!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  void _showCharacterPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '잔소리 캐릭터 선택',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...CharacterType.values.map((character) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: CharacterChip(
                    character: character,
                    isSelected: _selectedCharacter == character,
                    onTap: () {
                      setState(() => _selectedCharacter = character);
                      Navigator.pop(context);
                    },
                  ),
                );
              }),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}
