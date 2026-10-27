import 'dart:async';
import 'package:flutter/material.dart';

import 'scaffold_messenger_key.dart';

/// Zeigt kurze Benachrichtigungen (z.B. "Gespeichert", "PDF wird erstellt…")
/// oben am Bildschirmrand an, statt als SnackBar unten.
///
/// SnackBars am unteren Rand überlagern auf vielen Screens die
/// Speichern-Buttons und blockieren sie für die Dauer der Anzeige. Die
/// Benachrichtigung hier erscheint stattdessen oberhalb des Inhalts und
/// blendet sich nach kurzer Zeit automatisch wieder aus.
class TopNotification {
  TopNotification._();

  static OverlayEntry? _entry;
  static Timer? _timer;

  /// Standarddauer für kurze Bestätigungen (z.B. "… gespeichert").
  static const Duration defaultDuration = Duration(milliseconds: 1600);

  /// Zeigt eine Benachrichtigung oben an.
  /// [duration] == null → bleibt sichtbar, bis [hide] aufgerufen wird
  /// (z.B. für einen Ladehinweis wie "PDF wird erstellt…").
  static void show(
    String message, {
    Color? backgroundColor,
    Color? textColor,
    Duration? duration = defaultDuration,
    Widget? leading,
  }) {
    final context = scaffoldMessengerKey.currentContext;
    if (context == null) return;

    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    _remove();

    final entry = OverlayEntry(
      builder: (_) => _TopNotificationBanner(
        message: message,
        backgroundColor: backgroundColor,
        textColor: textColor,
        leading: leading,
      ),
    );
    _entry = entry;
    overlay.insert(entry);

    if (duration != null) {
      _timer = Timer(duration, _remove);
    }
  }

  /// Blendet eine aktuell sichtbare Benachrichtigung sofort aus.
  static void hide() => _remove();

  static void _remove() {
    _timer?.cancel();
    _timer = null;
    _entry?.remove();
    _entry = null;
  }
}

class _TopNotificationBanner extends StatefulWidget {
  final String message;
  final Color? backgroundColor;
  final Color? textColor;
  final Widget? leading;

  const _TopNotificationBanner({
    required this.message,
    this.backgroundColor,
    this.textColor,
    this.leading,
  });

  @override
  State<_TopNotificationBanner> createState() =>
      _TopNotificationBannerState();
}

class _TopNotificationBannerState extends State<_TopNotificationBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
  )..forward();
  late final Animation<Offset> _offset = Tween<Offset>(
    begin: const Offset(0, -1),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = widget.backgroundColor ?? theme.colorScheme.inverseSurface;
    final fgColor = widget.textColor ??
        (widget.backgroundColor != null
            ? Colors.white
            : theme.colorScheme.onInverseSurface);

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: SlideTransition(
          position: _offset,
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (widget.leading != null) ...[
                    widget.leading!,
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Text(
                      widget.message,
                      style: TextStyle(color: fgColor),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
