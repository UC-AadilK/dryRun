import 'dart:async';
import 'dart:ui';
import 'package:dryrun/BeckgroundLocation.dart';
import 'package:dryrun/bg.dart';
import 'package:dryrun/logger_helper.dart';
import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:geolocator/geolocator.dart';

import 'notificationshow.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
 final status =  await BackgroundLocationService().checkLocationPermissionInForeground();


 if(status == true){

   BackgroundLocationService().initializeBackgroundService();
   await Workmanager().initialize(
       callbackDispatcher, // The top level function, aka callbackDispatcher
       isInDebugMode:
       true // If enabled it will post a notification whenever the task is running. Handy for debugging tasks
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
  Workmanager().executeTask((task, inputData) async{
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
        body: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(child: Text("Tracking location in background...")),
            ElevatedButton(onPressed: () {
              if (StaticService.service != null) {
                StaticService.service!.startService();
              }
            }, child: Text("Start")),
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
