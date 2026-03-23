import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class AgentLoadingDots extends StatelessWidget {
  const AgentLoadingDots({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: SizedBox(
        // color: Colors.red,
        height: 100, // Height matching the chat bubble sizes roughly
        child: Lottie.asset('assets/lotties/loading-dots.json'),
      ),
    );
  }
}
