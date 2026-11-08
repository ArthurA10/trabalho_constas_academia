import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
    );
    // Pede a permissão de notificação e de alarmes exatos no Android 13+
    final androidImplementation = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
      await androidImplementation.requestExactAlarmsPermission();
    }
  }

  // Alarme de alta prioridade disparado quando o tempo esgota
  Future<void> scheduleRestNotification(DateTime endTime) async {
    final int remainingSeconds = endTime.difference(DateTime.now()).inSeconds;
    if (remainingSeconds <= 0) return;

    final scheduledDate = tz.TZDateTime.now(tz.UTC)
        .add(Duration(seconds: remainingSeconds));

    const notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'rest_timer_channel',
        'Cronômetro de Descanso',
        importance: Importance.max,
        priority: Priority.high,
        visibility: NotificationVisibility.public,
        playSound: true,
        enableVibration: true,
        category: AndroidNotificationCategory.alarm,
        fullScreenIntent: true,
      ),
      iOS: DarwinNotificationDetails(presentSound: true, presentAlert: true),
    );

    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id: 1,
        title: 'Tempo de Descanso Concluído!',
        body: 'É hora de voltar ao treino.',
        scheduledDate: scheduledDate,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (e) {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id: 1,
        title: 'Tempo de Descanso Concluído!',
        body: 'É hora de voltar ao treino.',
        scheduledDate: scheduledDate,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  // Notificação com cronômetro contínuo regressivo em tempo real
  Future<void> showOngoingRestChronometer(
    DateTime endTime,
    String exerciseName,
  ) async {
    await flutterLocalNotificationsPlugin.show(
      id: 2,
      title: 'Descanso: $exerciseName',
      body: 'Tempo restante...',
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'ongoing_rest_channel',
          'Descanso em Andamento',
          importance: Importance.low,
          priority: Priority.low,
          usesChronometer: true, // Habilita o relógio
          chronometerCountDown: true, // Força a ser regressivo
          
          when: endTime.millisecondsSinceEpoch, 
          
          ongoing: true, // Não pode ser dispensada com arrasto
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }

  // Cancela apenas o cronômetro visual, mantendo o aviso de conclusão na tela
  Future<void> cancelOngoingChronometer() async {
    await flutterLocalNotificationsPlugin.cancel(id: 2);
  }

  // Único método de cancelamento limpando ambos os alertas
  Future<void> cancelNotification() async {
    await flutterLocalNotificationsPlugin.cancel(id: 1);
    await flutterLocalNotificationsPlugin.cancel(id: 2);
  }
}
