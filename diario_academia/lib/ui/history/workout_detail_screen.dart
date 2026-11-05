import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/models.dart';
import '../../providers/app_providers.dart';

class WorkoutDetailScreen extends ConsumerWidget {
  final Workout workout;
  const WorkoutDetailScreen({super.key, required this.workout});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(title: Text(workout.name)),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: ref.read(databaseRepositoryProvider).getWorkoutSetsWithExercises(workout.id!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Nenhum dado encontrado para este treino.'));
          }

          final sets = snapshot.data!;
          // Agrupar as séries por nome do exercício
          final Map<String, List<Map<String, dynamic>>> groupedSets = {};
          for (var row in sets) {
            
          // Tenta ler primeiro a "fotografia" do nome (snapshot). 
          // Se for um treino antigo (antes da atualização), usa o fallback do JOIN[cite: 1].
          final exName = (row['exerciseNameSnapshot'] as String?) ?? (row['exerciseName'] as String?) ?? 'Exercício Excluído';
            if (!groupedSets.containsKey(exName)) groupedSets[exName] = [];
            groupedSets[exName]!.add(row);
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Início: ${dateFormat.format(workout.startTime)}', style: const TextStyle(fontSize: 16)),
              if (workout.endTime != null)
                Text('Fim: ${dateFormat.format(workout.endTime!)}', style: const TextStyle(fontSize: 16)),
              const Divider(height: 32),
              ...groupedSets.entries.map((entry) {
                final exName = entry.key;
                final exSets = entry.value;
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(exName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        ...exSets.map((s) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('${s['weight']} kg', style: const TextStyle(fontSize: 16)),
                                  Text('${s['reps']} reps', style: const TextStyle(fontSize: 16)),
                                  Icon(s['isCompleted'] == 1 ? Icons.check_circle : Icons.radio_button_unchecked,
                                      color: s['isCompleted'] == 1 ? Colors.green : Colors.grey, size: 20),
                                ],
                              ),
                            )),
                      ],
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}