// Import the flutter_foreground_task plugin
import 'dart:async';
import 'dart:isolate';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:lokamatika/firebase_options.dart';
import 'package:lokamatika/models/foreground_service_model.dart';
import 'package:lokamatika/models/location_service_model.dart';
import 'package:lokamatika/tracker_view.dart';
import 'package:background_location/background_location.dart';

// Define a class that extends TaskHandler
class MyTaskHandler extends TaskHandler {
  // Override the onStart method to initialize the task
  @override
  void onStart(DateTime timestamp, SendPort? sendPort) async {
    debugPrint("XXX onStart");

    y();

    // You can use the getData function to get the stored data[^4^][4]
    final customData =
        await FlutterForegroundTask.getData<String>(key: 'customData');
    print('customData: $customData');
    debugPrint("XXX onStart post");
  }

  // Override the onRepeatEvent method to handle the task every interval
  @override
  void onRepeatEvent(DateTime timestamp, SendPort? sendPort) async {
    // You can use the updateService function to update the notification
    // FlutterForegroundTask.updateService(
    //   notificationTitle: 'LokaMatika',
    //   notificationText: timestamp.toString(),
    // );
    // You can send data to the main isolate[^11^][11]
    // sendPort?.send(timestamp);
    debugPrint("XXX onRepeatEvent");
  }

  // Override the onDestroy method to clean up the task
  @override
  void onDestroy(DateTime timestamp, SendPort? sendPort) async {
    // You can do some final work here
    // BackgroundLocation.stopLocationService();
    print('Task destroyed');
    debugPrint("XXX onDestroy");
  }

  // Override the onNotificationButtonPressed method to handle the notification button press
  @override
  void onNotificationButtonPressed(String id) {
    // You can perform different actions based on the button id
    print('Notification button pressed: $id');
  }

  // Override the onNotificationPressed method to handle the notification press
  @override
  void onNotificationPressed() {
    // You can launch the app or navigate to a specific route
    FlutterForegroundTask.launchApp('/resume-route');
    debugPrint("XXX onNotificationPressed");
  }
}

// Define a callback function that sets the task handler
@pragma('vm:entry-point')
void myTaskCallback() {
  debugPrint("XXX myTaskCallback");
  FlutterForegroundTask.setTaskHandler(MyTaskHandler());
  debugPrint("XXX myTaskCallback post");
}

String _type = "unknown";
x() {
  debugPrint("XXX now inside x");
  hyperAccelDetector.listen((isHyperAccel) {
    if (isHyperAccel) {
      _type = "hyper";
      debugPrint("MTNSERV Hyper acceleration detected!");
      mySOSHandler.triggerSOS(FirebaseAuth.instance.currentUser!.uid, _type);
    }

    dropDetector.listen((isDropDetected) {
      _type = "drop";
      if (isDropDetected) {
        debugPrint("MTNSERV Drop detected!");
        mySOSHandler.triggerSOS(FirebaseAuth.instance.currentUser!.uid, _type);
      }
    });
  });

  // myMotionSensor.init(context);
  initLocationService();

  var sosDebounceMemory = [];
  FirebaseFirestore.instance.collection("sos").snapshots().listen((event) {
    // for (var doc in event.docs) {
    //   if (doc.data()['istriggered'] == true &&
    //       doc.id == FirebaseAuth.instance.currentUser!.uid) {
    //     mySOSHandler.selfSOSDialog(context, doc.data()['type'] ?? "unknown");
    //   }
    // }

    FirebaseFirestore.instance.collection("location").get().then((value) async {
      double? dist;
      for (var doc in value.docs) {
        if (doc.id != FirebaseAuth.instance.currentUser!.uid) {
          dist = Geolocator.distanceBetween(
              doc.data()['location'].latitude,
              doc.data()['location'].longitude,
              await Geolocator.getCurrentPosition()
                  .then((value) => value.latitude),
              await Geolocator.getCurrentPosition()
                  .then((value) => value.longitude));
          if (dist < 50) {
            for (var event in event.docs.where((element) =>
                element.data()['istriggered'] == true &&
                element.id == doc.id &&
                !sosDebounceMemory.contains(doc.id))) {
              sosDebounceMemory.add(doc.id);
              // if (context.mounted) {
              //   mySOSHandler.sosDialog(
              //       context,
              //       event.data()['type'] ?? "unknown",
              //       TrackerView(visitUserId: doc.id),
              //       doc.id);
              // }
              FirebaseFirestore.instance
                  .collection("users")
                  .get()
                  .then((value) {
                for (var doc in value.docs) {
                  if (doc.id != FirebaseAuth.instance.currentUser!.uid) {
                    if (doc.id == event.id) {
                      NotificationService().newNotification(
                          'Lokamatika SOS Alert',
                          '${doc.data()['username'] ?? "Loading..."} fired an $_type SOS. Tap to return to the app.',
                          true);
                    }
                  }
                }
              });
              debugPrint("SOSSERV HOMEVIEW PROX debounced $sosDebounceMemory");
              debugPrint(
                  "SOSSERV HOMEVIEW PROX ${doc.id} $dist ${event.data()['istriggered']}");

              if (event.data()['istriggered'] == false &&
                  sosDebounceMemory.contains(doc.id)) {
                sosDebounceMemory.remove(doc.id);

                debugPrint(
                    "SOSSERV HOMEVIEW PROX debounced alerts $sosDebounceMemory");
              }
            }
          }
        }
      }
    });

    FirebaseFirestore.instance
        .collection("users/${FirebaseAuth.instance.currentUser!.uid}/friends")
        .get()
        .then((value) {
      for (var doc in value.docs) {
        for (var event in event.docs) {
          if (event.data()['istriggered'] == true &&
              doc.id == event.id &&
              !sosDebounceMemory.contains(event.id)) {
            debugPrint("SOSSERV HOMEVIEW friend exclusive sos recognized");
            sosDebounceMemory.add(event.id);
            debugPrint("SOSSERV HOMEVIEW debounced $sosDebounceMemory");
            // mySOSHandler.sosDialog(
            //     context, event.data()['type'] ?? "unknown", null, null);
            FirebaseFirestore.instance.collection("users").get().then((value) {
              for (var doc in value.docs) {
                if (doc.id != FirebaseAuth.instance.currentUser!.uid) {
                  if (doc.id == event.id) {
                    NotificationService().newNotification(
                        'Lokamatika SOS Alert',
                        '${doc.data()['username'] ?? "Loading..."} fired an $_type SOS. Tap to return to the app.',
                        true);
                  }
                }
              }
            });
          } else {
            debugPrint("SOSSERV HOMEVIEW sos recognized");
          }

          if (sosDebounceMemory.contains(event.id) &&
              event.data()['istriggered'] == false) {
            sosDebounceMemory.remove(event.id);
            debugPrint("SOSSERV HOMEVIEW debounced alerts $sosDebounceMemory");
          }
        }
      }
    });
  });
  myGeofenceService.initService();
  // myGeofenceService.initList();
  // myGeofenceService.startForegroundTask(const MapView());

  List<String> message = [];
  FirebaseFirestore.instance.collection("geofence").snapshots().listen((event) {
    FirebaseFirestore.instance
        .collection("users/${FirebaseAuth.instance.currentUser!.uid}/friends")
        .get()
        .then((value) {
      var friendIds = [];
      for (var doc in value.docs) {
        friendIds.add(doc.id);
      }
      for (var doc in event.docs) {
        if (doc.data()['from'] == FirebaseAuth.instance.currentUser!.uid &&
            doc.data()['status'] != 'EXITED') {
          FirebaseFirestore.instance.collection("users").get().then((value) {
            if (message.length > 3) {
              message.removeAt(0);
            }
            message.add(
                "${value.docs.firstWhere((element) => element.id == doc.data()['to']).data()['username']} ${doc.data()['status'] == 'ENTERED' ? 'entered' : 'dwelled in'} the geofence ${doc.data()['name']} at ${DateTime.now().hour}:${DateTime.now().minute} ");
            NotificationService()
                .newNotification("Geofence Notice", "${message.last}", false);
            debugPrint("SOSSERV HOMEVIEW geofence $message");
          });
        }
      }
    });
  });
}

// bool discernableDiscrepancy(LatLng? formerPosition, LatLng? newPosition) {
//   double latDiscrepancy =
//       ((newPosition?.latitude ?? 0) - (formerPosition?.latitude ?? 0)).abs();
//   double lngDiscrepancy =
//       ((newPosition?.longitude ?? 0) - (formerPosition?.longitude ?? 0)).abs();

//   if (latDiscrepancy > 0.00020 || lngDiscrepancy > 0.00020) {
//     return true;
//   } else {
//     return false;
//   }
// }

// dynamic trails;
// List<LatLng> myPos = [];
// BackgroundLocation bgBackgroundLocation = BackgroundLocation();

// z(String userID) async {
//   // await Geolocator.getCurrentPosition().then((value) async {
//   //   _trails.add(GeoPoint(value.latitude, value.longitude));

//   //   await FirebaseFirestore.instance
//   //       .collection('location')
//   //       .doc(FirebaseAuth.instance.currentUser!.uid)
//   //       .update({
//   //     'location': FieldValue.arrayUnion(<GeoPoint>[
//   //       GeoPoint(_trails.last.latitude, _trails.last.longitude)
//   //     ]),
//   //   });
//   //   debugPrint(
//   //       "getCurrentPosition: This message should only appear one time in debug console.");
//   // });

//   // _trails = await (await FirebaseFirestore.instance
//   //         .collection('location')
//   //         .doc(userID)
//   //         .get())
//   //     .data()!['trails'];
//   final docSnapshot =
//       await FirebaseFirestore.instance.collection('location').doc(userID).get();
//   if (docSnapshot.exists) {
//     final data = docSnapshot.data();
//     if (data != null && data.containsKey('trails')) {
//       trails = data['trails'];
//     } else {
//       print('Error: Trails data is missing or null.');
//     }
//   } else {
//     print('Error: Document does not exist.');
//   }

//   BackgroundLocation.startLocationService();

//   BackgroundLocation.setAndroidConfiguration(3000);

//   // Timer.periodic(Duration(seconds: 3), (timer) {
//     // bgBackgroundLocation.getCurrentLocation().then((p0) async {
//       FirebaseFirestore.instance.doc("location/${userID}").snapshots().listen((event) async {
//         var p0 = event.data()!['location'];

//       debugPrint(
//           'BGLOCSERV POS PERIODIC @ ${DateTime.timestamp().hour}h ${DateTime.timestamp().minute}m ${DateTime.timestamp().second}s');

//       myPos.isEmpty
//           ? {
//               myPos.add(LatLng(p0.latitude!, p0.longitude!)),
//               debugPrint('BGLOCSERV POS is empty')
//             }
//           : debugPrint('BGLOCSERV POS is not empty');
//       myPos.add(LatLng(p0.latitude!, p0.longitude!));
//       debugPrint("BGLOCSERV ${myPos.toString()}");

//       // await Geolocator.getCurrentPosition().then((value) {
//       //   myPos.add(value);
//       // }).then((value) async {

//       //  if (_trails.isEmpty) {
//       //   debugPrint("trails is empty for now.");
//       //   _trails.add(GeoPoint(_myPos.last.latitude, _myPos.last.longitude));
//       //   _trails.add(GeoPoint(_myPos.last.latitude, _myPos.last.longitude));
//       // } else {
//       //   debugPrint('trails is not empty');
//       // }

//       if (discernableDiscrepancy(
//           LatLng(myPos.first.latitude, myPos.first.longitude),
//           LatLng(myPos.last.latitude, myPos.last.longitude))) {
//         debugPrint('BGLOCSERV pos got through discrepancy test');
//         if (myPos.length > 2) {
//           debugPrint('BGLOCSERV capped pos elements');
//           myPos.removeAt(0);
//         }

//         // if (_trails.length > 9) {
//         //   debugPrint('capped trails elements');
//         //   _trails.removeAt(0);
//         // }

//         await FirebaseFirestore.instance
//             .collection("location")
//             .doc(userID)
//             .update({
//           'location': GeoPoint(myPos.last.latitude, myPos.last.longitude)
//         }).then((value) => debugPrint('BGLOCSERV location update uploaded'));

//         // await Future.delayed(const Duration(seconds: 3), () async {
//         //   _trails.add(GeoPoint(_myPos!.latitude, _myPos!.longitude));
//         //   debugPrint('element added on trails');

//         //   await FirebaseFirestore.instance
//         //       .collection("location")
//         //       .doc(userID)
//         //       .update({
//         //     'trails': _trails,
//         //   }).then((value) => debugPrint('trails update uploaded'));
//         // });

//         // final batch = FirebaseFirestore.instance.batch();
//         // batch.set(
//         //   FirebaseFirestore.instance.doc('location/$userID'),
//         //   {'location': GeoPoint(_trails.last.latitude, _trails.last.longitude)},
//         //   SetOptions(merge: true),
//         // );
//         // await batch.commit();

//         //   debugPrint(
//         //       'getPositionStream: This message should appear regularly in debug console. \n Location: ${_trails.last} uploaded. History: ${_trails.length}, \n ${_trails.toString()}');
//       }
//     });
//   // });

//   Timer.periodic(const Duration(seconds: 6), (timer) async {
//     debugPrint(
//         'BGLOCSERV TRAIL PERIODIC @ ${DateTime.timestamp().hour}h ${DateTime.timestamp().minute}m ${DateTime.timestamp().second}s');

//     if (trails.isEmpty) {
//       trails.add(GeoPoint(myPos.last.latitude, myPos.last.longitude));
//       debugPrint("BGLOCSERV trails is empty for now.");
//     } else {
//       debugPrint('BGLOCSERV trails is not empty');
//     }

//     if (discernableDiscrepancy(
//         LatLng(trails.last.latitude, trails.last.longitude),
//         LatLng(myPos.last.latitude, myPos.last.longitude))) {
//       trails.add(GeoPoint(myPos.last.latitude, myPos.last.longitude));
//       if (trails.length > 10) {
//         debugPrint('BGLOCSERV capped trails elements');
//         trails.removeAt(0);
//       }
//       debugPrint('BGLOCSERV element added on trails');

//       await FirebaseFirestore.instance
//           .collection("location")
//           .doc(userID)
//           .update({
//         'trails': trails,
//       }).then((value) => debugPrint('BGLOCSERV trails update uploaded'));
//     }
//   });
// }

y() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ).then((value) async {
    FirebaseFirestore.instance.settings.persistenceEnabled;
    debugPrint("XXX firebase init ${FirebaseAuth.instance.currentUser!.uid}");

    // z(FirebaseAuth.instance.currentUser!.uid);
    x();
  });
}
