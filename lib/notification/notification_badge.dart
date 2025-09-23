import 'package:flutter/material.dart';

class NotificationBadge extends StatelessWidget {
  final int count;
  final double size;
  final Color color;
  final Color textColor;
  final bool showZero;

  const NotificationBadge({
    super.key,
    required this.count,
    this.size = 20,
    this.color = Colors.red,
    this.textColor = Colors.white,
    this.showZero = false,
  });

  @override
  Widget build(BuildContext context) {
    if (count <= 0 && !showZero) return const SizedBox.shrink();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          count > 99 ? '99+' : count.toString(),
          style: TextStyle(
            color: textColor,
            fontSize: size * 0.5,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}