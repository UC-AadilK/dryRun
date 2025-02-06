import 'package:device_info_plus/device_info_plus.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:permission_handler/permission_handler.dart';
void requestIgnoreBatteryOptimization() async {
  final androidInfo = await DeviceInfoPlugin().androidInfo;
  // final packageName = androidInfo.packageName;

  const intent = AndroidIntent(
    action: 'android.settings.IGNORE_BATTERY_OPTIMIZATION_SETTINGS',
  );

  intent.launch();
}



Future<void> requestPermissions() async {
  if (await Permission.location.isDenied) {
    await Permission.location.request();
  }
  if (await Permission.notification.isDenied) {
    await Permission.notification.request();
  }
}
