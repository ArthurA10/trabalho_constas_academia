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

// 1. Mudamos de StateNotifier para Notifier
class RestTimerNotifier extends Notifier<RestTimerState> {
  Timer? _timer;

  // 2. O estado inicial agora é definido no método build()
  @override
  RestTimerState build() {
    // Quando o Notifier for destruído, cancelamos o timer para evitar memory leaks
    ref.onDispose(() {
      _timer?.cancel();
    });
    
    return RestTimerState();
  }

  void startTimer(int seconds) {
    _timer?.cancel();
    
    final targetTime = DateTime.now().add(Duration(seconds: seconds));
    
    NotificationService().scheduleRestNotification(targetTime);

    state = RestTimerState(
      isRunning: true,
      remainingSeconds: seconds,
      targetEndTime: targetTime,
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.targetEndTime == null) return;

      final now = DateTime.now();
      // Correção: calcula os milissegundos e arredonda para evitar o "pulo"
      final diff = (state.targetEndTime!.difference(now).inMilliseconds / 1000).round();

      if (diff <= 0) {
        stopTimer();
      } else {
        state = RestTimerState(
          isRunning: true,
          remainingSeconds: diff,
          targetEndTime: state.targetEndTime,
        );
      }
    });
  }

  void stopTimer() {
    _timer?.cancel();
    NotificationService().cancelNotification();
    state = RestTimerState(isRunning: false, remainingSeconds: 0, targetEndTime: null);
  }

  void addTime(int seconds) {
    if (!state.isRunning || state.targetEndTime == null) return;
    
    final newTarget = state.targetEndTime!.add(Duration(seconds: seconds));
    // Correção também aplicada aqui ao adicionar tempo
    final newRemaining = (newTarget.difference(DateTime.now()).inMilliseconds / 1000).round();
    
    NotificationService().scheduleRestNotification(newTarget);
    
    state = RestTimerState(
      isRunning: true,
      remainingSeconds: newRemaining,
      targetEndTime: newTarget,
    );
  }
}

// 3. Mudamos de StateNotifierProvider para NotifierProvider
final restTimerProvider = NotifierProvider<RestTimerNotifier, RestTimerState>(() {
  return RestTimerNotifier();
});

// Guarda o tempo de descanso padrão (inicialmente 90 segundos) usando a sintaxe atualizada
class DefaultRestTimeNotifier extends Notifier<int> {
  @override
  int build() => 90;

  void updateTime(int newTime) {
    state = newTime;
  }
}

final defaultRestTimeProvider = NotifierProvider<DefaultRestTimeNotifier, int>(() {
  return DefaultRestTimeNotifier();
});