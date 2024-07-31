import 'dart:async';
import 'package:background_location/background_location.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:lokamatika/context.dart';
import 'package:lokamatika/get_started.dart';
import 'package:lokamatika/login_view.dart';
import 'package:lokamatika/models/foreground_service_model.dart';
import 'package:lokamatika/models/permission_model.dart';
import 'firebase_options.dart';
import 'home_view.dart';
import 'package:is_first_run/is_first_run.dart';
import 'package:permission_handler/permission_handler.dart';

bool? _firstRun, _firstCall;

Future<void> _checkFirstRun() async {
  _firstRun = await IsFirstRun.isFirstRun();
  _firstCall = await IsFirstRun.isFirstCall();
}

////////////////////////////////////////////////////////////////////////////////
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  requestLocationPermission()
      .then((value) => requestStoragePermission())
      .then((value) => requestCameraPermission())
      .then((value) => requestNotifPermission());

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ).then((value) {
    FirebaseFirestore.instance.settings.persistenceEnabled;
  });

  _checkFirstRun().then((value) => runApp(const MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _checkFirstRun();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      home: (_firstRun! && _firstCall!)
          ? const GetStarted()
          : FirebaseAuth.instance.currentUser != null
              ? const HomeView()
              : const LoginView(),
    );
  }
}

void getLocationPermission() async {
  bool serviceEnabled;
  LocationPermission permission;

  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    return Future.error('Location services are disabled.');
  }

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      return Future.error('Location permissions are denied');
    }
  }

  if (permission == LocationPermission.deniedForever) {
    return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.');
  }
}
