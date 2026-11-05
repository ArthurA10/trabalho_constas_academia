import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_providers.dart';
import 'create_routine_screen.dart';
import '../active_workout/active_workout_screen.dart';
import '../../providers/active_workout_session_provider.dart';

class RoutinesScreen extends ConsumerWidget {
  const RoutinesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routinesAsync = ref.watch(routinesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Rotinas'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateRoutineScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Nova Rotina'),
      ),
      body: routinesAsync.when(
        data: (routines) {
          if (routines.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.list_alt, size: 64, color: Colors.grey.shade700),
                  const SizedBox(height: 16),
                  const Text('Nenhuma rotina criada.', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 8),
                  Text('Toque em "Nova Rotina" para começar.', style: TextStyle(color: Colors.grey.shade400)),
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: routines.length,
            itemBuilder: (context, index) {
              final routine = routines[index];
              return Dismissible(
                key: Key(routine.id.toString()),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (direction) async {
                  await ref.read(databaseRepositoryProvider).deleteRoutine(routine.id!);
                  ref.invalidate(routinesProvider);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rotina apagada.')));
                  }
                },
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(routine.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      // 1. Busca os exercícios da rotina escolhida
                      final exercises = await ref.read(databaseRepositoryProvider).getExercisesForRoutine(routine.id!);
                      
                      // 2. Avisa a memória global para iniciar a rotina
                      ref.read(activeWorkoutSessionProvider.notifier).startRoutineWorkout(routine, exercises);
                      
                      // 3. Só depois abre a tela de treino
                      if (context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ActiveWorkoutScreen(routine: routine),
                          ),
                        );
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erro ao carregar rotinas: $err')),
      ),
    );
  }
}