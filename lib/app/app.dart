import 'package:flutter/material.dart';
import 'package:photalchemy/app/app_controller.dart';
import 'package:photalchemy/app/app_shell.dart';

class PhotalchemyApp extends StatelessWidget {
  const PhotalchemyApp({super.key, this.controller});

  final AppController? controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Photalchemy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF5468FF)),
      ),
      home: AppShell(controller: controller),
    );
  }
}
