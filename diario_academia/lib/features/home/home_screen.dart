import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_providers.dart';
import '../../core/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyProvider);
    final volumeAsync = ref.watch(volumeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Diário de Academia'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Botão Premium com Gradiente
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryGradientStart, AppTheme.primaryGradientEnd],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  )
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  // Mantenha sua lógica de Iniciar Treino Livre
                },
                icon: const Icon(Icons.play_arrow_rounded, size: 28),
                label: const Text('Iniciar Treino Livre'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent, // Fundo transparente para ver o gradiente
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text('Resumo da Semana', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: historyAsync.when(
                    data: (workouts) => _buildSummaryCard(context, 'Treinos', '${workouts.length}', Icons.bolt_rounded),
                    loading: () => _buildLoadingCard(),
                    error: (_, __) => _buildSummaryCard(context, 'Treinos', '0', Icons.bolt_rounded),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: volumeAsync.when(
                    data: (volume) => _buildSummaryCard(context, 'Volume (kg)', volume.toStringAsFixed(0), Icons.fitness_center_rounded),
                    loading: () => _buildLoadingCard(),
                    error: (_, __) => _buildSummaryCard(context, 'Volume', '0', Icons.fitness_center_rounded),
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
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.surfaceElevated, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.bgSecondary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 24, color: AppTheme.primary),
          ),
          const SizedBox(height: 16),
          Text(value, style: GoogleFonts.manrope(fontSize: 28, fontWeight: FontWeight.w800, color: AppTheme.textMain)),
          const SizedBox(height: 4),
          Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.surfaceElevated, width: 1),
      ),
      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }
}