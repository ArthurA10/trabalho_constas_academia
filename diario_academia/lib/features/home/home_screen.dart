import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_providers.dart';
import '../../ui/active_workout/free_workout_screen.dart';
import '../../providers/active_workout_session_provider.dart';
import '../../ui/active_workout/active_workout_screen.dart';
import '../../ui/settings/settings_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyProvider);
    final volumeAsync = ref.watch(volumeProvider);
    final workoutSession = ref.watch(activeWorkoutSessionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Diário de Academia'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),

      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // 1. Banner de Treino em Andamento
          if (workoutSession.isRunning)
            Card(
              color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
              ),
              margin: const EdgeInsets.only(bottom: 24),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: ListTile(
                  leading: Icon(Icons.timer, color: Theme.of(context).colorScheme.primary, size: 32),
                  title: const Text(
                    'Treino em Andamento',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(workoutSession.title),
                  trailing: TextButton(
                    onPressed: () {
                      if (workoutSession.type == 'livre') {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const FreeWorkoutScreen()));
                      } else if (workoutSession.routine != null) {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => ActiveWorkoutScreen(routine: workoutSession.routine!)));
                      }
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                    child: const Text('Continuar'),
                  ),
                  // Colocamos a opção de descartar no clique longo para economizar espaço de layout
                  onLongPress: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Descartar Treino?'),
                        content: const Text('Isso apagará o progresso do treino atual.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                          TextButton(
                            onPressed: () {
                              ref.read(activeWorkoutSessionProvider.notifier).discardWorkout();
                              Navigator.pop(context);
                            },
                            child: const Text('Descartar', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),

          // 2. Botão de Iniciar Treino
          ElevatedButton.icon(
            onPressed: () {
              if (!workoutSession.isRunning) {
                ref.read(activeWorkoutSessionProvider.notifier).startFreeWorkout();
              }
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FreeWorkoutScreen()),
              );
            },
            icon: const Icon(Icons.play_arrow),
            label: const Text('Iniciar Treino Livre', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
              padding: const EdgeInsets.symmetric(vertical: 24),
            ),
          ),
          
          const SizedBox(height: 32),
          const Text('Resumo de Atividade', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          
          // 3. Resumo com proteção de altura fixa durante o carregamento
          Row(
            children: [
              Expanded(
                child: historyAsync.when(
                  data: (workouts) => _buildSummaryCard(context, 'Treinos', '${workouts.length}', Icons.fitness_center),
                  loading: () => const SizedBox(height: 120, child: Center(child: CircularProgressIndicator())),
                  error: (_, __) => _buildSummaryCard(context, 'Treinos', '0', Icons.fitness_center),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: volumeAsync.when(
                  data: (volume) => _buildSummaryCard(context, 'Volume (kg)', volume.toStringAsFixed(0), Icons.monitor_weight),
                  loading: () => const SizedBox(height: 120, child: Center(child: CircularProgressIndicator())),
                  error: (_, __) => _buildSummaryCard(context, 'Volume', '0', Icons.monitor_weight),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, String title, String value, IconData icon) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Garante que não tente expandir ao infinito
          children: [
            Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(title, style: TextStyle(color: Colors.grey.shade400)),
          ],
        ),
      ),
    );
  }
}