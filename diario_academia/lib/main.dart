import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/shell/main_screen.dart';

void main() {
  // O ProviderScope é obrigatório para o Riverpod funcionar e gerir os estados
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
          brightness: Brightness.dark, // Modo escuro (opcional, pode mudar para light)
        ),
        useMaterial3: true,
      ),
      // Aponta para o ecrã principal que contém as abas (BottomNavigationBar)
      home: const MainScreen(), 
    );
  }
}