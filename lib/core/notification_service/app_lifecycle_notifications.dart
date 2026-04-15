import 'package:flutter/widgets.dart';

import '../config/theme_provider.dart';
import 'notification_service.dart';

/// Shows a local reminder when the app goes to the background (user leaves).
///
/// True "app killed" notifications require a server push (FCM); see
/// `docs/BACKEND_PUSH_NOTIFICATIONS.md`.
class AppLifecycleNotifier extends StatefulWidget {
  final Widget child;

  const AppLifecycleNotifier({super.key, required this.child});

  @override
  State<AppLifecycleNotifier> createState() => _AppLifecycleNotifierState();
}

class _AppLifecycleNotifierState extends State<AppLifecycleNotifier>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      final locale = ThemeProvider.instance.locale;
      FirebaseNotification.showExitReminderIfAllowed(locale);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
