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

      final lat = 0;
      final long = 0;
      // if (value == null) {
      //   print("Error: Unable to fetch location");
      //   callback();
      //   return;
      // }

      final serverTime = Timestamp.now();
      String docId = Timestamp.now().toDate().toString();

      Map<String, dynamic> data = {
        "Location":
            value == null ? [lat, long] : [value.latitude, value.longitude],
        "lastUpdated": serverTime,
      };

      try {
        print("Checking for pending data in SharedPreferences...");

        if (await hasInternetConnection() == true) {
          await uploadPendingData(); // Upload pending data if available
          print("Uploading new location data to Firestore...");
          await FirebaseFirestore.instance
              .collection("LOCATION")
              .doc("user2")
              .collection("data")
              .doc(docId)
              .set(data)
              .catchError((onError) async {
            // print("No Internet: Storing data in SharedPreferences... $onError");
            // await saveDataOffline(data);
          });
          print("Firestore Updated: $data");
        } else {
          throw Exception("No Internet");
        }
      } catch (e) {
        print("No Internet: Storing data in SharedPreferences...");
        data['docId'] = docId;
        await saveDataOffline(data);
      } finally {
        callback();
      }
    });
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

    // Remove Firestore-specific objects before saving
    data["lastUpdated"] =
        (data["lastUpdated"] as Timestamp).millisecondsSinceEpoch;

    final encodedValue = jsonEncode(data);
    // Store JSON-encoded data
    pendingData.add(encodedValue);
    await prefs.setStringList("pending_data", pendingData);
    print("Data saved offline: $data");
  }

  /// Upload pending data when the internet is available
  Future<void> uploadPendingData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? pendingData = prefs.getStringList("pending_data");

    if (pendingData == null || pendingData.isEmpty) {
      print("No pending data to upload.");
      return;
    }

    print("Uploading pending location data to Firestore...");
    for (String jsonData in pendingData) {
      Map<String, dynamic> data = jsonDecode(jsonData);

      // Convert stored timestamp back to Firestore Timestamp
      data["lastUpdated"] =
          Timestamp.fromMillisecondsSinceEpoch(data["lastUpdated"]);

      try {
        String docId = data['docId'];
        await FirebaseFirestore.instance
            .collection("LOCATION")
            .doc("user2")
            .collection("data")
            .doc(docId)
            .set(data);

        print("Uploaded pending data: $data");
      } catch (e) {
        print("Error uploading pending data: $e");
        return;
      }
    }

    // Clear pending data after successful upload
    await prefs.remove("pending_data");
    print("All pending data uploaded and cleared.");
  }

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

  // Future<bool> checkLocationPermission() async {
  //   // Step 1: Request foreground location permission first
  //   PermissionStatus foregroundStatus = await Permission.locationWhenInUse.request();
  //
  //   // If foreground permission is denied, return false
  //   if (foregroundStatus != PermissionStatus.granted) {
  //     log("Foreground location permission denied.");
  //     return false;
  //   }
  //
  //   // Step 2: Now request background location permission
  //   PermissionStatus backgroundStatus = await Permission.locationAlways.request();
  //
  //   // Step 3: If background permission is permanently denied, open settings
  //   if (backgroundStatus == PermissionStatus.permanentlyDenied) {
  //     log('Background location permission permanently denied. Opening settings...');
  //     await openAppSettings();
  //     return false;
  //   }
  //
  //   // Step 4: Return true if either "granted" or "limited" (iOS)
  //   return backgroundStatus == PermissionStatus.granted || backgroundStatus == PermissionStatus.limited;
  // }

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
