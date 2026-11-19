import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../providers/app_providers.dart';

import 'dart:math';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  void _showAddWeightDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Registrar Peso'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Seu peso atual (ex: 75.5)',
            suffixText: 'kg',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              final weight = double.tryParse(
                controller.text.replaceAll(',', '.'),
              );
              if (weight != null && weight > 0) {
                await ref
                    .read(databaseRepositoryProvider)
                    .addBodyWeight(weight);
                ref.invalidate(
                  bodyWeightProvider,
                ); // Atualiza o gráfico de peso
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weightDataAsync = ref.watch(bodyWeightProvider);
    final volumeDataAsync = ref.watch(volumeChartProvider);

    final currentFilter = ref.watch(chartTimeFilterProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Relatórios e Evolução')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddWeightDialog(context, ref),
        icon: const Icon(Icons.scale),
        label: const Text('Registrar Peso'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            // --- FILTRO TEMPORAL ---
            Center(
              child: SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 7, label: Text('7 Dias')),
                  ButtonSegment(value: 30, label: Text('30 Dias')),
                  ButtonSegment(value: 90, label: Text('3 Meses')),
                  ButtonSegment(value: 0, label: Text('Tudo')),
                ],
                selected: {currentFilter},
                onSelectionChanged: (Set<int> newSelection) {
                  // Usa o método setFilter que você criou no Notifier!
                  ref.read(chartTimeFilterProvider.notifier).setFilter(newSelection.first);
                },
              ),
            ),
            const SizedBox(height: 24),

            // --- GRÁFICO 1: PESO CORPORAL ---
            const Text(
              'Evolução de Peso Corporal',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  height: 250,
                  child: weightDataAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (err, stack) => Center(child: Text('Erro: $err')),
                    data: (data) {
                      if (data.isEmpty) {
                        return const Center(
                          child: Text(
                            'Nenhum peso registrado ainda.\nToque no botão abaixo para começar!',
                            textAlign: TextAlign.center,
                          ),
                        );
                      }

                      // Calcula o maior e menor peso para dar uma margem no gráfico
                      final weights = data
                          .map((e) => e['weight'] as double)
                          .toList();
                      final minWeight = weights.reduce(min);
                      final maxWeight = weights.reduce(max);
                      final spots = data.asMap().entries.map((e) {
                        return FlSpot(
                          e.key.toDouble(),
                          e.value['weight'] as double,
                        );
                      }).toList();

                      return LineChart(
                        LineChartData(
                          minY: (minWeight - 2).floorToDouble(), // Dá 2kg de folga para baixo (evita vazar a borda) e arredonda
                          maxY: (maxWeight + 2).floorToDouble(), // Dá 2kg de folga para cima
                          gridData: const FlGridData(show: false),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 50,
                                interval: 1, // Pode manter 1 para peso, fica com bom espaçamento
                                getTitlesWidget: (value, meta) {
                                  // O PULO DO GATO: Se o valor for a exata borda superior ou inferior,
                                  // nós o escondemos. Isso impede que ele se sobreponha aos números do intervalo!
                                  if (value == meta.max || value == meta.min) {
                                    return const SizedBox.shrink();
                                  }
                                  
                                  // Garante que só mostre números inteiros
                                  if (value % 1 != 0) return const SizedBox.shrink();

                                  return Text(
                                    value.toInt().toString(),
                                    style: const TextStyle(fontSize: 10),
                                  );
                                },
                              )
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: 1,
                                getTitlesWidget: (value, meta) {
                                  // Se o valor não for um número inteiro exato, esconde o texto
                                  if (value % 1 != 0) return const SizedBox.shrink();
                                  
                                  final dateStr =
                                      data[value.toInt()]['date'] as String;
                                  final date = DateTime.parse(dateStr);
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      DateFormat('dd/MM').format(date),
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          borderData: FlBorderData(
                            show: true,
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          lineBarsData: [
                            LineChartBarData(
                              spots: spots,
                              isCurved: true,
                              color: Colors.blueAccent,
                              barWidth: 3,
                              isStrokeCapRound: true,
                              dotData: const FlDotData(show: true),
                              belowBarData: BarAreaData(
                                show: true,
                                color: Colors.blueAccent.withOpacity(0.2),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // --- GRÁFICO 2: VOLUME DE TREINO (FORÇA) ---
            const Text(
              'Desempenho de Força (Volume)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  height: 250,
                  child: volumeDataAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (err, stack) =>
                        Center(child: Text('Erro ao carregar volume: $err')),
                    data: (data) {
                      if (data.isEmpty || data[0]['total_volume'] == null) {
                        return const Center(
                          child: Text(
                            'Complete seu primeiro treino para ver a evolução da sua força!',
                            textAlign: TextAlign.center,
                          ),
                        );
                      }

                      // Calcula o maior e menor volume para dar a margem
                      final volumes = data
                          .map(
                            (e) =>
                                (e['total_volume'] as num?)?.toDouble() ?? 0.0,
                          )
                          .toList();
                      final minVolume = volumes.reduce(min);
                      final maxVolume = volumes.reduce(max);

                      // Calcula uma folga de 10% para o gráfico respirar
                      final paddingY = (maxVolume - minVolume) * 0.1;
                      // Se os valores forem iguais (só 1 treino), a folga padrão é 1000
                      final safePadding = paddingY == 0 ? 1000.0 : paddingY;

                      final spots = data.asMap().entries.map((e) {
                        final volume =
                            (e.value['total_volume'] as num?)?.toDouble() ??
                            0.0;
                        return FlSpot(e.key.toDouble(), volume);
                      }).toList();

                      return LineChart(
                        LineChartData(
                          minY: (minVolume - safePadding).clamp(
                            0,
                            double.infinity,
                          ), // Folga para baixo (não deixa ficar negativo)
                          maxY: maxVolume + safePadding, // Folga para cima
                          gridData: const FlGridData(show: false),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 50, // Aumenta o espaço lateral (resolve a quebra de linha)
                                getTitlesWidget: (value, meta) {
                                  // Opcional: Arredonda o valor para ficar mais limpo (ex: 9.5K em vez de 9.52K)
                                  if (value >= 1000) {
                                    return Text(
                                      '${(value / 1000).toStringAsFixed(1)}K',
                                      style: const TextStyle(fontSize: 10),
                                    );
                                  }
                                  return Text(
                                    value.toStringAsFixed(0),
                                    style: const TextStyle(fontSize: 10),
                                  );
                                },
                              ),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: 1,
                                getTitlesWidget: (value, meta) {
                                  //Se o valor não for um número inteiro exato, esconde o texto
                                  if (value % 1 != 0) return const SizedBox.shrink();

                                  final index = value.toInt();
                                  if (index < 0 || index >= data.length) return const Text('');

                                  final dateStr = data[index]['date'] as String;
                                  final dateParts = dateStr.split('-');
                                  if (dateParts.length != 3){
                                    return const Text('');
                                  }

                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      '${dateParts[2]}/${dateParts[1]}',
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          borderData: FlBorderData(
                            show: true,
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          lineBarsData: [
                            LineChartBarData(
                              spots: spots,
                              isCurved: true,
                              color: Colors.orangeAccent,
                              barWidth: 3,
                              isStrokeCapRound: true,
                              dotData: const FlDotData(show: true),
                              belowBarData: BarAreaData(
                                show: true,
                                color: Colors.orangeAccent.withOpacity(0.2),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(
              height: 80,
            ), // Espaço extra no final para o FAB não cobrir o gráfico
          ],
        ),
      ),
    );
  }
}
