import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:project_radar_app/notification/notification_service.dart';

class NotificationBadge extends StatelessWidget {
  /// Optional: pass your own listenable. If null, falls back to NotificationService instance
  final ValueListenable<int>? countListenable;
  final double size;
  final Color color;
  final Color textColor;
  final bool showZero;
  final bool showAnimation;
  final Duration animationDuration;
  final Widget? child;
  final Alignment alignment;
  final EdgeInsets margin;

  const NotificationBadge({
    Key? key,
    this.countListenable,
    this.size = 20,
    this.color = Colors.red,
    this.textColor = Colors.white,
    this.showZero = false,
    this.showAnimation = true,
    this.animationDuration = const Duration(milliseconds: 300),
    this.child,
    this.alignment = Alignment.topRight,
    this.margin = EdgeInsets.zero,
  }) : super(key: key);

  /// A small badge that shows just a dot when there are notifications
  const NotificationBadge.smallDot({
    Key? key,
    this.countListenable,
    this.size = 12,
    this.color = Colors.red,
    this.textColor = Colors.white,
    this.showZero = false,
    this.showAnimation = true,
    this.animationDuration = const Duration(milliseconds: 300),
    this.child,
    this.alignment = Alignment.topRight,
    this.margin = EdgeInsets.zero,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ValueListenable<int> listenable = countListenable ?? NotificationService().unreadCount;

    return ValueListenableBuilder<int>(
      valueListenable: listenable,
      builder: (context, count, _) {
        final hasNotifications = count > 0 || showZero;
        
        if (!hasNotifications && child == null) return const SizedBox.shrink();
        if (!hasNotifications) return child ?? const SizedBox.shrink();

        final displayText = count > 99 ? '99+' : count.toString();
        
        Widget badge = Container(
          width: size,
          height: size,
          constraints: BoxConstraints(minWidth: size, minHeight: size),
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
          child: count > 0 ? Center(
            child: Text(
              displayText,
              style: TextStyle(
                color: textColor,
                fontSize: size * 0.5,
                fontWeight: FontWeight.bold,
                height: 1.0,
              ),
              textAlign: TextAlign.center,
            ),
          ) : null,
        );

        if (showAnimation && count > 0) {
          badge = AnimatedContainer(
            duration: animationDuration,
            curve: Curves.easeInOut,
            width: size,
            height: size,
            child: badge,
          );
        }

        if (child != null) {
          return Stack(
            clipBehavior: Clip.none,
            children: [
              child!,
              Positioned(
                right: margin.right,
                top: margin.top,
                child: badge,
              ),
            ],
          );
        }

        return badge;
      },
    );
  }
}