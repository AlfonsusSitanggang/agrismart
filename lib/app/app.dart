import 'package:flutter/material.dart';
import 'routes.dart';
import 'theme.dart';

class AgriSmartApp extends StatelessWidget {
  const AgriSmartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'AgriSmart',
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
    );
  }
}