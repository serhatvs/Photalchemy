import 'package:flutter/material.dart';
import 'package:photalchemy/app/app_shell.dart';

class PhotalchemyApp extends StatelessWidget {
  const PhotalchemyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Photalchemy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF5468FF)),
      ),
      home: const AppShell(),
    );
  }
}
