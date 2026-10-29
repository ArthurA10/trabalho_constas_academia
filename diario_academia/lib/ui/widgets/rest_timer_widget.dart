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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(restTimerProvider);

    // Se o cronómetro não estiver a correr, não mostra nada
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
            Row(
              children: [
                const Icon(Icons.timer, size: 28),
                const SizedBox(width: 12),
                Text(
                  _formatTime(timerState.remainingSeconds),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
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