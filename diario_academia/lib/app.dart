import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/shell/main_screen.dart'; // Importamos o MainScreen

class GymDiaryApp extends StatelessWidget {
  const GymDiaryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Diário de Academia',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const MainScreen(), // Aqui deve ser MainScreen, e não HomeScreen
    );
  }
}