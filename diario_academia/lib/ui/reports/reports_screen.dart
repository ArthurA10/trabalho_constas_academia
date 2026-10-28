import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_providers.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyProvider);
    final volumeAsync = ref.watch(volumeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatórios'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(historyProvider);
              ref.invalidate(volumeProvider);
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Evolução Geral', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const Icon(Icons.fitness_center, size: 32, color: Colors.blueAccent),
                          const SizedBox(height: 8),
                          historyAsync.when(
                            data: (workouts) => Text('${workouts.length}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                            loading: () => const CircularProgressIndicator(),
                            error: (e, _) => const Text('Erro'),
                          ),
                          const Text('Treinos Concluídos', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const Icon(Icons.monitor_weight, size: 32, color: Colors.blueAccent),
                          const SizedBox(height: 8),
                          volumeAsync.when(
                            data: (volume) => Text('${volume.toStringAsFixed(0)} kg', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                            loading: () => const CircularProgressIndicator(),
                            error: (e, _) => const Text('Erro'),
                          ),
                          const Text('Volume Total', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}