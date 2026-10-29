import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/shell/main_screen.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Obrigatório antes de inicializar serviços nativos
  await NotificationService().init(); // Inicializa as notificações
  runApp(const ProviderScope(child: DiarioAcademiaApp()));
}

class DiarioAcademiaApp extends StatelessWidget {
  const DiarioAcademiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Diário de Academia',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueAccent,
          brightness: Brightness.dark, // Modo escuro
        ),
        useMaterial3: true,
      ),
      // Aponta para o ecrã principal que contém as abas (BottomNavigationBar)
      home: const MainScreen(), 
    );
  }
}