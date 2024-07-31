import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:lokamatika/app_legend.dart';
import 'package:lokamatika/widget_tester.dart';
import 'package:lokamatika/models/manual_sos_model.dart';
import 'package:intl/intl.dart';
import 'dart:math';

final MapController mapController = MapController();
final Map<String, bool> friendVisibility = {};

Future<void> focusToUser(String userid) async {
  await FirebaseFirestore.instance.doc('location/$userid').get().then((value) {
    if (value.exists) {
      mapController.move(
          LatLng(value.data()!['location'].latitude,
              value.data()!['location'].longitude),
          15.35);
    }
  });
}

class MapView extends StatefulWidget {
  const MapView({super.key});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> with AutomaticKeepAliveClientMixin {
  // String? _profileUrl;
  // final myLocationService = LocationServiceModel();

  List<String> friendList = [];
  Map<String, LocationMarkerLayer> friendMarkers = {};
  Map<String, PolylineLayer> friendTrails = {};
  Map<String, List<LocationMarkerLayer>> friendTrailsTimestamps = {};

  void focusToMe() {
    Geolocator.getCurrentPosition().then((value) {
      mapController.move(LatLng(value.latitude, value.longitude), 15.35);
    });
  }

  @override
  bool get wantKeepAlive => true;

  // @override
  // void initState() {
  //   super.initState();
  //   // getProfilePicture();
  // }
  //sasd test

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      // floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        backgroundColor: Colors.deepPurple,
        onPressed: () {
          sosCounter();
          focusToMe();
          setState(() {});
        },
        child: const Icon(
          Icons.my_location,
          color: Colors.amber,
        ),
      ),
      body: Stack(children: [
        FlutterMap(
            mapController: mapController,
            // ignore: prefer_const_constructors
            options: MapOptions(
                maxZoom: 18,
                minZoom: 3,
                onTap: (tapPosition, point) {
                  sosCounter();
                },
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
              //////////////////////////////////////////////////////////////////
              // StreamBuilder(
              //     stream:
              //         FirebaseFirestore.instance.collection("geofence").snapshots(),
              //     builder: ((context, snapshot) {
              //       if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
              //         myGeofenceService.initList();
              //         debugPrint("GEOMAP Returned circle geofence list");
              //         return CircleLayer(circles: getCircleGeofences());
              //       } else {
              //         return Container();
              //       }
              //     }))
              // // make it update with geofence db changes
              StreamBuilder(
                  stream: FirebaseFirestore.instance
                      .collection("geofence")
                      .snapshots(),
                  builder: ((context, snapshot) {
                    if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                      List<CircleMarker> circles = [];
                      for (var doc in snapshot.data!.docs) {
                        if (FirebaseAuth.instance.currentUser != null) {
                          if (doc.data()['to'] ==
                              FirebaseAuth.instance.currentUser!.uid) {
                            circles.add(
                              CircleMarker(
                                useRadiusInMeter: true,
                                borderStrokeWidth: 5.0,
                                borderColor: Colors.orange,
                                color: Colors.deepPurple.withOpacity(0.35),
                                point: LatLng(doc.data()['center'].latitude,
                                    doc.data()['center'].longitude),
                                radius: doc.data()['radius'],
                              ),
                            );
                          }
                        }
                      }
                      return CircleLayer(circles: circles);
                    } else {
                      return Container();
                    }
                  })),
              //////////////////////////////////////////////////////////////////
              StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('location')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                    // friendTrails =
                    //     {}; // TODO: (note) reset trails per state change
                    // friendTrailsTimestamps =
                    //     {}; // TODO: (note) reset trails per state change
                    FirebaseFirestore.instance
                        .collection('users')
                        .doc(FirebaseAuth.instance.currentUser?.uid)
                        .collection('friends')
                        .snapshots()
                        .listen((event) {
                      List<String> friendListGetter = [];
                      for (var friend in event.docs) {
                        friendListGetter.add(friend.id);
                      }
                      friendList = friendListGetter;

                      for (var doc in snapshot.data!.docs) {
                        if (friendList.contains(doc.id) == true) {
                          // LOCATION MARKER AVATARS ///////////////////////////
                          friendMarkers[doc.id] = LocationMarkerLayer(
                            style: LocationMarkerStyle(
                                markerSize: const Size.square(40),
                                marker: StreamBuilder(
                                    stream: FirebaseFirestore.instance
                                        .doc('profilepicture/${doc.id}')
                                        .snapshots(),
                                    builder: (context, snapshot) =>
                                        snapshot.data?['url'] != null &&
                                                snapshot.data!.exists
                                            ? CircleAvatar(
                                                backgroundImage: NetworkImage(
                                                    snapshot.data?['url']),
                                              )
                                            : DefaultLocationMarker())),
                            position: LocationMarkerPosition(
                              latitude: doc.data()['location'].latitude,
                              longitude: doc.data()['location'].longitude,
                              accuracy: 0,
                            ),
                          );

                          // TRAILS ////////////////////////////////////////////
                          // POLYLINES
                          List<GeoPoint> trailData = [];
                          trailData = doc.data()['trails'].cast<GeoPoint>();
                          List<LatLng> points = [];
                          points = trailData
                              .map((geoPoint) =>
                                  LatLng(geoPoint.latitude, geoPoint.longitude))
                              .toList();

                          friendTrails[doc.id] =
                              PolylineLayer(polylineCulling: true, polylines: [
                            Polyline(
                              strokeWidth: 10,
                              points: points,
                              gradientColors: <Color>[
                                Colors.amber.withOpacity(0.2),
                                Colors.amber.withOpacity(0.4),
                                Colors.deepPurple,
                              ],
                            )
                          ]);

                          // TIMESTAMPS
                          List<Timestamp> x =
                              doc.data()['timestamps'].cast<Timestamp>();
                          List<DateTime> timestamps = [];
                          for (var time in x) {
                            timestamps.add(time.toDate());
                          }
                          List<LocationMarkerLayer> stampMarkers = [];

                          if (x.isNotEmpty || trailData.isNotEmpty) {
                            for (int i = 0;
                                i < min(timestamps.length, points.length);
                                i++) {
                              stampMarkers.add(LocationMarkerLayer(
                                  style: LocationMarkerStyle(
                                    markerSize: Size(40, 20),
                                    marker: Container(
                                      decoration: BoxDecoration(
                                        color:
                                            Colors.deepPurple.withOpacity(0.65),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Center(
                                        child: Text(
                                          "${timestamps[i].hour.toString().padLeft(2, '0')}:${timestamps[i].minute.toString().padLeft(2, '0')}",
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                  ),
                                  position: LocationMarkerPosition(
                                      latitude: points[i].latitude,
                                      longitude: points[i].longitude,
                                      accuracy: 0)));
                            }
                            friendTrailsTimestamps[doc.id] = stampMarkers;
                          }
                        }

                        if (friendVisibility.containsKey(doc.id) == false) {
                          friendVisibility[doc.id] = true;
                        } else if (friendVisibility[doc.id] == false) {
                          friendMarkers.remove(doc.id);
                          friendTrails.remove(doc.id);
                          friendTrailsTimestamps.remove(doc.id);
                        }
                      }
                    });
                  }
                  List<LocationMarkerLayer> renderStampList = [];
                  for (var list in friendTrailsTimestamps.values) {
                    for (var marker in list) {
                      renderStampList.add(marker);
                    }
                  }
                  return Stack(children: [
                    Stack(children: friendTrails.values.toList()),
                    Stack(children: renderStampList),
                    Stack(
                      children: friendMarkers.values.toList(),
                    )
                  ]);
                },
              ),
              //////////////////////////////////////////////////////////////////////
              CurrentLocationLayer(
                style: LocationMarkerStyle(
                  markerSize: const Size.square(40),
                  headingSectorRadius: 80,
                  marker: StreamBuilder<String>(
                    stream: FirebaseAuth.instance.currentUser?.uid != null
                        ? FirebaseFirestore.instance
                            .doc(
                                "profilepicture/${FirebaseAuth.instance.currentUser!.uid}")
                            .snapshots()
                            .map((event) => event.get("url"))
                        : Stream.empty(),
                    builder:
                        (BuildContext context, AsyncSnapshot<String> snapshot) {
                      if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                        return CircleAvatar(
                          backgroundImage: NetworkImage(snapshot.data!),
                        );
                      } else {
                        return const CircleAvatar(
                          child: Icon(Icons.person),
                        );
                      }
                    },
                  ),
                ),
                alignPositionOnUpdate: AlignOnUpdate.once,
              ),
            ]),
        Align(
          alignment: Alignment.centerRight,
          child: Container(
            color: Colors.transparent,
            width: MediaQuery.of(context).size.width * 0.1,
            height: MediaQuery.of(context).size.height,
          ),
        ),
        Positioned(
          top: 36.0,
          right: 16.0,
          child: FloatingActionButton(
            heroTag: null,
            backgroundColor: Colors.deepPurple,
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return const Dialog(child: AppLegend());
                },
              );
            },
            child: const Icon(Icons.help_outline, color: Colors.amber),
          ),
        ),
      ]),
    );
  }

  // void appLegend(BuildContext context) {
  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return const Dialog(child: AppLegend());
  //     },
  //   );
  // }

  // void getProfilePicture() async {
  //   DocumentSnapshot snapshot = await FirebaseFirestore.instance
  //       .collection('profilepicture')
  //       .doc(FirebaseAuth.instance.currentUser!.uid)
  //       .get();
  //   _profileUrl = snapshot.get("url");
  //   setState(() {});
  // }

  // List<CircleMarker> getCircleGeofences() {
  //   List<CircleMarker> circles = [];
  // for (var circleGeofence in myGeofenceService.localCircleGeofenceList) {
  //   circles.add(
  //     CircleMarker(
  //       useRadiusInMeter: true,
  //       borderStrokeWidth: 5.0,
  //       borderColor: Colors.orange,
  //       color: Colors.deepPurple.withOpacity(0.35),
  //       point: LatLng(circleGeofence.latitude, circleGeofence.longitude),
  //       radius: circleGeofence.radius.first.length,
  //     ),
  //   );
  //   // }
  //   return circles;
  // }
}
