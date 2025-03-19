// import 'package:call_log/call_log.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:device_info_plus/device_info_plus.dart';
// import 'package:flutter/material.dart';
//
// class CallLogService {
//   static Future<List<CallLogEntry>> fetchCallLogs(
//       DateTime from, DateTime to) async {
//     var entries = await CallLog.query(dateTimeFrom: from, dateTimeTo: to);
//     return entries.toList();
//   }
//
//   static Future<void> handleCallLogs(String userId) async {
//     DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
//     AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
//     String deviceId = androidInfo.id;
//     debugPrint("DEVICEID $deviceId");
//
//     DocumentReference _ref =
//         FirebaseFirestore.instance.collection('partner').doc(userId);
//     final docSnap = await _ref.get();
//     final document = docSnap.data();
//
//     Timestamp? lastCallLogUpdate = document != null &&
//             (document as Map<String, dynamic>).containsKey('lastCallLogUpdate')
//         ? document['lastCallLogUpdate']
//         : null;
//
//     final partnerCallLogsCollectionRef =
//         FirebaseFirestore.instance.collection('partnerCallLogs');
//
//     debugPrint(lastCallLogUpdate == null ? "New User" : "Old User");
//
//     // Determine fetch start time (new user or old user)
//     Timestamp startTime = lastCallLogUpdate ?? Timestamp.now();
//     List<CallLogEntry> callLogsList =
//         await fetchCallLogs(startTime.toDate(), DateTime.now());
//
//     // Exit early if no logs
//     if (callLogsList.isEmpty) {
//       lastCallLogUpdate == null
//           ? await _ref.set(
//               {'lastCallLogUpdate': Timestamp.now()}, SetOptions(merge: true))
//           : await _ref.update({'lastCallLogUpdate': Timestamp.now()});
//       return;
//     }
//
//     await uploadBatchData(callLogsList, _ref, partnerCallLogsCollectionRef,
//         userId, lastCallLogUpdate == null);
//   }
//
//   static Future<void> uploadBatchData(
//       List<CallLogEntry> callLogsList,
//       DocumentReference ref,
//       CollectionReference partnerCallLogsCollectionRef,
//       String userId,
//       bool isNew) async {
//     debugPrint("Call Logs: $callLogsList");
//     final batch = FirebaseFirestore.instance.batch();
//     for (int i = 0; i < callLogsList.length; i++) {
//       var log = callLogsList[i];
//
//       batch.set(partnerCallLogsCollectionRef.doc(), {
//         "log": {
//           "name": log.name,
//           "number": log.number,
//           "formattedNumber": log.formattedNumber,
//           "duration": log.duration,
//           "timestamp": Timestamp.fromMillisecondsSinceEpoch(log.timestamp ?? 0),
//           "phoneAccountId": log.phoneAccountId,
//           "simDisplayName": log.simDisplayName,
//           "cachedMatchedNumber": log.cachedMatchedNumber,
//           "cachedNumberType": log.cachedNumberType,
//           "cachedNumberLabel": log.cachedNumberLabel,
//           "callType": log.callType.toString(),
//         },
//         "partnerId": userId,
//         "logTime": Timestamp.now(),
//       });
//
//       // Commit batch every 100 writes
//       if ((i + 1) % 100 == 0 || i == callLogsList.length - 1) {
//         await batch.commit();
//         isNew
//             ? await ref.set({
//                 'lastCallLogUpdate':
//                     Timestamp.fromMillisecondsSinceEpoch(log.timestamp ?? 0)
//               }, SetOptions(merge: true))
//             : await ref.update({
//                 'lastCallLogUpdate':
//                     Timestamp.fromMillisecondsSinceEpoch(log.timestamp ?? 0)
//               });
//       }
//     }
//     isNew
//         ? await ref.set(
//             {'lastCallLogUpdate': Timestamp.now()}, SetOptions(merge: true))
//         : await ref.update({'lastCallLogUpdate': Timestamp.now()});
//   }
// }
