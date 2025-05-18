import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  // Initialisation de Firebase Messaging & notifications locales
  static Future<void> initialize() async {
    // Demander les permissions (nécessaire sur iOS & Android 13+)
    await _firebaseMessaging.requestPermission();

    // Récupérer le token FCM (utile pour tester les notifications via Firebase Console)
    String? token = await _firebaseMessaging.getToken();
    print("🔑 Firebase Token: $token");

    // Initialisation de la notification locale
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
    );

    // Notifications reçues en premier plan
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📩 Message reçu en premier plan: ${message.notification?.title}');

      if (message.notification != null) {
        showNotification(
          title: message.notification!.title ?? '',
          body: message.notification!.body ?? '',
        );
      }
    });

    // Notification cliquée (app ouverte depuis une notification)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('📬 Notification ouverte: ${message.notification?.title}');
      // TODO: Navigate or trigger action
    });
  }

  // Afficher une notification locale
  static Future<void> showNotification({required String title, required String body}) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'default_channel', // channel ID
      'Default', // channel name
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      0, // ID de notification
      title,
      body,
      platformChannelSpecifics,
    );
  }
}
