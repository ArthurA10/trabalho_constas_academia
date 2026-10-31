import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
    );

    final androidPlugin = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        
    // Solicita permissão para notificações
    await androidPlugin?.requestNotificationsPermission();
    
    // Solicita permissão para alarmes exatos (Obrigatório a partir do Android 14/15/16)
    await androidPlugin?.requestExactAlarmsPermission();
  }

  Future<void> scheduleRestNotification(DateTime endTime) async {
    await cancelNotification();

    // 1. Calcula a duração exata do cronômetro a partir do momento do clique
    final duration = endTime.difference(DateTime.now());
    
    // 2. Adiciona a duração ao relógio da biblioteca para evitar o erro de fuso horário do UTC
    final scheduledDate = tz.TZDateTime.now(tz.local).add(duration);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id: 1, 
      title: 'Tempo de Descanso Concluído!',
      body: 'É hora de voltar ao treino.',
      scheduledDate: scheduledDate,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'rest_timer_channel',
          'Cronômetro de Descanso',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(presentSound: true, presentAlert: true),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancelNotification() async {
    await flutterLocalNotificationsPlugin.cancel(id: 1);
  }
}