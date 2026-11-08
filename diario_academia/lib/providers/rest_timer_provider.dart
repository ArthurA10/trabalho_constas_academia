import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/notification_service.dart';
// O import do settings_provider não é mais necessário aqui, pois a UI já passa os dados.

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
    
    // Usa o tempo e o nome que a tela enviou, sem precisar chamar o 'settings'
    NotificationService().showOngoingRestChronometer(targetTime, exerciseName);
    
    // Agenda o alarme crítico para quando zerar (agora sem duplicar)
    NotificationService().scheduleRestNotification(targetTime);

    state = RestTimerState(
      isRunning: true,
      remainingSeconds: seconds,
      targetEndTime: targetTime,
    );

    _timer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (state.targetEndTime == null) return;

      final now = DateTime.now();
      final diffMs = state.targetEndTime!.difference(now).inMilliseconds;
      final remaining = (diffMs / 1000).ceil();

      if (remaining <= 0) {
        // CORREÇÃO: false para não cancelar a notificação ao esgotar o tempo
        stopTimer(cancelAlarm: false);
      } else if (remaining != state.remainingSeconds){
        state = RestTimerState(
          isRunning: true,
          remainingSeconds: remaining,
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