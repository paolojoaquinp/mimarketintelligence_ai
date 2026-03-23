import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:miestudiomarket_ai_app/core/utils/splash_screen.dart';
import 'package:rive/rive.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'shared/widgets/app_shell/app_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RiveNative.init();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MiEstudioMarketApp());
}

class MiEstudioMarketApp extends StatelessWidget {
  const MiEstudioMarketApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const SplashScreen(),
    );
  }
}
