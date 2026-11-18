import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/models.dart';
import '../../providers/app_providers.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';

class WorkoutDetailScreen extends ConsumerWidget {
  final Workout workout;
  const WorkoutDetailScreen({super.key, required this.workout});

  @override
  // CORREÇÃO: Adicionado o 'WidgetRef ref' aqui!
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.bgMain,
      appBar: AppBar(
        title: const Text('Resumo do Treino'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.success.withOpacity(0.1),
              ),
              child: const Icon(
                Icons.emoji_events_rounded,
                size: 64,
                color: AppTheme.success,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Treino Concluído!',
              style: GoogleFonts.manrope(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppTheme.textMain,
              ),
            ),
            const SizedBox(height: 40),
            
            // Grid de Estatísticas Premium
            Row(
              children: [
                Expanded(
                  child: _buildStatPanel(
                    'Duração', 
                    // Se o seu model usar apenas "duration", mude aqui para workout.duration
                    '${workout.durationMinutes} min', 
                    Icons.timer_rounded,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatPanel(
                    'Volume', 
                    '${workout.totalVolume} kg', 
                    Icons.fitness_center_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildStatPanel(
              'Séries Concluídas', 
              '${workout.completedSets} séries', 
              Icons.check_circle_rounded,
              isFullWidth: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatPanel(String label, String value, IconData icon, {bool isFullWidth = false}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.surfaceElevated),
      ),
      child: Column(
        crossAxisAlignment: isFullWidth ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.primary, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textMain,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}