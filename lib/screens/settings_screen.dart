import 'package:flutter/material.dart';
import '../widgets/clover_logo.dart';
import '../services/notification_service.dart';
import '../utils/constants.dart';

/// 설정 화면
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _isLoggedIn = false;
  String? _githubUsername;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildProfileSection(),
              const SizedBox(height: 24),
              _buildQuickSettings(),
              const SizedBox(height: 24),
              _buildIntegrations(),
              const SizedBox(height: 24),
              _buildOtherSettings(),
              const SizedBox(height: 24),
              if (_isLoggedIn) _buildLogoutButton(),
              const SizedBox(height: 20),
              _buildPixelDecoration(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Settings',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Manage your preferences',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
        const CloverLogo(size: 40),
      ],
    );
  }

  Widget _buildProfileSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryLight, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Center(
                  child: Text('👤', style: TextStyle(fontSize: 32)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isLoggedIn ? 'User Name' : '로그인하기',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isLoggedIn
                          ? 'user@email.com'
                          : '로그인하고 데이터를 동기화하세요',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.white.withOpacity(0.6),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 프로그레스 바 (장식용)
          Row(
            children: List.generate(5, (i) {
              return Expanded(
                child: Container(
                  height: 8,
                  margin: EdgeInsets.only(right: i < 4 ? 6 : 0),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(i < 3 ? 0.4 : 0.2),
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

  Widget _buildQuickSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('QUICK SETTINGS', style: AppTextStyles.label),
        const SizedBox(height: 12),
        Container(
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
              _buildSettingToggle(
                icon: Icons.notifications,
                iconColor: AppColors.primary,
                title: 'Notifications',
                subtitle: 'Enable reminders',
                value: _notificationsEnabled,
                onChanged: (value) async {
                  if (value) {
                    final granted = await NotificationService().requestPermissions();
                    if (granted) {
                      setState(() => _notificationsEnabled = true);
                    } else {
                      _showPermissionDeniedDialog();
                    }
                  } else {
                    setState(() => _notificationsEnabled = false);
                  }
                },
              ),
              const Divider(height: 1),
              _buildSettingToggle(
                icon: Icons.volume_up,
                iconColor: AppColors.primary,
                title: 'Sound',
                subtitle: 'Alarm sounds',
                value: _soundEnabled,
                onChanged: (value) => setState(() => _soundEnabled = value),
              ),
              const Divider(height: 1),
              _buildSettingToggle(
                icon: Icons.dark_mode,
                iconColor: AppColors.textLight,
                title: 'Dark Mode',
                subtitle: 'Coming soon',
                value: false,
                onChanged: null,
                disabled: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // 알림 테스트 버튼들
        _buildNotificationTestSection(),
      ],
    );
  }

  Widget _buildNotificationTestSection() {
    return Column(
      children: [
        // 즉시 알림 테스트
        _buildTestButton(
          icon: Icons.notifications_active,
          title: '즉시 알림 테스트',
          subtitle: '탭하면 바로 알림이 옵니다',
          onTap: _testInstantNotification,
        ),
        const SizedBox(height: 12),
        // 1분 후 예약 알림 테스트
        _buildTestButton(
          icon: Icons.alarm,
          title: '1분 후 예약 알림 테스트',
          subtitle: '앱을 닫아도 1분 후 알림이 옵니다',
          onTap: _testScheduledNotification,
          isScheduled: true,
        ),
      ],
    );
  }

  Widget _buildTestButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isScheduled = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isScheduled
              ? Colors.orange.withOpacity(0.1)
              : AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isScheduled
                ? Colors.orange.withOpacity(0.3)
                : AppColors.primary.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isScheduled ? Colors.orange : AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: AppColors.textLight),
                  ),
                ],
              ),
            ),
            Icon(
              isScheduled ? Icons.schedule_send : Icons.send,
              color: isScheduled ? Colors.orange : AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _testInstantNotification() async {
    final notificationService = NotificationService();

    await notificationService.showInstantNotification(
      title: '🎯 Commitime 테스트',
      body: '알림이 정상적으로 작동합니다! 목표를 향해 달려가세요!',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('테스트 알림을 발송했습니다! 상단 알림창을 확인하세요.'),
          backgroundColor: AppColors.primary,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _testScheduledNotification() async {
    final notificationService = NotificationService();

    await notificationService.scheduleTestNotification(
      minutesFromNow: 1,
      title: '⏰ 예약 알림 테스트',
      body: '이 알림은 1분 후에 예약되었습니다. 앱을 닫아도 알림이 옵니다!',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('1분 후 알림이 예약되었습니다! 앱을 닫고 기다려보세요.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  Widget _buildSettingToggle({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool)? onChanged,
    bool disabled = false,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: disabled ? AppColors.textLight : AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: disabled ? null : onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildIntegrations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('INTEGRATIONS', style: AppTextStyles.label),
        const SizedBox(height: 12),
        _buildIntegrationItem(
          icon: Icons.code,
          iconBgColor: Colors.grey.shade900,
          iconColor: Colors.white,
          title: 'GitHub Account',
          subtitle: _githubUsername != null ? 'Connected' : 'Not connected',
          isConnected: _githubUsername != null,
          onTap: _showGitHubDialog,
        ),
      ],
    );
  }

  Widget _buildIntegrationItem({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isConnected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isConnected ? AppColors.primary : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            if (isConnected)
              Row(
                children: [
                  ...List.generate(3, (i) {
                    return Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  }),
                ],
              ),
            const Icon(Icons.chevron_right, color: AppColors.textLight),
          ],
        ),
      ),
    );
  }

  Widget _buildOtherSettings() {
    final items = [
      {'label': 'About Commitime', 'sublabel': 'Version 1.0.0'},
      {'label': 'Privacy Policy', 'sublabel': 'How we protect your data'},
      {'label': 'Terms of Service', 'sublabel': 'Legal information'},
      {'label': 'Help & Support', 'sublabel': 'Get help'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('OTHER', style: AppTextStyles.label),
        const SizedBox(height: 12),
        Container(
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
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Column(
                children: [
                  ListTile(
                    title: Text(
                      item['label']!,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      item['sublabel']!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: AppColors.textLight,
                    ),
                    onTap: () {
                      // TODO: 각 설정 페이지로 이동
                    },
                  ),
                  if (index < items.length - 1) const Divider(height: 1),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: _showLogoutDialog,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.red.shade100),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, color: Colors.red.shade400),
            const SizedBox(width: 8),
            Text(
              'Log Out',
              style: TextStyle(
                color: Colors.red.shade400,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPixelDecoration() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        return Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: AppColors.getColorByLevel(4 - i),
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('알림 권한 필요'),
        content: const Text('목표 알림을 받으려면 알림 권한이 필요합니다.\n설정에서 권한을 허용해주세요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _showGitHubDialog() {
    final controller = TextEditingController(text: _githubUsername);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('GitHub 연결'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'GitHub Username',
            hintText: 'your-username',
            prefixIcon: Icon(Icons.alternate_email),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _githubUsername = controller.text.trim());
              Navigator.pop(context);
            },
            child: const Text('연결'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('정말 로그아웃 하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _isLoggedIn = false);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
            ),
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );
  }
}
