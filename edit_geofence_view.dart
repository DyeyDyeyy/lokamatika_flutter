import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:curved_labeled_navigation_bar/curved_navigation_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:latlong2/latlong.dart';
import 'package:lokamatika/models/geofence_service_model.dart';
import 'package:curved_labeled_navigation_bar/curved_navigation_bar_item.dart';
import 'package:lokamatika/models/lokamatika_colors.dart';
import 'package:lokamatika/models/manual_sos_model.dart';
import 'package:uuid/uuid.dart';

var uuid = Uuid();

class EditGeofenceView extends StatefulWidget {
  final String visitUserId;
  const EditGeofenceView({super.key, required this.visitUserId});

  @override
  State<EditGeofenceView> createState() => _EditGeofenceViewState();
}

class _EditGeofenceViewState extends State<EditGeofenceView>
    with AutomaticKeepAliveClientMixin {
  bool editmode = false;
  Icon editButtonIcon = const Icon(Icons.edit);
  int _selectedIndex = 0;
  final _pageController = PageController();
  bool navBarTap = false;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      bottomNavigationBar: CurvedNavigationBar(
        // currentIndex: _selectedIndex,
        index: _selectedIndex,
        onTap: (index) {
          navBarTap = true;
          if (_selectedIndex != index) {
            _selectedIndex = index;
            _pageController.animateToPage(
              _selectedIndex,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
          }
        },
        items: const [
          CurvedNavigationBarItem(
              child: Icon(Icons.map, color: Color(0xfffe9923)),
              label: "Geofence Map",
              labelStyle:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          CurvedNavigationBarItem(
              child: Icon(Icons.list, color: Color(0xfffe9923)),
              label: "Geofence List",
              labelStyle:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
        backgroundColor: const Color(0xfffe9923),
        color: const Color(0xff6054a4),
        buttonBackgroundColor: const Color(0xff6054a4),
        animationCurve: Curves.linear,
        animationDuration: const Duration(milliseconds: 350),
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          if (!navBarTap) {
            _selectedIndex = index;
            setState(() {});
          } 
            navBarTap = false;
        },
        children: [
          GeofenceMap(visitUserId: widget.visitUserId),
          GeofenceList(visitUserId: widget.visitUserId)
        ],
      ),
    );
  }

  // List<CircleMarker> getCircleGeofences() {
  //   List<CircleMarker> circles = [];
  //   myGeofenceService.geofenceRef.then((geofenceCollection) {
  //     if (geofenceCollection.docs.isNotEmpty) {
  //       for (var doc in geofenceCollection.docs) {
  //         if (doc.data()['from'] == FirebaseAuth.instance.currentUser!.uid &&
  //             doc.data()['to'] == widget.visitUserId &&
  //             doc.data()['type'] == 'circle') {
  //           debugPrint(
  //               "GEOEDIT geofence found: ${doc.data()['center'].latitude}");
  //           circles.add(CircleMarker(
  //             useRadiusInMeter: false,
  //             borderStrokeWidth: 5.0,
  //             borderColor: Colors.orange,
  //             color: Colors.deepPurple.withOpacity(0.35),
  //             point: LatLng(
  //               doc.data()['center'].latitude,
  //               doc.data()['center'].latitude,
  //             ),
  //             radius: doc.data()['radius'],
  //           ));
  //         }
  //       }
  //     }
  //   });
  //   return circles;
  // }
}

class GeofenceList extends StatefulWidget {
  final String visitUserId;
  const GeofenceList({super.key, required this.visitUserId});

  @override
  State<GeofenceList> createState() => _GeofenceListState();
}

class _GeofenceListState extends State<GeofenceList> {
  late String username;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: gradientBg,
      child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
              backgroundColor: const Color(0xff6054a4),
              iconTheme: const IconThemeData(color: Colors.white),
              title: Text("$_username's Geofence List",
                  style: const TextStyle(color: Colors.white))),
          body: StreamBuilder(
            stream:
                FirebaseFirestore.instance.collection('geofence').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      if (snapshot.data!.docs[index].data()['from'] ==
                              FirebaseAuth.instance.currentUser!.uid &&
                          snapshot.data!.docs[index].data()['to'] ==
                              widget.visitUserId) {
                        debugPrint(
                            "GEOEDIT Geofence added to list ${snapshot.data!.docs[index].id} ${snapshot.data!.docs[index].data()['name']}");
                        return ListTile(
                          title: Text(snapshot.data!.docs[index].data()['name'],
                              style: const TextStyle(color: Colors.white)),
                          subtitle: Text(
                              "${snapshot.data!.docs[index].data()['center'].latitude} ${snapshot.data!.docs[index].data()['center'].longitude} ${snapshot.data!.docs[index].data()['type']} ${snapshot.data!.docs[index].data()['radius']}m",
                              style: const TextStyle(color: Colors.white)),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete,
                                color: Color(0xfffe9923)),
                            onPressed: () {
                              showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      backgroundColor: const Color(0xfffe9923),
                                      title: Text(
                                        'Are you sure you want to delete ${snapshot.data!.docs[index].data()['name']}?',
                                        style: const TextStyle(
                                            color: Colors.white),
                                      ),
                                      actions: [
                                        ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  const Color(0xff6054a4),
                                              foregroundColor: Colors.white,
                                            ),
                                            onPressed: () {
                                              snapshot
                                                  .data!.docs[index].reference
                                                  .delete();
                                              Navigator.pop(context);
                                            },
                                            child: const Text('Yes',
                                                style: TextStyle(
                                                    color: Colors.white))),
                                        ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  const Color(0xff6054a4),
                                              foregroundColor: Colors.white,
                                            ),
                                            onPressed: () {
                                              Navigator.pop(context);
                                            },
                                            child: const Text('No',
                                                style: TextStyle(
                                                    color: Colors.white))),
                                      ],
                                    );
                                  });
                            },
                          ),
                        );
                      } else {
                        return const SizedBox.shrink();
                      }
                    });
              } else {
                return const SizedBox.shrink();
              }
            },
          )),
    );
  }
}

String _username = '';

class GeofenceMap extends StatefulWidget {
  final String visitUserId;
  const GeofenceMap({super.key, required this.visitUserId});

  @override
  State<GeofenceMap> createState() => _GeofenceMapState();
}

class _GeofenceMapState extends State<GeofenceMap> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          backgroundColor: const Color(0xff6054a4),
          iconTheme: const IconThemeData(color: Colors.white),
          title: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(widget.visitUserId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.exists) {
                  _username = snapshot.data!['username'];
                  return Text(
                    "$_username's Geofence Map",
                    style: const TextStyle(color: Colors.white),
                  );
                } else {
                  return const Text('Loading...');
                }
              })),
      body: Stack(
        children: [
          StreamBuilder(
              stream:
                  FirebaseFirestore.instance.collection("location").snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                  for (var doc in snapshot.data!.docs) {
                    if (doc.id == widget.visitUserId) {
                      return FlutterMap(
                          options: MapOptions(
                            initialCenter: LatLng(
                                doc.data()["location"].latitude,
                                doc.data()["location"].longitude),
                            interactionOptions: const InteractionOptions(
                                flags: ~InteractiveFlag.rotate),
                            onTap: (tapPosition, point) {
                              debugPrint("GEOEDIT Tapped on ${point.toJson()}");
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => CreateGeofence(
                                            point: point,
                                            visitUserId: widget.visitUserId,
                                            username: _username,
                                          ))).then((value) {
                                setState(() {});
                              });
                            },
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://api.maptiler.com/maps/dataviz/256/{z}/{x}/{y}.png?key=J9Vtnlt50RFtdipVdFXJ', // Maptiler API
                            ),
                            LocationMarkerLayer(
                                position: LocationMarkerPosition(
                              latitude: doc.data()['location'].latitude,
                              longitude: doc.data()['location'].longitude,
                              accuracy: 0,
                            )),
                            // StreamBuilder(
                            //     stream: FirebaseFirestore.instance
                            //         .collection("location")
                            //         .doc(widget.visitUserId)
                            //         .snapshots(),
                            //     builder: ((context, snapshot) {
                            //       if (snapshot.hasData && snapshot.data!.exists) {
                            //         return LocationMarkerLayer(
                            //           position: LocationMarkerPosition(
                            //               latitude: snapshot.data!.data()!['location'].latitude,
                            //               longitude:
                            //                   snapshot.data!.data()!['location'].latitude,
                            //               accuracy: 0),
                            //         );
                            //       } else {
                            //         return const SizedBox.shrink();
                            //       }
                            //     })),
                            StreamBuilder(
                                stream: FirebaseFirestore.instance
                                    .collection("geofence")
                                    .snapshots(),
                                builder: (context, snapshot) {
                                  if (snapshot.hasData &&
                                      snapshot.data!.docs.isNotEmpty) {
                                    List<CircleMarker> circles = [];
                                    if (snapshot.data!.docs.isNotEmpty) {
                                      for (var doc in snapshot.data!.docs) {
                                        if (doc.data()['from'] ==
                                                FirebaseAuth.instance
                                                    .currentUser!.uid &&
                                            doc.data()['to'] ==
                                                widget.visitUserId &&
                                            doc.data()['type'] == 'circle') {
                                          debugPrint(
                                              "GEOEDIT geofence found: ${doc.metadata}");
                                          circles.add(CircleMarker(
                                            useRadiusInMeter: true,
                                            borderStrokeWidth: 5.0,
                                            borderColor: Colors.orange,
                                            color: Colors.deepPurple
                                                .withOpacity(0.35),
                                            point: LatLng(
                                              doc.data()['center'].latitude,
                                              doc.data()['center'].longitude,
                                            ),
                                            radius: doc.data()['radius'],
                                          ));
                                        }
                                      }
                                    }

                                    return CircleLayer(circles: circles);
                                  }
                                  return Container();
                                }),
                          ]);
                    }
                  }
                }
                return CircularProgressIndicator();
              }),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () {
                sosCounter();
              },
              child: Container(
                color: Colors.transparent,
                width: MediaQuery.of(context).size.width * 0.1,
                height: MediaQuery.of(context).size.height,
              ),
            ),
          )
        ],
      ),
    );
  }

  // List<CircleMarker> getCircleGeofences() {
  //   List<CircleMarker> circles = [];
  //   myGeofenceService.geofenceRef.then((geofenceCollection) {
  //     if (geofenceCollection.docs.isNotEmpty) {
  //       for (var doc in geofenceCollection.docs) {
  //         if (doc.data()['from'] == FirebaseAuth.instance.currentUser!.uid &&
  //             doc.data()['to'] == widget.visitUserId &&
  //             doc.data()['type'] == 'circle') {
  //           debugPrint("GEOEDIT geofence found: ${doc.metadata}");
  //           circles.add(CircleMarker(
  //             useRadiusInMeter: false,
  //             borderStrokeWidth: 5.0,
  //             borderColor: Colors.orange,
  //             color: Colors.deepPurple.withOpacity(0.35),
  //             point: LatLng(
  //               doc.data()['center'].latitude,
  //               doc.data()['center'].latitude,
  //             ),
  //             radius: doc.data()['radius'],
  //           ));
  //         }
  //       }
  //     }
  //   });
  //   return circles;
  // }
}

class CreateGeofence extends StatefulWidget {
  final LatLng point;
  final String visitUserId;
  final String username;
  const CreateGeofence(
      {super.key,
      required this.point,
      required this.visitUserId,
      required this.username});

  @override
  State<CreateGeofence> createState() => _CreateGeofenceState();
}

class _CreateGeofenceState extends State<CreateGeofence> {
  double _sliderValue = 100.0;
  final _textfieldValue = TextEditingController();
  DateTimeRange? _dateTime = DateTimeRange(
      start: DateTime.now(), end: DateTime.now().add(const Duration(days: 7)));

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: gradientBg,
      child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: const Color(0xff6054a4),
            iconTheme: const IconThemeData(color: Colors.white),
            title: Text("Create Geofence for ${widget.username}",
                style: const TextStyle(color: Colors.white)),
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextFormField(
                    controller: _textfieldValue,
                    style: const TextStyle(color: Colors.white),
                    cursorColor: Colors.white,
                    cursorWidth: 3,
                    decoration: const InputDecoration(
                      labelText: 'Geofence Name',
                      labelStyle: TextStyle(color: Colors.white),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color:
                                Color(0xfffe9923)), // Border color when focused
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: Color(
                                0xfffe9923)), // Border color when not focused
                      ),
                    ),
                  ),
                  const SizedBox(height: 24.0),
                  const Text("Select Geofence Radius:",
                      style: TextStyle(color: Colors.white)),
                  Slider(
                    divisions: (1000 - 10) ~/ 10,
                    value: _sliderValue,
                    min: 10.0,
                    max: 1000.0,
                    label: "${_sliderValue.toString().split(".").first}m",
                    onChanged: (value) {
                      setState(() {
                        _sliderValue = value;
                      });
                    },
                    activeColor: const Color(0xfffe9923),
                    inactiveColor: Colors.white,
                    thumbColor: const Color(0xfffe9923),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xfffe9923)),
                    onPressed: () async {
                      Future(() async => {
                            _dateTime = await showDateRangePicker(
                              context: context,
                              initialDateRange: _dateTime,
                              firstDate: _dateTime!.start,
                              lastDate:
                                  DateTime.now().add(const Duration(days: 365)),
                              currentDate: _dateTime!.start,
                            )
                          }).then((value) {
                        setState(() {});
                      });
                    },
                    child: Text(
                      "Set geofence effective period: \n ${_dateTime!.start.month}/${_dateTime!.start.day}/${_dateTime!.start.year} - ${_dateTime!.end.month}/${_dateTime!.end.day}/${_dateTime!.end.year}",
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xfffe9923)),
                          onPressed: () {
                            if (_textfieldValue.text.isNotEmpty) {
                              var geofenceMetadata = {
                                "name": _textfieldValue.text,
                                "center": GeoPoint(widget.point.latitude,
                                    widget.point.longitude),
                                "radius": _sliderValue,
                                "expiryDate": _dateTime!.end,
                                "setDate": _dateTime!.start,
                                "from": FirebaseAuth.instance.currentUser!.uid,
                                "to": widget.visitUserId,
                                "type": "circle",
                                "status": "",
                                "polygon": <GeoPoint>[],
                              };
                              sendToFirestore(
                                  "geofence/${uuid.v4()}", geofenceMetadata);
                              // myGeofenceService.initList();
                              Navigator.of(context).pop();
                            } else {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(const SnackBar(
                                content: Text("Geofence name cannot be empty"),
                              ));
                              debugPrint(
                                  "GEOEDIT Geofence name cannot be empty");
                            }
                          },
                          child: const Text("Create",
                              style: TextStyle(color: Colors.white))),
                      ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xfffe9923)),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text("Cancel",
                              style: TextStyle(color: Colors.white)))
                    ],
                  ),
                ],
              ),
            ),
          )),
    );
  }
}
