import 'dart:async';
import 'package:lokamatika/models/location_service_model.dart';
import 'package:background_location/background_location.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:curved_labeled_navigation_bar/curved_navigation_bar.dart';
import 'package:curved_labeled_navigation_bar/curved_navigation_bar_item.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lokamatika/models/foreground_service_model.dart';
import 'package:lokamatika/models/manual_sos_model.dart';
import 'package:lokamatika/samp.dart';
import 'package:lokamatika/tracker_view.dart';
import 'map_view.dart';
import 'friends_view.dart';
import 'settings_view.dart';

PageController pageController = PageController();

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => HomeViewState();
}

class HomeViewState extends State<HomeView> {
  int _selectedIndex = 0;

  String type = "unknown";
  int _batteryLevel = 0;
  final Battery _battery = Battery();
  late Timer _batteryUpdateTimer;

  bool navBarTap = false;

  @override
  void initState() {
    super.initState();
    pageController = PageController(initialPage: _selectedIndex);
    // myMotionSensor.init(context);
    locationServiceModel.getPeriodicPositionAndUploadIfDiscernableNonBG(
        FirebaseAuth.instance.currentUser!.uid);
    sos();
    _getBatteryLevel();
    debugPrint(_batteryLevel.toString());
  }

  @override
  void dispose() {
    pageController.dispose();
    // myMotionSensor.cancel();
    _batteryUpdateTimer.cancel();
    super.dispose();
  }

  Future<void> _getBatteryLevel() async {
    final batteryLevel = await _battery.batteryLevel;
    _batteryLevel = batteryLevel;
    _updateBatteryLevelInFirebase(batteryLevel);

    if (batteryLevel >= 20) {
      // Upload battery level to Firebase every one hour
      _batteryUpdateTimer = Timer.periodic(const Duration(hours: 1), (timer) {
        _updateBatteryLevelInFirebase(batteryLevel);
      });
    } else {
      // Upload battery level to Firebase immediately
      _updateBatteryLevelInFirebase(batteryLevel);
    }
  }

  Future<void> _updateBatteryLevelInFirebase(int batteryLevel) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('profilepicture')
            .doc(user.uid)
            .set({'batteryLevel': batteryLevel}, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Error updating battery level: $e');
    }
  }

  void _onItemTapped(int index) {
    navBarTap = true;
    debugPrint("onItemTapped $index, selectedIndex $_selectedIndex");
    sosCounter();
    if (_selectedIndex == 0 && index == 2) {
      navBarTap = true;
      pageController.animateToPage(
        1,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
      // _selectedIndex = 1;
      
      navBarTap = true;
      pageController.animateToPage(
        2,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
      _selectedIndex = 2;
      // long = false;
    } else if (_selectedIndex == 2 && index == 0) {
      navBarTap = true;
      pageController.animateToPage(
        1,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
      // _selectedIndex = 1;
      
      navBarTap = true;
      pageController.animateToPage(
        0,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
      _selectedIndex = 0;
    } else if (_selectedIndex != index) {
      _selectedIndex = index;
      pageController.animateToPage(
        _selectedIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onPageChanged(int index) {
    debugPrint(index.toString());
    debugPrint(_selectedIndex.toString());
    // if (navBarTap == true) {
    //   null;
    // } else if (_selectedIndex != index && navBarTap == false) {
    //   setState(() {
    //     _selectedIndex = index;
    //   });
    // }
    if (!navBarTap) {
      _selectedIndex = index;
      setState(() {});
    }
    navBarTap = false;
  }

  @override
  Widget build(BuildContext context) {
    return WillStartForegroundTask(
      onWillStart: () async {
        // BackgroundLocation.stopLocationService();
        return true;
      },
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'foreground_service',
        channelName: 'Foreground Service Notification',
        channelDescription:
            'This notification appears when the foreground service is running.',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        // iconData: const NotificationIconData(
        //   resType: ResourceType.drawable,
        //   resPrefix: ResourcePrefix.ic,
        //   name: 'launcher',
        // ),
        // buttons: [
        //   const NotificationButton(id: 'sendButton', text: 'Send'),
        //   const NotificationButton(id: 'testButton', text: 'Test'),
        // ],
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: const ForegroundTaskOptions(
        interval: 5000,
        isOnceEvent: false,
        autoRunOnBoot: true,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
      notificationTitle: 'Foreground Service is running',
      notificationText: 'Tap to return to the app',
      callback: myTaskCallback,
      child: Scaffold(
        body: PageView(
          controller: pageController,
          onPageChanged: _onPageChanged,
          children: const [
            MapView(),
            FriendsView(),
            SettingsView(),
          ],
        ),
        backgroundColor: Colors.amber,
        bottomNavigationBar: CurvedNavigationBar(
          index: _selectedIndex,
          items: const [
            CurvedNavigationBarItem(
              child: Icon(
                Icons.map,
                color: Colors.amber,
              ),
              label: 'Map',
              labelStyle:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            CurvedNavigationBarItem(
                child: Icon(Icons.people, color: Colors.amber),
                label: 'Friends',
                labelStyle: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            CurvedNavigationBarItem(
                child: Icon(Icons.settings, color: Colors.amber),
                label: 'Settings',
                labelStyle: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ],
          backgroundColor: Colors.amber,
          color: Colors.deepPurple,
          buttonBackgroundColor: Colors.deepPurple,
          animationCurve: Curves.linear,
          animationDuration: const Duration(milliseconds: 350),
          onTap: _onItemTapped,
        ),
      ),
    );
  }

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  void sos() {
    hyperAccelDetector.listen((isHyperAccel) {
      if (isHyperAccel) {
        type = "hyper";
        debugPrint("MTNSERV Hyper acceleration detected!");
        mySOSHandler.triggerSOS(FirebaseAuth.instance.currentUser!.uid, type);
      }

      dropDetector.listen((isDropDetected) {
        type = "drop";
        if (isDropDetected) {
          debugPrint("MTNSERV Drop detected!");
          mySOSHandler.triggerSOS(FirebaseAuth.instance.currentUser!.uid, type);
        }
      });
    });

    

    var sosDebounceMemory = [];
    FirebaseFirestore.instance.collection("sos").snapshots().listen((event) {
      for (var doc in event.docs) {
        if (doc.data()['istriggered'] == true &&
            doc.id == FirebaseAuth.instance.currentUser!.uid) {
          mySOSHandler.selfSOSDialog(context, doc.data()['type'] ?? "unknown");
        }
      }

      FirebaseFirestore.instance
          .collection("location")
          .get()
          .then((value) async {
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
            if (dist < 100) {
              for (var event in event.docs.where((element) =>
                  element.data()['istriggered'] == true &&
                  element.id == doc.id &&
                  !sosDebounceMemory.contains(doc.id))) {
                sosDebounceMemory.add(doc.id);
                if (context.mounted) {
                  mySOSHandler.sosDialog(
                      context,
                      event.data()['type'] ?? "unknown",
                      TrackerView(visitUserId: doc.id),
                      doc.id);
                }
                debugPrint(
                    "SOSSERV HOMEVIEW PROX debounced $sosDebounceMemory");
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
              mySOSHandler.sosDialog(
                  context, event.data()['type'] ?? "unknown", null, null);
            } else {
              debugPrint("SOSSERV HOMEVIEW sos recognized");
            }

            if (sosDebounceMemory.contains(event.id) &&
                event.data()['istriggered'] == false) {
              sosDebounceMemory.remove(event.id);
              debugPrint(
                  "SOSSERV HOMEVIEW debounced alerts $sosDebounceMemory");
            }
          }
        }
      });
    });
    myGeofenceService.initService();
    // myGeofenceService.initList();
    // myGeofenceService.startForegroundTask(const MapView());

    List<String> message = [];
    FirebaseFirestore.instance
        .collection("geofence")
        .snapshots()
        .listen((event) {
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
}
