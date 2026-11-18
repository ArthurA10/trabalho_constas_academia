import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
// Import corrigido para o caminho correto do seu provider
import '../../providers/active_workout_session_provider.dart';

void showFinishWorkoutBottomSheet(BuildContext context, WidgetRef parentRef) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppTheme.bgMain,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      // Adicionado um Consumer para o Modal conseguir escutar o Riverpod corretamente
      return Consumer(
        builder: (context, ref, child) {
          final session = ref.watch(activeWorkoutSessionProvider);

          // Calculando dinamicamente o total de séries e quantas foram concluídas
          int totalSetsCount = 0;
          int completedSetsCount = 0;

          for (var sets in session.workoutSets.values) {
            totalSetsCount += sets.length;
            completedSetsCount += sets.where((set) => set.isCompleted == 1).length;
          }

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceElevated,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  'Finalizar Treino?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textMain,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Você completou $completedSetsCount de $totalSetsCount séries.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [AppTheme.primaryGradientStart, AppTheme.primaryGradientEnd],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withOpacity(0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(true); // Retorna true para a tela avisando que confirmou
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                    child: Text(
                      'Salvar Treino',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false), // Retorna false avisando para continuar
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.textSecondary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Continuar Treinando'),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}