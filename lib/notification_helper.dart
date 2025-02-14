import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';

import 'temp/BackGround_Service.dart';

// Notification Channel ID
const String notificationChannelId = 'my_foreground';
// Notification ID (used for updating notifications)
const int notificationId = 888;

Future<void> initializeNotificationService() async {
  // Create a notification channel
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    notificationChannelId, // Channel ID
    'MY FOREGROUND SERVICE', // Channel Name
    description: 'This channel is used for important notifications.',
    importance: Importance.low, // Must be at least low or higher
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
}
