
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:interview_coach/core/widgets/exit_app_dialog.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'features/profile/presentation/controllers/theme_controller.dart';
import 'features/splash/presentation/pages/splash_page.dart';


final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
class InterviewCoachApp extends StatefulWidget {
  const InterviewCoachApp({super.key});

  @override
  State<InterviewCoachApp> createState() => _InterviewCoachAppState();
}

class _InterviewCoachAppState extends State<InterviewCoachApp>
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
  Future<bool> didPopRoute() async {
    final navigator = rootNavigatorKey.currentState;
    if (navigator == null) return false;

    // 1. If any screen, dialog, modal, or bottom sheet is present above the root,
    // let Navigator pop it normally.
    final popped = await navigator.maybePop();
    if (popped) {
      return true; // Successfully popped a pushed route or dialog
    }

    // 2. If nothing was popped, there is NO screen left in the stack.
    // Instead of exiting the app abruptly, prompt the user with the confirmation dialogue.
    final context = rootNavigatorKey.currentContext;
    if (context != null) {
      final shouldExit = await ExitAppDialog.show(context);
      if (shouldExit == true) {
        await SystemNavigator.pop();
      }
      return true; // Handled, prevents sudden app closure
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final themeCtrl = context.watch<ThemeController>();

    return MaterialApp(
      navigatorKey: rootNavigatorKey,
      title: 'Interview Coach',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeCtrl.flutterThemeMode,
      home: const SplashPage(),
    );
  }
}
