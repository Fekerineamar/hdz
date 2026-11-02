import 'package:flutter/material.dart';

import 'core/network/trust_manager.dart';
import 'ui/screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  setupTrustManager();
  runApp(const DzdsAgentApp());
}

class DzdsAgentApp extends StatelessWidget {
  const DzdsAgentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DZDS Agent',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0B5D1E)),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
