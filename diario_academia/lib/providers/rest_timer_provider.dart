import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/notification_service.dart';

class RestTimerState {
  final bool isRunning;
  final int remainingSeconds;
  final DateTime? targetEndTime;

  RestTimerState({
    this.isRunning = false,
    this.remainingSeconds = 0,
    this.targetEndTime,
  });
}

class RestTimerNotifier extends Notifier<RestTimerState> {
  Timer? _timer;

  @override
  RestTimerState build() {
    ref.onDispose(() {
      _timer?.cancel();
    });
    return RestTimerState();
  }

  void startTimer(int seconds, {String exerciseName = 'Exercício'}) {
    _timer?.cancel();
    
    final targetTime = DateTime.now().add(Duration(seconds: seconds));
    
    // Inicia o cronômetro visual instantaneamente
    NotificationService().showOngoingRestChronometer(targetTime, exerciseName);
    // Agenda o alarme crítico para quando zerar
    NotificationService().scheduleRestNotification(targetTime);

    NotificationService().scheduleRestNotification(targetTime);

    state = RestTimerState(
      isRunning: true,
      remainingSeconds: seconds,
      targetEndTime: targetTime,
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.targetEndTime == null) return;

      final now = DateTime.now();
      final diff = state.targetEndTime!.difference(now).inSeconds;

      if (diff <= 0) {
        // CORREÇÃO: false para não cancelar a notificação ao esgotar o tempo
        stopTimer(cancelAlarm: false);
      } else {
        state = RestTimerState(
          isRunning: true,
          remainingSeconds: diff,
          targetEndTime: state.targetEndTime,
        );
      }
    });
  }

  // CORREÇÃO: Adicionado parâmetro opcional cancelAlarm (por padrão, true)
  void stopTimer({bool cancelAlarm = true}) {
    _timer?.cancel();
    
    if (cancelAlarm) {
      // Interrompido manualmente antes do fim: remove tudo
      NotificationService().cancelNotification();
    } else {
      // Tempo esgotou: remove apenas o cronômetro negativo da tela, 
      // e deixa o alerta de "Tempo Concluído" (ID 1) tocar.
      NotificationService().cancelOngoingChronometer();
    }
    
    state = RestTimerState(isRunning: false, remainingSeconds: 0, targetEndTime: null);
  }

  void addTime(int seconds) {
    if (!state.isRunning || state.targetEndTime == null) return;
    
    final newTarget = state.targetEndTime!.add(Duration(seconds: seconds));
    final newRemaining = newTarget.difference(DateTime.now()).inSeconds;
    
    NotificationService().scheduleRestNotification(newTarget);
    
    state = RestTimerState(
      isRunning: true,
      remainingSeconds: newRemaining,
      targetEndTime: newTarget,
    );
  }
}

final restTimerProvider = NotifierProvider<RestTimerNotifier, RestTimerState>(() {
  return RestTimerNotifier();
});

class DefaultRestTimeNotifier extends Notifier<int> {
  @override
  int build() => 90; // Tempo inicial
  
  void setTime(int seconds) => state = seconds;
}

final defaultRestTimeProvider = NotifierProvider<DefaultRestTimeNotifier, int>(() {
  return DefaultRestTimeNotifier();
});