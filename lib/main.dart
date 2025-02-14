import 'dart:async';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dryrun/BeckgroundLocation.dart';
import 'package:dryrun/bg.dart';
import 'package:dryrun/logger_helper.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:geolocator/geolocator.dart';

import 'firebase_options.dart';
import 'notification_helper.dart';
import 'temp/notificationshow.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await initializeNotificationService();
  final status =
      await BackgroundLocationService().checkLocationPermissionInForeground();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (status == true) {
    BackgroundLocationService().initializeBackgroundService();
    await Workmanager().initialize(
        callbackDispatcher, // The top level function, aka callbackDispatcher
        isInDebugMode:
            false // If enabled it will post a notification whenever the task is running. Ha ndy for debugging tasks
        );
    Workmanager().registerPeriodicTask("task-identifier", "simpleTask",
        frequency: Duration(minutes: 5));
  }
  // NotificationService notificationService = NotificationService();
  // await notificationService.initNotification();

  runApp(MyApp());
}

@pragma(
    'vm:entry-point') // Mandatory if the App is obfuscated or using Flutter 3.1+
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    LoggerHelper.info("Native called background task: $task");
    if (StaticService.service == null) {
      await BackgroundLocationService().initializeBackgroundService().then((_) {
        StaticService.service!.startService();
      });
    } else {
      StaticService.service!.startService();
    }
    print(
        "Native called background task: $task"); //simpleTask will be emitted here.
    return Future.value(true);
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text("Background Location Tracking")),
        floatingActionButton: FloatingActionButton(onPressed: () {
          final time = Timestamp.now();
          print("Time : ${time.toDate()}");
        }),
        body: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(child: Text("Tracking location in background...")),
            ElevatedButton(
                onPressed: () {
                  if (StaticService.service != null) {
                    StaticService.service!.startService();
                  }
                },
                child: Text("Start")),
            // ElevatedButton(onPressed: () {
            //  if(StaticService.service != null){
            //  }
            // }, child: Text("Stop")),
          ],
        ),
      ),
    );
  }
}

Future<void> requestAllPermissions() async {
  // 1️⃣ Request "While in Use" Location Permission
  var locationPermission = await Permission.locationWhenInUse.request();
  if (locationPermission.isGranted) {
    print("✅ Location (While in Use) Permission Granted");

    // 2️⃣ Request "Allow All Time" Location Permission
    var backgroundLocationPermission =
        await Permission.locationAlways.request();
    if (backgroundLocationPermission.isGranted) {
      print("✅ Background Location Permission Granted");

      // 3️⃣ Request Notification Permission
      var notificationPermission = await Permission.notification.request();
      if (notificationPermission.isGranted) {
        print("✅ Notification Permission Granted");

        // 4️⃣ Request to Disable Battery Optimization
        var batteryOptimization =
            await Permission.ignoreBatteryOptimizations.request();
        if (batteryOptimization.isGranted) {
          print("✅ Battery Optimization Disabled");
        } else {
          print("❌ Battery Optimization Permission Denied");
        }
      } else {
        print("❌ Notification Permission Denied");
      }
    } else {
      print("❌ Background Location Permission Denied");
    }
  } else {
    print("❌ Location (While in Use) Permission Denied");
  }
}
