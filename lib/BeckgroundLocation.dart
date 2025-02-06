import 'dart:async';
import 'dart:developer';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

@pragma('vm:entry-point')
void onStart(ServiceInstance serviceInstance) async {
  DartPluginRegistrant.ensureInitialized();
  // await Firebase.initializeApp(
  //     options: FirebaseOptions(
  //         apiKey: "AIzaSyBuIDbowOMN6lmWrtRzOGJx-Hr2Zdwxs9A",
  //         appId: "1:689526460795:android:4c801f97db5fd3f972adde",
  //         messagingSenderId: "689526460795",
  //         projectId: "todocheck-c219b")
  // );
  if (serviceInstance is AndroidServiceInstance) {
    serviceInstance.on('setAsForeground').listen((event) {
      serviceInstance.setAsForegroundService();
    });
    serviceInstance.on('setAsBackground').listen((event) {
      serviceInstance.setAsBackgroundService();
    });
    serviceInstance.on('stopService').listen((event) {
      serviceInstance.stopSelf();
    });
  }
  Timer.periodic(const Duration(seconds: 10), (timer) async {
    if (serviceInstance is AndroidServiceInstance) {
      if (await serviceInstance.isForegroundService()) {
        serviceInstance.setForegroundNotificationInfo(
          title: 'Go',
          content: 'Fetching Driver Location ${DateTime.now()}',
        );
        BackgroundLocationService().sendDriverLatLng();
      }
    }
    serviceInstance.invoke('update');
  });
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance serviceInstance) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

class BackgroundLocationService {
  Future<void> initializeBackgroundService() async {
    final FlutterBackgroundService service = FlutterBackgroundService();
    await service.configure(
        iosConfiguration: IosConfiguration(
          onForeground: onStart,
        ),
        androidConfiguration: AndroidConfiguration(
          onStart: onStart,
          isForegroundMode: true,
        ));
    service.startService();
  }

  sendDriverLatLng() {
    getCurrentLocation(showLoader: false).then((value) async {
      Map<String, dynamic> data = {
        "id": "1",
        "name": "kunal auto ",
        "lat": value!.latitude.toString(),
        "lan": value!.longitude.toString(),
        "insetrd_at": DateTime.now(),
        "updated_at": DateTime.now()
      };
      try {
        // Firebasemainhelper().createDocumentWithAutoId('GetloctionData', data);
      } on Exception catch (e) {
        print(e.toString());
      }
    });
  }

  Future<Position?> getCurrentLocation({bool? showLoader}) async {
    Position? position;
    bool isPermissionGranted = false;
    isPermissionGranted = await checkLocationPermission();
    if (isPermissionGranted) {
      try {
        position = await Geolocator.getCurrentPosition();
        log('\nCurrent Latitude -> ${(position.latitude).toString()}'
            '\nCurrent Longitude -> ${(position.longitude).toString()}'
            '\nCurrent Accuracy -> ${(position.accuracy).toString()}');
      } catch (e) {
        log(e.toString());
        return position;
      }
    }
    return position;
  }

  Future<bool> checkLocationPermission() async {
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
