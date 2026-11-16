import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models.dart';
import '../../providers/app_providers.dart';
import '../../providers/rest_timer_provider.dart';
import '../../providers/active_workout_session_provider.dart';
import '../widgets/rest_timer_widget.dart';
import '../../providers/settings_provider.dart';
import '../../ui/routines/select_exercise_screen.dart';

class ActiveWorkoutScreen extends ConsumerStatefulWidget {
  final Routine routine;
  const ActiveWorkoutScreen({super.key, required this.routine});

  @override
  ConsumerState<ActiveWorkoutScreen> createState() =>
      _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends ConsumerState<ActiveWorkoutScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeRoutine();
    });
  }

  Future<void> _initializeRoutine() async {
    final session = ref.read(activeWorkoutSessionProvider);
    if (!session.isRunning || session.routine?.id != widget.routine.id) {
      final exercises = await ref
          .read(databaseRepositoryProvider)
          .getExercisesForRoutine(widget.routine.id!);
      ref
          .read(activeWorkoutSessionProvider.notifier)
          .startRoutineWorkout(widget.routine, exercises);
    }
    setState(() => _isLoading = false);
  }

  Future<void> _finishWorkout() async {
    // 1. Mostra um círculo de carregamento enquanto salva no banco
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 2. Chama a função de finalizar que criamos no Provider!
      final success = await ref
          .read(activeWorkoutSessionProvider.notifier)
          .finishWorkout();

      // 3. Fecha o círculo de carregamento
      if (mounted) Navigator.pop(context);

      if (success) {
        // Se salvou com sucesso, para o cronômetro, atualiza as telas e volta pro início
        ref.read(restTimerProvider.notifier).stopTimer();
        ref.invalidate(historyProvider);

        ref.invalidate(volumeProvider); //Atualiza o somatório total
        ref.invalidate(volumeChartProvider); // Atualiza o gráfico

        if (mounted) {
          // Fecha a tela de treino e volta para a tela principal (Home)
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } else {
        // Se retornou false, é porque não tinha nenhuma série marcada com check verde (e com peso/reps)
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Conclua pelo menos uma série (com peso e reps preenchidos) para salvar.',
              ),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      // Se der algum erro no banco de dados (ex: tabela faltando), vai mostrar vermelho aqui!
      if (mounted) Navigator.pop(context); // Fecha o carregamento

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar no banco: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final session = ref.watch(activeWorkoutSessionProvider);
    final settings = ref.watch(settingsProvider);
    final pesoLabel = settings.useLbs ? 'Lbs' : 'Kg';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Treino Ativo'),
        actions: [
          TextButton(
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Finalizar Treino?'),
                  content: const Text('Deseja concluir e salvar este treino?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancelar'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Finalizar'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await _finishWorkout(); // Agora a sua função é chamada e usada!
              }
            },
            child: const Text(
              'FINALIZAR',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount:
            session.exercises.length +
            1, // +1 para o botão de adicionar no final
        itemBuilder: (context, index) {
          // BOTÃO DE ADICIONAR NO FINAL DA LISTA
          if (index == session.exercises.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: OutlinedButton.icon(
                icon: const Icon(Icons.add_circle_outline),
                label: const Text(
                  'Adicionar Exercício Extra',
                  style: TextStyle(fontSize: 16),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
                onPressed: () async {
                  // Abre a tela para o usuário escolher o exercício
                  final selectedExercise = await Navigator.push<Exercise>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SelectExerciseScreen(),
                    ),
                  );

                  // Se ele escolheu um exercício (não cancelou a tela), adicionamos ao treino
                  if (selectedExercise != null) {
                    ref
                        .read(activeWorkoutSessionProvider.notifier)
                        .addExercise(selectedExercise);
                  }
                },
              ),
            );
          }

          final ex = session.exercises[index];
          final sets = session.workoutSets[ex.id!] ?? [];

          return Card(
            margin: const EdgeInsets.only(bottom: 24),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // CABEÇALHO DO EXERCÍCIO COM BOTÃO DE REMOVER (X)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          ex.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        tooltip: 'Remover Exercício',
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Remover exercício?'),
                              content: Text(
                                'Deseja remover ${ex.name} desta rotina?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('Cancelar'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    ref
                                        .read(
                                          activeWorkoutSessionProvider.notifier,
                                        )
                                        .removeExercise(ex.id!);
                                    Navigator.pop(ctx);
                                  },
                                  child: const Text(
                                    'Remover',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  // CABEÇALHO DAS COLUNAS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(
                        width: 40,
                        child: Text('Série', textAlign: TextAlign.center),
                      ),
                      // Aqui usamos o pesoLabel!
                      Expanded(
                        child: Text(
                          'Peso ($pesoLabel)',
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const Expanded(
                        child: Text('Reps', textAlign: TextAlign.center),
                      ),
                      const SizedBox(width: 48, child: Icon(Icons.check)),
                    ],
                  ),
                  const Divider(),

                  // LISTA DE SÉRIES
                  ...List.generate(sets.length, (setIndex) {
                    final currentSet = sets[setIndex];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 40,
                            child: Text(
                              '${setIndex + 1}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          // CAMPO PESO
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              child: TextFormField(
                                initialValue: currentSet.weight == 0
                                    ? ''
                                    : currentSet.weight.toString(),
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.zero,
                                ),
                                onChanged: (val) => ref
                                    .read(activeWorkoutSessionProvider.notifier)
                                    .updateSet(
                                      ex.id!,
                                      setIndex,
                                      double.tryParse(val) ?? 0,
                                      currentSet.reps,
                                      currentSet.isCompleted == 1,
                                    ),
                              ),
                            ),
                          ),

                          // CAMPO REPETIÇÕES
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              child: TextFormField(
                                initialValue: currentSet.reps == 0
                                    ? ''
                                    : currentSet.reps.toString(),
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.zero,
                                ),
                                onChanged: (val) => ref
                                    .read(activeWorkoutSessionProvider.notifier)
                                    .updateSet(
                                      ex.id!,
                                      setIndex,
                                      currentSet.weight,
                                      int.tryParse(val) ?? 0,
                                      currentSet.isCompleted == 1,
                                    ),
                              ),
                            ),
                          ),

                          // LIXEIRA DA SÉRIE
                          if (currentSet.isCompleted == 0)
                            IconButton(
                              icon: const Icon(
                                Icons.remove_circle_outline,
                                color: Colors.red,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                ref
                                    .read(activeWorkoutSessionProvider.notifier)
                                    .removeSet(ex.id!, setIndex);
                              },
                            ),

                          // CHECKBOX DA SÉRIE
                          SizedBox(
                            width: 48,
                            child: Checkbox(
                              value: currentSet.isCompleted == 1,
                              onChanged: (val) {
                                if (val == true) {
                                  if (currentSet.weight <= 0 ||
                                      currentSet.reps <= 0) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Preencha o peso e as repetições antes de concluir a série!',
                                        ),
                                        behavior: SnackBarBehavior.floating,
                                        margin: EdgeInsets.only(
                                          bottom: 10,
                                          left: 16,
                                          right: 16,
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  final tempoPadrao = ref
                                      .read(settingsProvider)
                                      .defaultRestTime;
                                  ref
                                      .read(restTimerProvider.notifier)
                                      .startTimer(
                                        tempoPadrao,
                                        exerciseName: ex.name,
                                      );
                                }
                                ref
                                    .read(activeWorkoutSessionProvider.notifier)
                                    .updateSet(
                                      ex.id!,
                                      setIndex,
                                      currentSet.weight,
                                      currentSet.reps,
                                      val == true,
                                    );
                              },
                              activeColor: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  TextButton.icon(
                    onPressed: () => ref
                        .read(activeWorkoutSessionProvider.notifier)
                        .addSet(ex.id!),
                    icon: const Icon(Icons.add),
                    label: const Text('Adicionar Série'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: const RestTimerWidget(),
    );
  }
}
