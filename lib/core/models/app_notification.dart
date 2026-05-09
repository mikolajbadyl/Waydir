import 'package:flutter/material.dart';

enum NotificationType { autoDismiss, persistent }

class NotificationAction {
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final bool dismissOnTap;

  const NotificationAction({
    required this.label,
    required this.onTap,
    this.color,
    this.dismissOnTap = true,
  });
}

class AppNotification {
  final String id;
  final String? title;
  final String message;
  final NotificationType type;
  final Duration autoDismissDuration;
  final List<NotificationAction> actions;
  final IconData? icon;
  final Color? accentColor;
  final DateTime timestamp;

  AppNotification({
    this.id = '',
    this.title,
    required this.message,
    this.type = NotificationType.autoDismiss,
    this.autoDismissDuration = const Duration(seconds: 4),
    this.actions = const [],
    this.icon,
    this.accentColor,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}
