import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/goal_provider.dart';
import '../models/goal.dart';
import '../services/github_service.dart';
import '../widgets/clover_logo.dart';
import '../widgets/nagging_card.dart';
import '../utils/constants.dart';

/// 목표 생성/수정 화면
class GoalCreationScreen extends StatefulWidget {
  final Goal? existingGoal; // 수정 시 기존 목표

  const GoalCreationScreen({
    super.key,
    this.existingGoal,
  });

  @override
  State<GoalCreationScreen> createState() => _GoalCreationScreenState();
}

class _GoalCreationScreenState extends State<GoalCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _githubUsernameController = TextEditingController();
  final _githubService = GitHubService();

  GoalType _goalType = GoalType.manual;
  List<int> _selectedDays = [1, 2, 3, 4, 5]; // 월~금
  bool _excludeHolidays = false;
  TimeOfDay _deadlineTime = const TimeOfDay(hour: 18, minute: 0);
  bool _reminderEnabled = false;
  int _reminderMinutes = 60;
  CharacterType _selectedCharacter = CharacterType.professor;

  bool _isLoading = false;
  bool _isValidatingGithub = false;
  String? _githubValidationError;

  final List<String> _dayLabels = ['월', '화', '수', '목', '금', '토', '일'];
  final List<int> _reminderOptions = [30, 60, 120]; // 분

  @override
  void initState() {
    super.initState();
    if (widget.existingGoal != null) {
      _loadExistingGoal();
    }
  }

  void _loadExistingGoal() {
    final goal = widget.existingGoal!;
    _titleController.text = goal.title;
    _goalType = goal.type;
    _githubUsernameController.text = goal.githubUsername ?? '';
    _selectedDays = List.from(goal.repeatDays);
    _excludeHolidays = goal.excludeHolidays;

    final timeParts = goal.deadlineTime.split(':');
    _deadlineTime = TimeOfDay(
      hour: int.parse(timeParts[0]),
      minute: int.parse(timeParts[1]),
    );

    _reminderEnabled = goal.reminderEnabled;
    _reminderMinutes = goal.reminderMinutesBefore;
    _selectedCharacter = goal.character;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _githubUsernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingGoal != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // 헤더
            _buildHeader(isEditing),
            // 폼
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildGoalTypeSelector(),
                      const SizedBox(height: 24),
                      _buildTitleField(),
                      if (_goalType == GoalType.github) ...[
                        const SizedBox(height: 24),
                        _buildGithubUsernameField(),
                      ],
                      const SizedBox(height: 24),
                      _buildRepeatDaysSelector(),
                      const SizedBox(height: 24),
                      _buildHolidaySwitch(),
                      const SizedBox(height: 24),
                      _buildDeadlineTimePicker(),
                      const SizedBox(height: 24),
                      _buildReminderSection(),
                      const SizedBox(height: 24),
                      _buildCharacterSelector(),
                      const SizedBox(height: 40),
                      _buildSubmitButton(isEditing),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isEditing) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    isEditing ? '목표 수정' : 'Create Goal',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('✨', style: TextStyle(fontSize: 24)),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                isEditing ? '목표를 수정하세요' : '새로운 목표를 설정하세요',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
          const CloverLogo(size: 40),
        ],
      ),
    );
  }

  Widget _buildGoalTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('GOAL TYPE', style: AppTextStyles.label),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTypeCard(
                type: GoalType.manual,
                icon: Icons.check_circle_outline,
                label: 'Manual',
                description: '직접 체크',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTypeCard(
                type: GoalType.github,
                icon: Icons.code,
                label: 'GitHub',
                description: '자동 확인',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTypeCard({
    required GoalType type,
    required IconData icon,
    required String label,
    required String description,
  }) {
    final isSelected = _goalType == type;

    return GestureDetector(
      onTap: () => setState(() => _goalType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.level1.withOpacity(0.3) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? AppColors.primaryLight : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                size: 28,
                color: isSelected ? Colors.white : AppColors.textLight,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
              ),
            ),
            Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('GOAL TITLE', style: AppTextStyles.label),
        const SizedBox(height: 12),
        TextFormField(
          controller: _titleController,
          decoration: InputDecoration(
            hintText: 'e.g., Morning workout 💪',
            hintStyle: TextStyle(color: Colors.grey.shade400),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '목표 제목을 입력해주세요';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildGithubUsernameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('GITHUB USERNAME', style: AppTextStyles.label),
        const SizedBox(height: 12),
        TextFormField(
          controller: _githubUsernameController,
          decoration: InputDecoration(
            hintText: 'your-username',
            hintStyle: TextStyle(color: Colors.grey.shade400),
            prefixIcon: const Icon(Icons.alternate_email),
            suffixIcon: _isValidatingGithub
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.check_circle_outline),
                    onPressed: _validateGithubUsername,
                  ),
            errorText: _githubValidationError,
          ),
          validator: (value) {
            if (_goalType == GoalType.github &&
                (value == null || value.trim().isEmpty)) {
              return 'GitHub 사용자명을 입력해주세요';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildRepeatDaysSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('REPEAT ON', style: AppTextStyles.label),
        const SizedBox(height: 12),
        Row(
          children: List.generate(7, (index) {
            final day = index + 1; // 1=월, 7=일
            final isSelected = _selectedDays.contains(day);

            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedDays.remove(day);
                    } else {
                      _selectedDays.add(day);
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: EdgeInsets.only(right: index < 6 ? 8 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _dayLabels[index],
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildHolidaySwitch() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.celebration, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '공휴일 제외',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  '공휴일에는 알람이 울리지 않아요',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _excludeHolidays,
            onChanged: (value) => setState(() => _excludeHolidays = value),
            activeThumbColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildDeadlineTimePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Text('DEADLINE TIME', style: AppTextStyles.label),
            SizedBox(width: 8),
            Text('⏰'),
          ],
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _selectDeadlineTime,
          child: Container(
            padding: const EdgeInsets.all(16),
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
            child: Row(
              children: [
                const Icon(Icons.access_time, color: AppColors.primary),
                const SizedBox(width: 12),
                Text(
                  _deadlineTime.format(context),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.arrow_drop_down, color: AppColors.textLight),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReminderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Text('REMINDER BEFORE', style: AppTextStyles.label),
            SizedBox(width: 8),
            Text('🔔'),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.notifications_active, color: AppColors.primary),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      '리마인더 알람',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  Switch(
                    value: _reminderEnabled,
                    onChanged: (value) => setState(() => _reminderEnabled = value),
                    activeThumbColor: AppColors.primary,
                  ),
                ],
              ),
              if (_reminderEnabled) ...[
                const SizedBox(height: 16),
                Row(
                  children: _reminderOptions.map((minutes) {
                    final isSelected = _reminderMinutes == minutes;
                    final label = minutes < 60
                        ? '$minutes분 전'
                        : '${minutes ~/ 60}시간 전';

                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _reminderMinutes = minutes),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              label,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCharacterSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.people, size: 16, color: AppColors.textSecondary),
            SizedBox(width: 8),
            Text('NAGGING CHARACTER', style: AppTextStyles.label),
          ],
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 2.2,
          children: CharacterType.values.map((character) {
            return CharacterChip(
              character: character,
              isSelected: _selectedCharacter == character,
              onTap: () => setState(() => _selectedCharacter = character),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(bool isEditing) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitGoal,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isEditing ? '수정하기' : 'Create Goal',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('🎯'),
                ],
              ),
      ),
    );
  }

  Future<void> _selectDeadlineTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _deadlineTime,
    );
    if (picked != null) {
      setState(() => _deadlineTime = picked);
    }
  }

  Future<void> _validateGithubUsername() async {
    final username = _githubUsernameController.text.trim();
    if (username.isEmpty) return;

    setState(() {
      _isValidatingGithub = true;
      _githubValidationError = null;
    });

    final exists = await _githubService.checkUserExists(username);

    setState(() {
      _isValidatingGithub = false;
      if (!exists) {
        _githubValidationError = '존재하지 않는 GitHub 사용자입니다';
      }
    });

    if (exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ GitHub 사용자가 확인되었습니다'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  Future<void> _submitGoal() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('반복할 요일을 선택해주세요')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final deadlineStr =
          '${_deadlineTime.hour.toString().padLeft(2, '0')}:${_deadlineTime.minute.toString().padLeft(2, '0')}';

      final goal = Goal(
        id: widget.existingGoal?.id,
        title: _titleController.text.trim(),
        type: _goalType,
        githubUsername:
            _goalType == GoalType.github ? _githubUsernameController.text.trim() : null,
        repeatDays: _selectedDays..sort(),
        excludeHolidays: _excludeHolidays,
        deadlineTime: deadlineStr,
        reminderEnabled: _reminderEnabled,
        reminderMinutesBefore: _reminderMinutes,
        character: _selectedCharacter,
      );

      final provider = context.read<GoalProvider>();
      if (widget.existingGoal != null) {
        await provider.updateGoal(goal);
      } else {
        await provider.addGoal(goal);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.existingGoal != null ? '목표가 수정되었습니다' : '목표가 추가되었습니다'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류가 발생했습니다: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
