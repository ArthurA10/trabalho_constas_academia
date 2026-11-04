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
        
    await androidPlugin?.requestNotificationsPermission();
    
    try {
      await androidPlugin?.requestExactAlarmsPermission();
    } catch (_) {}
  }

  Future<void> scheduleRestNotification(DateTime endTime) async {
    await cancelNotification();
    
    // Calcula quantos segundos exatos a contagem deve durar
    final int remainingSeconds = endTime.difference(DateTime.now()).inSeconds;
    if (remainingSeconds <= 0) return;
    
    // Adiciona esses segundos à referência zero do UTC para não depender de fuso horário
    final scheduledDate = tz.TZDateTime.now(tz.UTC).add(Duration(seconds: remainingSeconds));

    final notificationDetails = const NotificationDetails(
      android: AndroidNotificationDetails(
        'rest_timer_channel',
        'Cronômetro de Descanso',
        importance: Importance.max,
        priority: Priority.high,
        visibility: NotificationVisibility.public,
        playSound: true,
        enableVibration: true,
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

  Future<void> cancelNotification() async {
    await flutterLocalNotificationsPlugin.cancel(id: 1);
  }
}