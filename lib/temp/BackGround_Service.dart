// import 'dart:async';
// import 'dart:ui';
// import 'package:flutter/material.dart';
// import 'package:flutter_background_service/flutter_background_service.dart';
//
// import 'notificationshow.dart';
//
// // Top-level function for background service
//
// void onStart(ServiceInstance service) async {
//   DartPluginRegistrant.ensureInitialized();
//
//   Timer.periodic(const Duration(seconds: 20), (timer) async {
//     print("::::::::::::::${timer.isActive}");
//       NotificationService().showNotification(
//       id: 1,
//       body: "Background service will call ",
//       payload: "now",
//       title: "New Notificatio",
//     );
//
//     print('Data written at: ${DateTime.now()}');
//   });
//
//   print('Background task executed: ${DateTime.now()}');
// }
//
// class BackgroundevServiceCustom {
//   Future<void> initializeService() async {
//     final service = FlutterBackgroundService();
//
//     await service.configure(
//       androidConfiguration: AndroidConfiguration(
//         onStart: onStart,
//         autoStart: true,
//         isForegroundMode: true,
//         initialNotificationContent: "Debuging",
//         initialNotificationTitle: "Happy Pratice",
//       ),
//       iosConfiguration: IosConfiguration(
//         autoStart: true,
//         onForeground: onStart,
//         onBackground: onIosBackground,
//       ),
//     );
//   }
//
//   Future<bool> onIosBackground(ServiceInstance service) async {
//     WidgetsFlutterBinding.ensureInitialized();
//     DartPluginRegistrant.ensureInitialized();
//     return true;
//   }
// }
