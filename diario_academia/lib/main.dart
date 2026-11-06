import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/shell/main_screen.dart';
import 'services/notification_service.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Obrigatório antes de inicializar serviços nativos
  await NotificationService().init(); // Inicializa as notificações

  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            details.exceptionAsString(),
            style: const TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  };

  runApp(const ProviderScope(child: DiarioAcademiaApp()));
}

class DiarioAcademiaApp extends StatelessWidget {
  const DiarioAcademiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Diário de Academia',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      // Aponta para o ecrã principal que contém as abas (BottomNavigationBar)
      home: const MainScreen(), 
    );
  }
}