import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/settings_provider.dart';
import '../../providers/app_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Preferências de Treino', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          SwitchListTile(
            title: const Text('Unidade de Peso'),
            subtitle: Text(settings.useLbs ? 'Libras (lb)' : 'Quilogramas (kg)'),
            value: settings.useLbs,
            onChanged: (value) => ref.read(settingsProvider.notifier).toggleUnit(value),
          ),
          ListTile(
            title: const Text('Tempo de Descanso Padrão'),
            subtitle: Text('${settings.defaultRestTime} segundos'),
            trailing: DropdownButton<int>(
              value: settings.defaultRestTime,
              items: [30, 45, 60, 90, 120, 180].map((int value) {
                return DropdownMenuItem<int>(
                  value: value,
                  child: Text('${value}s'),
                );
              }).toList(),
              onChanged: (newValue) {
                if (newValue != null) {
                  ref.read(settingsProvider.notifier).updateRestTime(newValue);
                }
              },
            ),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Gestão de Dados', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ListTile(
            title: const Text('Limpar Histórico de Treinos', style: TextStyle(color: Colors.redAccent)),
            subtitle: const Text('Apaga permanentemente as sessões concluídas.'),
            leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
            onTap: () => _showClearHistoryDialog(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _showClearHistoryDialog(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Atenção'),
        content: const Text('Tem a certeza que deseja apagar todo o histórico de treinos? Esta ação não afetará as suas rotinas nem os exercícios, mas os dados de evolução serão perdidos.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Apagar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseRepository().clearWorkoutHistory();
      // Atualiza os providers para os relatórios e histórico refletirem a limpeza a zero
      ref.invalidate(historyProvider);
      ref.invalidate(volumeProvider);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Histórico limpo com sucesso.')),
        );
      }
    }
  }
}