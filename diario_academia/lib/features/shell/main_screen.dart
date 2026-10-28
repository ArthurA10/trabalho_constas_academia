import 'package:flutter/material.dart';
import '../home/home_screen.dart';
import '../../ui/routines/routines_screen.dart';
import '../../ui/exercises/exercises_screen.dart';
import '../../ui/history/history_screen.dart';
import '../../ui/reports/reports_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const RoutinesScreen(),
    const ExercisesScreen(),
    const HistoryScreen(), // <- Tela de histórico
    const ReportsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Início'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Treinos'),
          BottomNavigationBarItem(icon: Icon(Icons.fitness_center), label: 'Exercícios'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Histórico'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Relatórios'),
        ],
      ),
    );
  }
}