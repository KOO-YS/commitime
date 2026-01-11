import 'package:flutter/material.dart';

/// GitHub 컬러 스케일 (커밋 그래프 색상)
class AppColors {
  // GitHub Contribution Colors
  static const Color level0 = Color(0xFFEBEDF0); // Empty
  static const Color level1 = Color(0xFFC6E48B); // Light
  static const Color level2 = Color(0xFF7BC96F); // Medium
  static const Color level3 = Color(0xFF239A3B); // Strong
  static const Color level4 = Color(0xFF196127); // Full

  // Primary Colors
  static const Color primary = Color(0xFF239A3B);
  static const Color primaryLight = Color(0xFF7BC96F);
  static const Color primaryDark = Color(0xFF196127);

  // Background Colors
  static const Color background = Color(0xFFFFFEF9);
  static const Color cardBackground = Colors.white;
  static const Color surfaceLight = Color(0xFFF5F5F5);

  // Character Card Colors
  static const Color professorCard = Color(0xFFFFD6E8);
  static const Color momCard = Color(0xFFFFE4B5);
  static const Color friendCard = Color(0xFFB5E3FF);
  static const Color drillCard = Color(0xFFE0E0E0);

  // Text Colors
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textLight = Color(0xFF9CA3AF);

  // Status Colors
  static const Color success = Color(0xFF239A3B);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFEF4444);

  /// 레벨에 따른 색상 반환
  static Color getColorByLevel(int level) {
    switch (level) {
      case 0:
        return level0;
      case 1:
        return level1;
      case 2:
        return level2;
      case 3:
        return level3;
      case 4:
        return level4;
      default:
        return level0;
    }
  }

  /// 캐릭터별 카드 색상 반환
  static Color getCharacterColor(String character) {
    switch (character.toLowerCase()) {
      case 'professor':
        return professorCard;
      case 'mom':
        return momCard;
      case 'friend':
        return friendCard;
      case 'drill':
        return drillCard;
      default:
        return professorCard;
    }
  }
}

/// 앱 텍스트 스타일
class AppTextStyles {
  static const TextStyle heading1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle heading3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textLight,
  );

  static const TextStyle label = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    letterSpacing: 0.5,
  );
}

/// 앱 테마
class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        background: AppColors.background,
      ),
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.heading2,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardBackground,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: AppColors.primaryLight, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );
  }
}
