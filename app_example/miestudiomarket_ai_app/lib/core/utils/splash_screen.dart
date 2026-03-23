import 'package:flutter/material.dart';
import 'package:miestudiomarket_ai_app/shared/widgets/app_shell/app_shell.dart';
import 'package:rive/rive.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late File file;
  late RiveWidgetController controller;
  bool isInitialized = false;

  final ValueNotifier<bool> _isTimeElapsed = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    initRive();
    _startTimer();
  }

  void initRive() async {
    file = (await File.asset("assets/rives/chatbot.riv", riveFactory: Factory.rive))!;
    controller = RiveWidgetController(file);
    if (mounted) {
      setState(() => isInitialized = true);
    }
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _isTimeElapsed.value = true;
      }
    });
  }

  @override
  void dispose() {
    file.dispose();
    controller.dispose();
    _isTimeElapsed.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _isTimeElapsed,
      builder: (context, isTimeElapsed, child) {
        if (isTimeElapsed) {
          Future.microtask(() {
            if (!context.mounted) return;
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                transitionDuration: const Duration(milliseconds: 800),
                pageBuilder: (_, __, ___) => const AppShell(),
                transitionsBuilder: (_, animation, __, child) {
                  return FadeTransition(
                    opacity: animation,
                    child: child,
                  );
                },
              ),
            );
          });
        }

        return Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: SizedBox(
              width: 400,
              height: 400,
              child: !isInitialized
                  ? const Center(child: CircularProgressIndicator())
                  : RiveWidget(
                      controller: controller,
                      fit: Fit.cover,
                    ),
            ),
          ),
        );
      },
    );
  }
}