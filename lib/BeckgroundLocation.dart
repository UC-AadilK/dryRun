import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'notification_helper.dart';

class StaticService {
  static FlutterBackgroundService? service;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance serviceInstance) async {
  DartPluginRegistrant.ensureInitialized();
  print("<<<<<<<<<<<<<<<<<<Background service started!");

  // final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  //     FlutterLocalNotificationsPlugin();

  // Periodically update the notification
  // var activeTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
  //   if (serviceInstance is AndroidServiceInstance) {
  //     // Check if service is still in foreground
  //     if (await serviceInstance.isForegroundService()) {
  //       print("notification is still updating>>>>>>>>>>>>>");
  //       flutterLocalNotificationsPlugin.show(
  //         notificationId,
  //         'COOL SERVICE',
  //         'Updated Time: ${DateTime.now()}',
  //         const NotificationDetails(
  //           android: AndroidNotificationDetails(
  //             notificationChannelId,
  //             'MY FOREGROUND SERVICE',
  //             icon: 'ic_bg_service_small',
  //             // Ensure this icon exists in res/drawable
  //             ongoing: true, // Ensures it stays active
  //           ),
  //         ),
  //       );
  //     }
  //   }
  // });

  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: "AIzaSyAnDD1VEuXgvdusIUuim6VyH7dyIVeIX9w",
      appId: "1:1035192159954:android:0a1d5a0b0b1355c812270b",
      messagingSenderId: "1035192159954",
      projectId: "dryrun-b7475",
    ),
  );
  if (serviceInstance is AndroidServiceInstance) {
    serviceInstance.on('setAsForeground').listen((event) {
      serviceInstance.setAsForegroundService();
    });
    serviceInstance.on('setAsBackground').listen((event) {
      serviceInstance.setAsBackgroundService();
    });
    serviceInstance.on('stopService').listen((event) {
      print("Stop service received!");
      // activeTimer.cancel();
      // flutterLocalNotificationsPlugin.cancel(notificationId);
      serviceInstance.stopSelf();
    });
  }
  // Timer.periodic(const Duration(seconds: 10), (timer) async {
  if (serviceInstance is AndroidServiceInstance) {
    // if (await serviceInstance.isForegroundService()) {
    serviceInstance.setForegroundNotificationInfo(
      title: 'Go',
      content: 'Fetching Location ${DateTime.now()}',
    );
    await BackgroundLocationService().sendPartnerLatLng(() async {
      // serviceInstance.invoke('stopService');
      // Cancel the notification
      // activeTimer.cancel();
      // await flutterLocalNotificationsPlugin.cancel(notificationId);
      await serviceInstance.stopSelf();
      print("Background service stopped after!!!!!!!!!!!");
    });
    // }
  }
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance serviceInstance) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

class BackgroundLocationService {
  Future<void> initializeBackgroundService() async {
    var isRunning = await FlutterBackgroundService().isRunning();
    if (!isRunning) {
      final FlutterBackgroundService service = FlutterBackgroundService();
      await service.configure(
          iosConfiguration: IosConfiguration(
            onForeground: onStart,
          ),
          androidConfiguration: AndroidConfiguration(
            onStart: onStart,
            isForegroundMode: true,
            // notificationChannelId: notificationChannelId,
            // initialNotificationTitle: 'AWESOME SERVICE',
            // initialNotificationContent: 'Initializing...',
            // foregroundServiceNotificationId: notificationId,
          ));
      StaticService.service = service;
    }
  }

  sendPartnerLatLng(Function callback) async {
    print("Location Fetching Method Call!!!!!");

    await getCurrentLocation().then((value) async {
      print("Hello World>>>>>>>>>>>>>>>>>>>>$value");

      final timestamp = Timestamp.now()
          .millisecondsSinceEpoch; // Get current timestamp in milliseconds
      print("Checking for pending data in SharedPreferences...");

      try {
        if (await hasInternetConnection() == true) {
          final pendingData = await getLocalStoredLocations();

          print("pending data $pendingData");
          final Map<String, dynamic> requestBody = {
            "partnerId": "user4",
            "latitude": value?.latitude ?? 0,
            "longitude": value?.longitude ?? 0,
            "locationTime": timestamp, // Sending timestamp
            "missingCoordinates": pendingData
          };
          http
              .post(
            Uri.parse("http://10.68.124.73:8000/api/location"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode(requestBody),
          )
              .then((response) {
            print("Server Response: ${response.body}");
          });
        } else {
          throw Exception("No Internet");
        }
      } catch (e) {
        print("No Internet: Storing data in SharedPreferences...");

        await saveDataOffline({
          "latitude": value?.latitude ?? 0,
          "longitude": value?.longitude ?? 0,
          "locationTime": timestamp,
        });
      } finally {

        print("Call back called");
        callback();
      }
    });
  }

  Future<List> getLocalStoredLocations() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? pendingData = prefs.getStringList("pending_data");
    if (pendingData == null || pendingData.isEmpty) {
      print("No pending data to upload.");
      return [];
    } else {
      final snapshot = await FirebaseFirestore.instance
          .collection('Location')
          .where('partnerId', isEqualTo: 'user4')
          .orderBy('endTime', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final endTimeTimeStamp =
            await snapshot.docs.first.get('endTime') as Timestamp;
        print(
            'Last Coordinate is update on time : ${endTimeTimeStamp.toDate()}');
        final endTime = endTimeTimeStamp.toDate();

        final newPendingList = <String>[];
        for (var data in pendingData) {
          final decodeData = jsonDecode(data);
          print("data : $decodeData and  ${decodeData['locationTime'] is int}");
          if (decodeData['locationTime'] > endTime.millisecondsSinceEpoch) {
            newPendingList.add(data);
          }
        }

        await prefs.setStringList("pending_data", newPendingList);
        return newPendingList;
      } else {
        return pendingData;
      }
    }
  }

  // static Future<bool> hasInternetConnection() async {
  //   try {
  //     final result = await InternetAddress.lookup('example.com');
  //     return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
  //   } on SocketException catch (_) {
  //     return false;
  //   }
  // }

  Future<bool> hasInternetConnection() async {
    var connectivityResult = await Connectivity().checkConnectivity();

    // Check if device is connected to mobile or WiFi
    if (connectivityResult.last == ConnectivityResult.mobile ||
        connectivityResult.last == ConnectivityResult.wifi) {
      try {
        // Check actual internet access by pinging a website
        // final result = await InternetAddress.lookup('google.com');
        // if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return true; // Internet is available
        // }
      } catch (e) {
        return false; // No internet access
      }
    }

    return false; // No network connection
  }

  /// Save data in SharedPreferences when offline
  Future<void> saveDataOffline(Map<String, dynamic> data) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> pendingData = prefs.getStringList("pending_data") ?? [];

    final encodedValue = jsonEncode(data);
    // Store JSON-encoded data
    pendingData.add(encodedValue);
    await prefs.setStringList("pending_data", pendingData);
    print("Data saved offline: $data");
  }

  /// Upload pending data when the internet is available

  Future<Position?> getCurrentLocation() async {
    Position? position;
    bool isPermissionGranted = false;
    isPermissionGranted = await checkLocationPermissionInForeground();
    if (isPermissionGranted) {
      try {
        position = await Geolocator.getCurrentPosition();
        log('\nCurrent Latitude -> ${(position.latitude).toString()}'
            '\nCurrent Longitude -> ${(position.longitude).toString()}'
            '\nCurrent Accuracy -> ${(position.accuracy).toString()}');
      } catch (e) {
        log("Error in GetCurrentLocation Method:::::::::::::$e");
        return position;
      }
    }
    return position;
  }

  Future<bool> checkLocationPermissionInForeground() async {
    bool returnValue = true;
    LocationPermission permission;
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        log('Location permissions are denied');
        returnValue = false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      returnValue = false;
      await Geolocator.openAppSettings();
      log('Location permissions are permanently denied, we cannot request permissions.');
    }
    return returnValue;
  }

  Future<bool> checkNotificationPermission() async {
    bool returnValue = true;
    await Permission.notification.isDenied.then((value) {
      if (value) {
        Permission.notification.request();
      }
    });
    return returnValue;
  }
}
