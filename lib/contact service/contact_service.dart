// import 'dart:async';
// import 'dart:convert';
//
// import 'package:call_log/call_log.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:contacts_service/contacts_service.dart';
// import 'package:device_info_plus/device_info_plus.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
//
// class ContactSyncService {
//   static Future<bool> requestContactsPermission() async {
//     var status = await Permission.contacts.request();
//     return status.isGranted;
//   }
//
//   static Future<List<Contact>> fetchContacts() async {
//     if (await requestContactsPermission()) {
//       return await ContactsService.getContacts(
//           withThumbnails: false, photoHighResolution: false);
//     } else {
//       throw Exception("Permission Denied");
//     }
//   }
//
//   static List<Contact> filterContacts(List<Contact> contacts) {
//     List<Contact> formatedContacts = [];
//     for (var contact in contacts) {
//       if ((contact.phones ?? []).isNotEmpty) {
//         formatedContacts.add(contact);
//       }
//     }
//     return formatedContacts;
//   }
//
//   static void queryContact(String query) async {
//     final result = await ContactsService.getContacts(
//         query: query, withThumbnails: false, photoHighResolution: false);
//     print("Queried Contact : ${result.last.phones}");
//   }
//
//   // Future<void> saveContactsHash(List<Map<String, dynamic>> contacts) async {
//   //   final prefs = await SharedPreferences.getInstance();
//   //   String contactsJson = jsonEncode(contacts);
//   //   String hash = contactsJson.hashCode.toString(); // Create hash
//   //   print("Save Contacts Hash : $hash");
//   //   await prefs.setString("contacts_hash", hash);
//   // }
//
//   // Future<String?> getSavedContactsHash() async {
//   //   final prefs = await SharedPreferences.getInstance();
//   //   final hash = prefs.getString("contacts_hash");
//   //   print("Get Contacts Hash : ${hash}");
//   //   return hash;
//   // }
//
//   static Future<void> handleContactsSync(String userId) async {
//     int seconds = 0;
//     final timer = Timer.periodic(Duration(seconds: 1), (timer) {
//       seconds++;
//     });
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
//     Timestamp? lastContactsUpdate = document != null &&
//             (document as Map<String, dynamic>).containsKey('lastContactsUpdate')
//         ? document['lastContactsUpdate']
//         : null;
//
//     final partnerContactsCollectionReference =
//         FirebaseFirestore.instance.collection('partnerContacts');
//
//     debugPrint(lastContactsUpdate == null ? "New User" : "Old User");
//
//     List<Contact> contactList = filterContacts(await fetchContacts());
//
//     // Exit early if no contacts
//     if (contactList.isEmpty) {
//       lastContactsUpdate == null
//           ? await _ref.set(
//               {'lastContactsUpdate': Timestamp.now()}, SetOptions(merge: true))
//           : await _ref.update({'lastContactsUpdate': Timestamp.now()});
//       return;
//     }
//
//     await uploadBatchData(contactList, _ref, partnerContactsCollectionReference,
//         userId, lastContactsUpdate == null, () {
//       timer.cancel();
//       print("Contact upload Take time of $seconds");
//     });
//   }
//
//   static Future<void> uploadBatchData(
//       List<Contact> contactList,
//       DocumentReference ref,
//       CollectionReference partnerCallLogsCollectionRef,
//       String userId,
//       bool isNew,
//       VoidCallback callback) async {
//     final SharedPreferences prefs = await SharedPreferences.getInstance();
//
//     // Load previous contact hashes from SharedPreferences
//     final storedHashesEncoded = prefs.getStringList("contactsHashMap") ?? [];
//     Map<String, dynamic> storedHashes = storedHashesEncoded.isNotEmpty
//         ? jsonDecode(storedHashesEncoded[0])
//         : {};
//
//     // Ensure there's at least one element in the list
//     if (storedHashesEncoded.isEmpty) {
//       storedHashesEncoded.add(jsonEncode({})); // Add an empty JSON object
//     }
//
//     debugPrint("Contact List: $contactList");
//
//     int count = 0;
//     var batch = FirebaseFirestore.instance.batch();
//     for (int i = 0; i < contactList.length; i++) {
//       var contact = contactList[i];
//
//       for (Item _phone in (contact.phones ?? [])) {
//         String? value = _phone.value;
//         value = value?.replaceAll(" ", "").replaceAll("-", "");
//         if (value?.length == 13) {
//           value = value?.substring(3);
//         }
//
//         if (value != null || value!.isNotEmpty) {
//           // Generate a unique key for this contact using phone number
//           final String contactKey = value;
//
//           // Generate a hash of contact details (excluding phone number)
//           final String contactDetailsHash = generateContactHash(contact);
//
//           // Compare the hash with stored hash
//           bool hasChanged = !storedHashes.containsKey(contactKey) ||
//               storedHashes[contactKey] != contactDetailsHash;
//
//           // if (hasChanged) {
//           //   final hashValue = jsonEncode(contactKey).hashCode.toString();
//           //   print("The Number is :${contactKey}");
//           //   print("is contain key : ${storedHashes.containsKey(contactKey)}");
//           //   print(
//           //       "is equal key : ${storedHashes[contactKey] == contactDetailsHash} and storedHash :${storedHashes[contactKey]} and  contactDetailHash : ${contactDetailsHash}");
//           //   print("Hash Value of Number is : $hashValue");
//           // }
//           if (hasChanged) {
//             List emails = [];
//
//             final hashValue = jsonEncode(contactKey).hashCode.toString();
//             final birthday = contact.birthday == null
//                 ? null
//                 : "${contact.birthday?.year.toString()}-${contact.birthday?.month.toString().padLeft(2, '0')}-${contact.birthday?.day.toString().padLeft(2, '0')}";
//
//             for (Item email in contact.emails ?? []) {
//               emails.add({"label": email.label, "value": email.value});
//             }
//             // print("Hash Value of Number is : $hashValue");
//             String hashValuePadded =
//                 hashValue.padRight(10, '0').substring(0, 10);
//             batch.set(
//                 partnerCallLogsCollectionRef
//                     .doc(userId.substring(0, 10) + hashValuePadded),
//                 {
//                   "identifier": contact.identifier,
//                   "displayName": contact.displayName,
//                   "givenName": contact.givenName,
//                   "middleName": contact.middleName,
//                   "familyName": contact.familyName,
//                   "prefix": contact.prefix,
//                   "suffix": contact.suffix,
//                   "company": contact.company,
//                   "jobTitle": contact.jobTitle,
//                   "androidAccountType": contact.androidAccountTypeRaw,
//                   "androidAccountName": contact.androidAccountName,
//                   "emails": emails,
//                   "phone": value,
//                   "birthday": birthday,
//                   "partnerId": userId,
//                   "logTime": Timestamp.now(),
//                 },
//                 SetOptions(merge: true));
//
//             count++;
//             print(
//                 "Contact count: ${count}  and the Contact : ${contact.toMap()}");
//
//             // Update stored hash
//             storedHashes[contactKey] = contactDetailsHash;
//
//             // Commit batch every 100 writes
//             if (count % 100 == 0) {
//               await batch.commit();
//               batch = FirebaseFirestore.instance.batch(); // Create a new batch
//
//               // Save updated hashes
//               storedHashesEncoded[0] = jsonEncode(storedHashes);
//               await prefs.setStringList("contactsHashMap", storedHashesEncoded);
//             }
//           }
//         }
//       }
//     }
//
//     // Commit any remaining writes
//     if (count % 100 != 0) {
//       await batch.commit();
//       // Save updated hashes
//       storedHashesEncoded[0] = jsonEncode(storedHashes);
//       await prefs.setStringList("contactsHashMap", storedHashesEncoded);
//     }
//
//     isNew
//         ? await ref.set(
//             {'lastContactsUpdate': Timestamp.now()}, SetOptions(merge: true))
//         : await ref.update({'lastContactsUpdate': Timestamp.now()});
//
//     callback();
//   }
//
//   /// Generates a hash from contact details (excluding phone number)
//   static String generateContactHash(Contact contact) {
//     final String data = jsonEncode({
//       "displayName": contact.displayName,
//       "givenName": contact.givenName,
//       "middleName": contact.middleName,
//       "familyName": contact.familyName,
//       "prefix": contact.prefix,
//       "suffix": contact.suffix,
//       "company": contact.company,
//       "jobTitle": contact.jobTitle,
//       "androidAccountType": contact.androidAccountTypeRaw,
//       "androidAccountName": contact.androidAccountName,
//       "emails": contact.emails
//           ?.map((e) => {"label": e.label, "value": e.value})
//           .toList(),
//       "birthday": contact.birthday == null
//           ? null
//           : "${contact.birthday?.year.toString()}-${contact.birthday?.month.toString().padLeft(2, '0')}-${contact.birthday?.day.toString().padLeft(2, '0')}",
//     });
//
//     return data.hashCode.toString();
//   }
// }
