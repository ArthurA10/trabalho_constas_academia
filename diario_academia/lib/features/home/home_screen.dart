import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
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
        title: const Text('Solid Workout'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
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
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          // 1. Banner de Treino em Andamento
          if (workoutSession.isRunning)
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primary, width: 1.5),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.timer_outlined, color: AppTheme.primary),
                ),
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
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

          // 2. Botão de Iniciar Treino
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            child: Ink(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primary, AppTheme.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  if (!workoutSession.isRunning) {
                    ref.read(activeWorkoutSessionProvider.notifier).startFreeWorkout();
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const FreeWorkoutScreen()),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: const BoxDecoration(
                          color: Color(0x33FFFFFF),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 34),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Iniciar Treino Livre',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Adicione exercícios e registre suas séries',
                              style: TextStyle(fontSize: 13, color: Color(0xCCFFFFFF)),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 28),
          const Text('Resumo de Atividade', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),

          // 3. Resumo com proteção de altura fixa durante o carregamento
          Row(
            children: [
              Expanded(
                child: historyAsync.when(
                  data: (workouts) => _buildSummaryCard(context, 'Treinos', '${workouts.length}', Icons.fitness_center, AppTheme.primary),
                  loading: () => const SizedBox(height: 120, child: Center(child: CircularProgressIndicator())),
                  error: (_, __) => _buildSummaryCard(context, 'Treinos', '0', Icons.fitness_center, AppTheme.primary),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: volumeAsync.when(
                  data: (volume) => _buildSummaryCard(context, 'Volume (kg)', volume.toStringAsFixed(0), Icons.monitor_weight_outlined, AppTheme.success),
                  loading: () => const SizedBox(height: 120, child: Center(child: CircularProgressIndicator())),
                  error: (_, __) => _buildSummaryCard(context, 'Volume', '0', Icons.monitor_weight_outlined, AppTheme.success),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, String title, String value, IconData icon, Color accent) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Garante que não tente expandir ao infinito
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 22, color: accent),
            ),
            const SizedBox(height: 14),
            Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(title, style: TextStyle(color: Colors.grey.shade400)),
          ],
        ),
      ),
    );
  }
}