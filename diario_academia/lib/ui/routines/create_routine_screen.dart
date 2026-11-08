import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models.dart';
import '../../providers/app_providers.dart';
import 'select_exercise_screen.dart';

class CreateRoutineScreen extends ConsumerStatefulWidget {
  const CreateRoutineScreen({super.key});

  @override
  ConsumerState<CreateRoutineScreen> createState() => _CreateRoutineScreenState();
}

class _CreateRoutineScreenState extends ConsumerState<CreateRoutineScreen> {
  final _nameController = TextEditingController();
  final List<Exercise> _selectedExercises = [];
  bool _isSaving = false;

  Future<void> _saveRoutine() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Insira um nome para a rotina')));
      return;
    }
    if (_selectedExercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Adicione pelo menos um exercício')));
      return;
    }

    setState(() => _isSaving = true);
    
    await ref.read(databaseRepositoryProvider).createRoutineWithExercises(
      _nameController.text.trim(),
      _selectedExercises,
    );
    
    // Atualiza a lista de rotinas na tela anterior
    ref.invalidate(routinesProvider);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova Rotina'),
        actions: [
          IconButton(
            icon: _isSaving 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                : const Icon(Icons.check),
            onPressed: _isSaving ? null : _saveRoutine,
          )
        ],
      ),
      // SafeArea garante que o conteúdo não invada as áreas dos botões do sistema
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome da Rotina (ex: Treino A, Push)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Exercícios', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Expanded(
                child: _selectedExercises.isEmpty
                    ? Center(child: Text('Nenhum exercício adicionado.', style: TextStyle(color: Colors.grey.shade400)))
                    : ListView.builder(
                        itemCount: _selectedExercises.length,
                        itemBuilder: (context, index) {
                          final ex = _selectedExercises[index];
                          return Card(
                            child: ListTile(
                              title: Text(ex.name),
                              subtitle: Text(ex.muscleGroup),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => setState(() => _selectedExercises.removeAt(index)),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 16),
              
              // SizedBox adiciona um respiro na parte inferior para levantar o botão
              SizedBox(
                width: double.infinity, // O botão agora ocupa a largura toda
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final selected = await Navigator.push<Exercise>(
                      context,
                      MaterialPageRoute(builder: (_) => const SelectExerciseScreen()),
                    );
                    
                    if (selected != null) {
                      // VERIFICAÇÃO DE DUPLICIDADE AQUI
                      final jaExiste = _selectedExercises.any((ex) => ex.id == selected.id);

                      if (jaExiste) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Este exercício já foi adicionado!'),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        }
                        return;
                      }

                      setState(() => _selectedExercises.add(selected));
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Adicionar Exercício', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 8), // Margem extra do fundo da tela
            ],
          ),
        ),
      ),
    );
  }
}