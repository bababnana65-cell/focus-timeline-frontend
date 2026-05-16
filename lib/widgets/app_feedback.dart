import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum AppSnackBarTone {
  info,
  success,
  warning,
  error,
}

Future<bool> showAppConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = '确认',
  String cancelLabel = '取消',
  bool destructive = false,
}) async {
  return await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
                child: Text(cancelLabel),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: destructive ? AppTheme.danger : null,
                ),
                child: Text(confirmLabel),
              ),
            ],
          );
        },
      ) ??
      false;
}

Future<String?> showAppTextInputDialog(
  BuildContext context, {
  required String title,
  required String hintText,
  String confirmLabel = '确定',
  String cancelLabel = '取消',
  String initialValue = '',
}) async {
  final controller = TextEditingController(text: initialValue);
  final value = await showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: hintText,
          ),
          onSubmitted: (value) {
            Navigator.of(context).pop(value);
          },
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(cancelLabel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop(controller.text);
            },
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );
  controller.dispose();
  return value;
}

void showAppSnackBar(
  BuildContext context,
  String message, {
  AppSnackBarTone tone = AppSnackBarTone.info,
}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) {
    return;
  }

  final (backgroundColor, foregroundColor, icon) = switch (tone) {
    AppSnackBarTone.info => (
        AppTheme.surface,
        AppTheme.textPrimary,
        Icons.info_outline_rounded
      ),
    AppSnackBarTone.success => (
        AppTheme.surface,
        AppTheme.mintDeep,
        Icons.check_circle_outline_rounded
      ),
    AppSnackBarTone.warning => (
        AppTheme.surface,
        AppTheme.textPrimary,
        Icons.warning_amber_rounded
      ),
    AppSnackBarTone.error => (
        AppTheme.surface,
        AppTheme.danger,
        Icons.error_outline_rounded
      ),
  };
  final iconColor = switch (tone) {
    AppSnackBarTone.info => AppTheme.lavender,
    AppSnackBarTone.success => AppTheme.mintDeep,
    AppSnackBarTone.warning => AppTheme.lavender,
    AppSnackBarTone.error => AppTheme.danger,
  };
  final isHighPriority =
      tone == AppSnackBarTone.warning || tone == AppSnackBarTone.error;

  messenger.showSnackBar(
    SnackBar(
      duration: Duration(milliseconds: isHighPriority ? 2600 : 1400),
      backgroundColor: backgroundColor,
      behavior: SnackBarBehavior.floating,
      elevation: 3,
      margin: const EdgeInsets.fromLTRB(44, 0, 44, 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: tone == AppSnackBarTone.warning
              ? AppTheme.accent.withValues(alpha: 0.16)
              : AppTheme.border,
        ),
      ),
      showCloseIcon: isHighPriority,
      closeIconColor: foregroundColor,
      content: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, color: iconColor, size: 17),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              message,
              maxLines: isHighPriority ? 2 : 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: foregroundColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
