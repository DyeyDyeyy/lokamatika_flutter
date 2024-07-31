import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class TrackerView extends StatefulWidget {
  final String? visitUserId;
  const TrackerView({super.key, required this.visitUserId});

  @override
  State<TrackerView> createState() => _TrackerViewState();
}

class _TrackerViewState extends State<TrackerView> {
  Position? myPos;
  String username = "Loading...";

  @override
  initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: StreamBuilder(
          stream: FirebaseFirestore.instance
              .doc("users/${widget.visitUserId}")
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data!.exists) {
              username = snapshot.data!.data()!['username'];
              return Text("Locating $username");
            } else {
              return const Text('Loading...');
            }
          },
        ),
      ),
      body: FlutterMap(
          options: MapOptions(
              interactionOptions: const InteractionOptions(
                  flags: ~InteractiveFlag.rotate &
                      // ~InteractiveFlag.drag &
                      ~InteractiveFlag.doubleTapDragZoom &
                      ~InteractiveFlag.flingAnimation)),
          children: [
            TileLayer(
              urlTemplate:
                  'https://api.maptiler.com/maps/dataviz/256/{z}/{x}/{y}.png?key=J9Vtnlt50RFtdipVdFXJ', // Maptiler API
            ),
            StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('location')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                    LatLng? guestLocation;
                    LatLng? selfLocation;
                    for (var doc in snapshot.data!.docs) {
                      if (doc.id == widget.visitUserId) {
                        guestLocation = LatLng(doc.data()['location'].latitude,
                            doc.data()['location'].longitude);
                      }
                      if (doc.id == FirebaseAuth.instance.currentUser!.uid) {
                        selfLocation = LatLng(doc.data()['location'].latitude,
                            doc.data()['location'].longitude);
                      }
                    }
                    return PolylineLayer(polylines: [
                      Polyline(
                        points: [
                          selfLocation!,
                          guestLocation!,
                        ],
                        strokeWidth: 20.0,
                        gradientColors: [Colors.deepPurple, Colors.amber],
                        // borderColor: Colors.white,
                        // borderStrokeWidth: 5.0,
                      )
                    ]);
                  }
                  return CircularProgressIndicator();
                }),
            StreamBuilder(
                stream: FirebaseFirestore.instance
                    .doc('location/${widget.visitUserId}')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data!.exists) {
                    return LocationMarkerLayer(
                      style: LocationMarkerStyle(
                          markerSize: const Size.square(40),
                          marker: CircleAvatar(
                            child: Text(
                              "FRIEND",
                              style: TextStyle(
                                  color: Colors.black, fontSize: 40 * 0.25),
                            ),
                            backgroundColor: Colors.amber,
                          )),
                      position: LocationMarkerPosition(
                        latitude: snapshot.data!.data()!['location'].latitude,
                        longitude: snapshot.data!.data()!['location'].longitude,
                        accuracy: 0,
                      ),
                    );
                  } else {
                    return CircularProgressIndicator();
                  }
                }),
            CurrentLocationLayer(
                alignPositionOnUpdate: AlignOnUpdate.always,
                alignDirectionOnUpdate: AlignOnUpdate.always,
                style: LocationMarkerStyle(
                    markerSize: const Size.square(40),
                    marker: CircleAvatar(
                      child: Text(
                        "YOU",
                        style: TextStyle(color: Colors.white),
                      ),
                      backgroundColor: Colors.deepPurple,
                    ))),
          ]),
    );
  }
}
