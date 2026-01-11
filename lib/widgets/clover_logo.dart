import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// 픽셀 도트 스타일의 네잎클로버 로고
class CloverLogo extends StatelessWidget {
  final double size;

  const CloverLogo({
    super.key,
    this.size = 60,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _CloverPainter(),
    );
  }
}

class _CloverPainter extends CustomPainter {
  // 픽셀 데이터: {x, y, level}
  // level: 1=연한 녹색, 2=중간, 3=진한, 4=가장 진한
  final List<Map<String, int>> _pixels = [
    // 위쪽 잎
    {'x': 4, 'y': 1, 'level': 2},
    {'x': 5, 'y': 1, 'level': 2},
    {'x': 3, 'y': 2, 'level': 3},
    {'x': 4, 'y': 2, 'level': 4},
    {'x': 5, 'y': 2, 'level': 4},
    {'x': 6, 'y': 2, 'level': 3},
    {'x': 4, 'y': 3, 'level': 3},
    {'x': 5, 'y': 3, 'level': 3},

    // 왼쪽 잎
    {'x': 1, 'y': 4, 'level': 2},
    {'x': 1, 'y': 5, 'level': 2},
    {'x': 2, 'y': 3, 'level': 3},
    {'x': 2, 'y': 4, 'level': 4},
    {'x': 2, 'y': 5, 'level': 4},
    {'x': 2, 'y': 6, 'level': 3},
    {'x': 3, 'y': 4, 'level': 3},
    {'x': 3, 'y': 5, 'level': 3},

    // 오른쪽 잎
    {'x': 8, 'y': 4, 'level': 2},
    {'x': 8, 'y': 5, 'level': 2},
    {'x': 7, 'y': 3, 'level': 3},
    {'x': 7, 'y': 4, 'level': 4},
    {'x': 7, 'y': 5, 'level': 4},
    {'x': 7, 'y': 6, 'level': 3},
    {'x': 6, 'y': 4, 'level': 3},
    {'x': 6, 'y': 5, 'level': 3},

    // 아래쪽 잎
    {'x': 4, 'y': 8, 'level': 2},
    {'x': 5, 'y': 8, 'level': 2},
    {'x': 3, 'y': 7, 'level': 3},
    {'x': 4, 'y': 7, 'level': 4},
    {'x': 5, 'y': 7, 'level': 4},
    {'x': 6, 'y': 7, 'level': 3},
    {'x': 4, 'y': 6, 'level': 3},
    {'x': 5, 'y': 6, 'level': 3},

    // 중앙
    {'x': 4, 'y': 4, 'level': 4},
    {'x': 5, 'y': 4, 'level': 4},
    {'x': 4, 'y': 5, 'level': 4},
    {'x': 5, 'y': 5, 'level': 4},
  ];

  Color _getColor(int level) {
    switch (level) {
      case 1:
        return AppColors.level1;
      case 2:
        return AppColors.level2;
      case 3:
        return AppColors.level3;
      case 4:
        return AppColors.level4;
      default:
        return AppColors.level0;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final pixelSize = size.width / 10;
    final gap = pixelSize * 0.1;
    final actualSize = pixelSize - gap;
    final radius = Radius.circular(pixelSize * 0.1);

    for (final pixel in _pixels) {
      final paint = Paint()
        ..color = _getColor(pixel['level']!)
        ..style = PaintingStyle.fill;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          pixel['x']! * pixelSize,
          pixel['y']! * pixelSize,
          actualSize,
          actualSize,
        ),
        radius,
      );

      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 애니메이션 클로버 로고 (스플래시용)
class AnimatedCloverLogo extends StatefulWidget {
  final double size;
  final Duration duration;

  const AnimatedCloverLogo({
    super.key,
    this.size = 120,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<AnimatedCloverLogo> createState() => _AnimatedCloverLogoState();
}

class _AnimatedCloverLogoState extends State<AnimatedCloverLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _rotateAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeInOut),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _rotateAnimation.value * 0.1,
            child: CloverLogo(size: widget.size),
          ),
        );
      },
    );
  }
}
