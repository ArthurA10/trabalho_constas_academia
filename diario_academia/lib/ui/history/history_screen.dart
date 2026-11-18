import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_providers.dart';
import 'workout_detail_screen.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  static const List<String> _meses = [
    'JAN', 'FEV', 'MAR', 'ABR', 'MAI', 'JUN',
    'JUL', 'AGO', 'SET', 'OUT', 'NOV', 'DEZ',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ref.watch faz com que o ecrã atualize quando novos treinos forem guardados
    final historyAsync = ref.watch(historyProvider);
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(historyProvider), // Força a atualização da lista
          )
        ],
      ),
      body: historyAsync.when(
        data: (workouts) {
          if (workouts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey.shade700),
                  const SizedBox(height: 16),
                  const Text('Nenhum treino finalizado ainda.', style: TextStyle(fontSize: 16)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 24),
            itemCount: workouts.length,
            itemBuilder: (context, index) {
              final workout = workouts[index];
              final end = workout.endTime;
              final durationText = end != null
                  ? '  •  ${end.difference(workout.startTime).inMinutes} min'
                  : '';
              return Dismissible(
                key: Key(workout.id.toString()),
                direction: DismissDirection.endToStart,
                background: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade700,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (direction) async {
                  await ref.read(databaseRepositoryProvider).deleteWorkout(workout.id!);
                  ref.invalidate(historyProvider);
                  ref.invalidate(volumeProvider);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Treino apagado.')));
                  }
                },
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      width: 48,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            workout.startTime.day.toString().padLeft(2, '0'),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, height: 1.1),
                          ),
                          Text(
                            _meses[workout.startTime.month - 1],
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.primary),
                          ),
                        ],
                      ),
                    ),
                    title: Text(workout.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(
                      '${dateFormat.format(workout.startTime)}$durationText',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => WorkoutDetailScreen(workout: workout)),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erro: $err')),
      ),
    );
  }
}