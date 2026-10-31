import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/rest_timer_provider.dart';

class RestTimerWidget extends ConsumerWidget {
  const RestTimerWidget({super.key});

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _showSettingsDialog(BuildContext context, WidgetRef ref) {
    int newTime = ref.read(defaultRestTimeProvider);
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tempo de Descanso'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Defina o tempo de descanso para as próximas séries (em segundos):'),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: newTime.toString(),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Segundos',
                  suffixText: 's',
                ),
                onChanged: (val) {
                  newTime = int.tryParse(val) ?? newTime;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCELAR'),
            ),
            ElevatedButton(
              onPressed: () {
                // Guarda o novo tempo padrão na memória
                ref.read(defaultRestTimeProvider.notifier).state = newTime;
                // Reinicia o cronómetro atual com o novo tempo
                ref.read(restTimerProvider.notifier).startTimer(newTime);
                Navigator.pop(context);
              },
              child: const Text('SALVAR'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(restTimerProvider);

    if (!timerState.isRunning) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, -2))
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Agora o tempo é um botão clicável com um ícone de edição
            InkWell(
              onTap: () => _showSettingsDialog(context, ref),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Row(
                  children: [
                    const Icon(Icons.timer, size: 28),
                    const SizedBox(width: 8),
                    Text(
                      _formatTime(timerState.remainingSeconds),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.edit, size: 16, color: Colors.grey),
                  ],
                ),
              ),
            ),
            Row(
              children: [
                TextButton(
                  onPressed: () => ref.read(restTimerProvider.notifier).addTime(30),
                  child: const Text('+30s'),
                ),
                TextButton(
                  onPressed: () => ref.read(restTimerProvider.notifier).addTime(-30),
                  child: const Text('-30s'),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => ref.read(restTimerProvider.notifier).stopTimer(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}