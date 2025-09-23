import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:project_radar_app/notification/notification_service.dart';

class NotificationBadge extends StatelessWidget {
  /// Optional: pass your own listenable. If null, falls back to NotificationService.unreadCount
  final ValueListenable<int>? countListenable;
  final double size;
  final Color color;
  final Color textColor;
  final bool showZero;

  const NotificationBadge({
    Key? key,
    this.countListenable,
    this.size = 20,
    this.color = Colors.red,
    this.textColor = Colors.white,
    this.showZero = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Ensure a non-null ValueListenable<int> is passed to ValueListenableBuilder
    final ValueListenable<int> listenable = countListenable ?? NotificationService.unreadCount;

    return ValueListenableBuilder<int>(
      valueListenable: listenable,
      builder: (context, val, _) {
        if (val <= 0 && !showZero) return const SizedBox.shrink();
        final display = val > 99 ? '99+' : val.toString();
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))],
          ),
          child: Center(
            child: Text(
              display,
              style: TextStyle(color: textColor, fontSize: size * 0.5, fontWeight: FontWeight.bold),
            ),
          ),
        );
      },
    );
  }
}
