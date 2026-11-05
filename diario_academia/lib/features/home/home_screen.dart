import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_providers.dart';
import '../../ui/active_workout/free_workout_screen.dart';
import '../../providers/active_workout_session_provider.dart';
import '../../ui/active_workout/active_workout_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyProvider);
    final volumeAsync = ref.watch(volumeProvider);
    // 1. Escuta o provedor global do treino ativo
    final workoutSession = ref.watch(activeWorkoutSessionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Diário de Academia'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, // Estica os botões horizontalmente
          children: [
            // 2. Janela (Banner) que aparece apenas se houver um treino em andamento
            if (workoutSession.isRunning)
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Treino em Andamento',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      workoutSession.title,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            ref.read(activeWorkoutSessionProvider.notifier).discardWorkout();
                          },
                          child: const Text('Descartar', style: TextStyle(color: Colors.redAccent)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                  if (workoutSession.type == 'livre') {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const FreeWorkoutScreen()));
                  } else {
                    // Se for rotina, abre passando a rotina armazenada na memória!
                    Navigator.push(context, MaterialPageRoute(builder: (context) => ActiveWorkoutScreen(routine: workoutSession.routine!)));
                  }
                },
                          child: const Text('Continuar'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            // 3. Botão de iniciar treino atualizado para ativar a sessão
            ElevatedButton.icon(
              onPressed: () {
                // Registra o início da sessão para o banner aparecer caso o usuário saia da tela
                ref.read(activeWorkoutSessionProvider.notifier).startFreeWorkout();
                
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
            Row(
              children: [
                Expanded(
                  child: historyAsync.when(
                    data: (workouts) => _buildSummaryCard(context, 'Treinos', '${workouts.length}', Icons.fitness_center),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (_, __) => _buildSummaryCard(context, 'Treinos', '0', Icons.fitness_center),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: volumeAsync.when(
                    data: (volume) => _buildSummaryCard(context, 'Volume (kg)', volume.toStringAsFixed(0), Icons.monitor_weight),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (_, __) => _buildSummaryCard(context, 'Volume', '0', Icons.monitor_weight),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, String title, String value, IconData icon) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
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