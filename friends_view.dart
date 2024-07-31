import 'dart:math';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:lokamatika/edit_geofence_view.dart';
import 'package:lokamatika/home_view.dart';
import 'package:lokamatika/map_view.dart';
import 'package:lokamatika/models/lokamatika_colors.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:scan/scan.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import './models/manage_friend_model.dart';

class _FriendsViewState extends State<FriendsView>
    with AutomaticKeepAliveClientMixin {
  int? _previousBatteryLevel;
  // Map<String, String> _profileUrls = {};

  @override
  bool get wantKeepAlive => true;

  // void initState() {
  //   super.initState();
  //   // fetchProfileUrlForFriendList();
  // }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    Color? iconColor =
        const BottomNavigationBarItem(icon: Icon(Icons.abc)).backgroundColor;

    return Container(
      decoration: gradientBg,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: FloatingActionButton(
          heroTag: null,
          backgroundColor: const Color(0xff6054a4),
          onPressed: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => const ScannerView()));
          },
          tooltip: "Add a friend",
          child: const Icon(
            Icons.person_add_rounded,
            color: Colors.amber,
          ),
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc('${FirebaseAuth.instance.currentUser?.uid}')
              .collection('friends')
              .snapshots(),
          builder:
              (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.hasError) {
              return const Text('Something went wrong.');
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Text("Loading...");
            }

            // Get the documents in the 'friends' subcollection
            List<QueryDocumentSnapshot>? friends = snapshot.data?.docs;

            return ListView.builder(
              itemCount: friends?.length,
              itemBuilder: (context, index) {
                Map<String, dynamic> data =
                    friends![index].data() as Map<String, dynamic>;

                if (data['username'] == 'donotdelete') {
                  return Container();
                } else {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 4.0, 16.0, 4.0),
                    child: Container(
                      decoration: BoxDecoration(
                          color: Colors.deepPurple,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amber.withOpacity(0.5),
                              spreadRadius: 5,
                              blurRadius: 25,
                            )
                          ]),
                      child: ListTile(
                        // ignore: unnecessary_null_comparison
                        leading: Container(
                          width: 80,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              StreamBuilder<String>(
                                stream: FirebaseFirestore.instance
                                    .doc("profilepicture/${friends[index].id}")
                                    .snapshots()
                                    .map((event) => event.get("url")),
                                builder: (BuildContext context,
                                    AsyncSnapshot<String> snapshot) {
                                  if (snapshot.hasData) {
                                    return CircleAvatar(
                                      backgroundImage:
                                          NetworkImage(snapshot.data!),
                                    );
                                  } else {
                                    return const CircleAvatar(
                                      child: Icon(Icons.person,
                                          color: Colors.white),
                                    );
                                  }
                                },
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Stack(
                                  children: [
                                    StreamBuilder<DocumentSnapshot>(
                                      stream: FirebaseFirestore.instance
                                          .doc(
                                              "profilepicture/${friends[index].id}")
                                          .snapshots(),
                                      builder: (BuildContext context,
                                          AsyncSnapshot<DocumentSnapshot>
                                              snapshot) {
                                        if (snapshot.connectionState ==
                                            ConnectionState.waiting) {
                                          return const CircularProgressIndicator();
                                        }
                                        if (snapshot.hasError) {
                                          return Text(
                                              'Error: ${snapshot.error}');
                                        }
                                        if (snapshot.hasData &&
                                            snapshot.data!.exists) {
                                          Map<String, dynamic> data =
                                              snapshot.data!.data()
                                                  as Map<String, dynamic>;
                                          final batteryLevel =
                                              data['batteryLevel'];
                                          if (batteryLevel != null &&
                                              batteryLevel is int) {
                                            _previousBatteryLevel =
                                                batteryLevel;

                                            // Determine the color and icon based on the battery level
                                            IconData batteryIcon;
                                            Color batteryColor;
                                            if (batteryLevel >= 20) {
                                              batteryIcon = Icons.battery_full;
                                              batteryColor = Colors.green;
                                            } else {
                                              batteryIcon = Icons.battery_full;
                                              batteryColor = Colors.red;
                                            }

                                            // Show the battery icon with the appropriate color and rotation
                                            return Transform.rotate(
                                              angle: 90 * (pi / 180),
                                              child: Icon(
                                                batteryIcon,
                                                color: batteryColor,
                                                size: 32,
                                              ),
                                            );
                                          } else {
                                            return const Text(' ');
                                          }
                                        }
                                        return const Text(' ');
                                      },
                                    ),
                                    Positioned(
                                      left: 4,
                                      bottom: 8,
                                      child: StreamBuilder<DocumentSnapshot>(
                                        stream: FirebaseFirestore.instance
                                            .doc(
                                                "profilepicture/${friends[index].id}")
                                            .snapshots(),
                                        builder: (BuildContext context,
                                            AsyncSnapshot<DocumentSnapshot>
                                                snapshot) {
                                          if (snapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return const CircularProgressIndicator();
                                          }
                                          if (snapshot.hasError) {
                                            return Text(
                                                'Error: ${snapshot.error}');
                                          }
                                          if (snapshot.hasData &&
                                              snapshot.data!.exists) {
                                            Map<String, dynamic> data =
                                                snapshot.data!.data()
                                                    as Map<String, dynamic>;
                                            final batteryLevel =
                                                data['batteryLevel'] as int;
                                            return Text(
                                              '$batteryLevel%',
                                              style: const TextStyle(
                                                  color: Colors.white),
                                            );
                                          }
                                          return const Text(' ');
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        title: StreamBuilder(
                            stream: FirebaseFirestore.instance
                                .collection('users')
                                .doc(friends[index].id)
                                .snapshots(),
                            builder: (BuildContext context,
                                AsyncSnapshot<DocumentSnapshot> snapshot) {
                              String username = 'Loading...';
                              if (snapshot.hasData && snapshot.data!.exists) {
                                username = snapshot.data!['username'];
                              }
                              return Text(username, style: const TextStyle( color: Colors.white),);
                            }),
                        subtitle: StreamBuilder(
                            stream: FirebaseFirestore.instance
                                .collection('location')
                                .doc(friends[index].id)
                                .snapshots(),
                            builder: (BuildContext context,
                                AsyncSnapshot<DocumentSnapshot> snapshot) {
                              String location = 'Loading...';
                              if (snapshot.hasData && snapshot.data!.exists) {
                                placemarkFromCoordinates(
                                        snapshot.data!['location'].latitude,
                                        snapshot.data!['location'].longitude)
                                    .then((value) {
                                  location =
                                      "${value.first.thoroughfare!.isNotEmpty ? "${value.first.thoroughfare}" : ""}${value.first.locality!.isNotEmpty ? ", ${value.first.locality}" : ""}${value.first.postalCode!.isNotEmpty ? ", ${value.first.postalCode}" : ""}";
                                });
                              }
                              return Text(location,
                                style: const TextStyle(color: Colors.white),
                              );
                            }),
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => GuestProfileView(
                                      visitUserId: friends[index].id)));

                          focusToUser(friends[index].id);
                          pageController.animateToPage(
                            0,
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOut,
                          );
                        },
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              color: Colors.amber,
                              onPressed: () {
                                // showDialog(
                                //   context: context,
                                //   builder: (context) => AlertDialog(
                                //       title: Text(
                                //         'Are you sure you want to unfriend ${data['username']}?',
                                //       ),
                                //       actions: [
                                //         TextButton(
                                //             child: const Text(
                                //               'Yes',
                                //             ),
                                //             onPressed: () {
                                //               unfriend(
                                //                   FirebaseAuth.instance
                                //                       .currentUser!.uid,
                                //                   friends[index].id);
                                //               Navigator.pop(context);
                                //             }),
                                //         TextButton(
                                //             child: const Text(
                                //               'No',
                                //             ),
                                //             onPressed: () {
                                //               Navigator.pop(context);
                                //             })
                                //       ]),
                                // );
                                if (friendVisibility[friends[index].id] ==
                                    true) {
                                  friendVisibility[friends[index].id] = false;
                                } else {
                                  friendVisibility[friends[index].id] = true;
                                }

                                setState(() {});
                              },
                              icon: /* const Icon(Icons.person_remove */
                                  friendVisibility[friends[index].id] == true
                                      ? const Icon(Icons.visibility)
                                      : const Icon(Icons.visibility_off),
                              tooltip: "Hide/Unhide friend on Map View",
                            ),
                            IconButton(
                                visualDensity: VisualDensity.compact,
                                color: Colors.amber,
                                onPressed: () {
                                  Navigator.push(context,
                                      MaterialPageRoute(builder: (context) {
                                    Future.delayed(const Duration(seconds: 1),
                                        () {
                                      showDialog(
                                          context: context,
                                          builder: (context) =>
                                              const AlertDialog(
                                                backgroundColor:
                                                    Colors.deepPurple,
                                                content: Text(
                                                  "Tap a point in map to start creating a geofence.",
                                                  style: TextStyle(
                                                      color: Colors.white),
                                                ),
                                              ));
                                    });
                                    return EditGeofenceView(
                                      visitUserId: friends[index].id,
                                    );
                                  }));
                                },
                                icon: const Icon(Icons.shield),
                                tooltip:
                                    "Enable/disable geofence. Hold to edit geofence."),
                          ],
                        ),
                      ),
                    ),
                  );
                }
              },
            );
          },
        ),
      ),
    );
  }

  // void fetchProfileUrlForFriendList() async {
  //   try {
  //     QuerySnapshot snapshot = await FirebaseFirestore.instance
  //         .collection('users')
  //         .doc(FirebaseAuth.instance.currentUser!.uid)
  //         .collection('friends')
  //         .get();
  //     List<QueryDocumentSnapshot> friends = snapshot.docs;
  //     for (var index = 0; index < friends.length; index++) {
  //       FirebaseFirestore.instance
  //           .doc("profilepicture/${friends[index].id}")
  //           .snapshots()
  //           .listen((event) {
  //         if (event.exists) {
  //           setState(() {
  //             _profileUrls[friends[index].id] = event.get("url");
  //           });
  //         }
  //       });
  //     }
  //   } on Exception catch (e) {
  //     debugPrint(e.toString());
  //   }
  // }
}

// ListView.builder(itemBuilder: (context, index) {
//         return Padding(
//           padding: const EdgeInsets.symmetric(vertical: 4.0),
//           child: ListTile(
//             // ignore: unnecessary_null_comparison
//             leading: _profileUrl == null
//                 ? const CircleAvatar(
//                     child: Icon(Icons.person),
//                   )
//                 : Image.network(_profileUrl!),
//             title: Text('Friend $index'),
//             onTap: () {
//             },
//             trailing: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 IconButton(
//                   visualDensity: VisualDensity.compact,
//                   color: iconColor,
//                   onPressed: () {
//                   },
//                   icon: const Icon(Icons.group_remove),
//                   tooltip: "Remove friend",
//                 ),
//                 IconButton(
//                     visualDensity: VisualDensity.compact,
//                     color: iconColor,
//                     onPressed: () {
//                     },
//                     icon: const Icon(Icons.shield),
//                     tooltip: "Enable/disable geofence. Hold to edit geofence."),
//               ],
//             ),
//           ),
//         );
//       }),

class GuestProfileView extends StatefulWidget {
  final String visitUserId;

  const GuestProfileView({
    super.key,
    required this.visitUserId,
  });

  @override
  State<GuestProfileView> createState() => _GuestProfileViewState();
}

class _GuestProfileViewState extends State<GuestProfileView> {
  final userfriends = FirebaseFirestore.instance
      .collection('users')
      .doc(FirebaseAuth.instance.currentUser!.uid)
      .collection('friends')
      .snapshots();

  @override
  void initState() {
    super.initState();
    fetchProfileUrlForGuestProfile(widget.visitUserId);
  }

  void goToFriendsView() {
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => const HomeView()));

    // Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: gradientBg,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => goToFriendsView(),
          ),
            backgroundColor: const Color(0xff6054a4),
            iconTheme: const IconThemeData(color: Colors.white),
            title: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .doc('users/${widget.visitUserId}')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Text('Something went wrong.');
                }
                if (snapshot.hasData && snapshot.data!.exists) {
                  Map<String, dynamic> data =
                      snapshot.data!.data() as Map<String, dynamic>;
                  return Text('${data['username']}\'s Profile',
                      style: const TextStyle(color: Colors.white));
                } else {
                  return const Text('Loading...');
                }
              },
            )),
        body: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(widget.visitUserId)
              .snapshots(),
          builder:
              (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
            if (snapshot.hasError) {
              return const Text('Something went wrong.');
            }

            if (snapshot.hasData && snapshot.data!.exists) {
              Map<String, dynamic> data =
                  snapshot.data!.data() as Map<String, dynamic>;
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: ListView(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 100, 0, 50),
                      child: Center(
                        child: _profileUrl == null
                            ? const CircleAvatar(
                                radius: 100,
                                child: Icon(Icons.person),
                              )
                            : CircleAvatar(
                                radius: 100,
                                backgroundImage: NetworkImage(_profileUrl!),
                              ),
                      ),
                    ),
                    Center(
                        child: Text('${data['username']}',
                            style: const TextStyle(color: Colors.white))),
                    Center(
                      child: Text(
                        data['number'] != null && data['number'].isNotEmpty
                            ? 'Contact info: ${data['number']}'
                            : 'Empty contact info',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        maximumSize: const Size.fromWidth(200),
                        backgroundColor: const Color(0xff6054a4),
                      ),
                      onPressed: () async {
                        const CircularProgressIndicator();
                        debugPrint(FirebaseAuth.instance.currentUser!.uid);
                        debugPrint(widget.visitUserId);

                        await friendButtonLogic(
                            FirebaseAuth.instance.currentUser!.uid,
                            widget.visitUserId);

                        setState(() {});

                        // const CircularProgressIndicator();
                        // goToFriendsView();
                      },
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection(
                                'users/${FirebaseAuth.instance.currentUser!.uid}/friends')
                            .snapshots(),
                        builder: (BuildContext context,
                            AsyncSnapshot<QuerySnapshot> snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Text("Loading");
                          } else if (snapshot.hasError) {
                            return const Text("Loading");
                          } else {
                            final friends = snapshot.data!.docs;
                            return friends.any(
                                    (friend) => friend.id == widget.visitUserId)
                                ? const Text('Remove friend',
                                    style: TextStyle(color: Colors.white))
                                : const Text('Add friend',
                                    style: TextStyle(color: Colors.white));
                          }
                        },
                      ),
                    ),
                  ],
                ),
              );
            }
            return const Text("Loading");
          },
        ),
      ),
    );
  }

  String? _profileUrl;
  Future<void> fetchProfileUrlForGuestProfile(dynamic uid) async {
    try {
      await FirebaseFirestore.instance
          .doc("profilepicture/$uid")
          .get()
          .then((value) {
        _profileUrl = value.get("url");
        debugPrint("fetchProfileUrlForGuestProfile ${value.get("url")}");
      });
    } on Exception catch (e) {
      debugPrint(e.toString());
    }
  }
}

class ScannerView extends StatefulWidget {
  const ScannerView({super.key});

  @override
  State<ScannerView> createState() => _ScannerViewState();
}

class _ScannerViewState extends State<ScannerView> {
  late MobileScannerController scannerController;

  bool isGuestProfileViewOpen = false;

  @override
  void initState() {
    super.initState();
    scannerController =
        MobileScannerController(formats: [BarcodeFormat.qrCode]);
  }

  @override
  void dispose() {
    super.dispose();
    scannerController.dispose();
  }

  void decodeQrCodeFromImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        final String imagePath = pickedFile.path;
        final String? scannedData = await Scan.parse(imagePath);

        debugPrint('Decoded QR code from image: $scannedData');

        if (scannedData != null) {
          debugPrint("QRSERV $scannedData");
          if (scannedData == FirebaseAuth.instance.currentUser!.uid) {
            // ignore: use_build_context_synchronously
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'You cannot scan your own QR code.',
                  style: TextStyle(fontSize: 20),
                ),
              ),
            );
          } else {
            // ignore: use_build_context_synchronously
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    GuestProfileView(visitUserId: scannedData.toString()),
              ),
            );
          }
        } else {
          debugPrint('No data found in the QR code image.');
        }
      }
    } catch (e) {
      debugPrint('Error picking image or scanning QR code: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            backgroundColor: const Color(0xff6054a4),
            onPressed: () {
              // selectImage;
              decodeQrCodeFromImage();
            },
            tooltip: "Get QR Code from gallery",
            heroTag: null,
            child: const Icon(Icons.folder, color: Colors.amber),
          ),
          const SizedBox(height: 15),
          FloatingActionButton(
            backgroundColor: const Color(0xff6054a4),
            onPressed: () => Navigator.maybeOf(context)!.maybePop(),
            tooltip: "Return to friend list",
            heroTag: null,
            child: const Icon(Icons.close, color: Colors.amber),
          ),
        ],
      ),
      body: PopScope(
        onPopInvoked: (value) async {
          scannerController.stop();
        },
        child: Stack(
          children: [
            MobileScanner(
                overlay: const HoleInBoxWidget(),
                // scanWindow: Rect.fromCenter(
                //     center: Offset.zero,
                //     height: const MediaQueryData().size.height / 2,
                //     width: const MediaQueryData().size.width / 2),
                controller: scannerController,
                onDetect: (barcode) {
                  if (!isGuestProfileViewOpen) {
                    List<String> barcodeValues =
                        barcode.barcodes.last.rawValue!.split(',');

                    String uid = barcodeValues.elementAt(0);

                    barcodeValues.clear();

                    String currentUserUid =
                        FirebaseAuth.instance.currentUser?.uid as String;
                    if (uid == currentUserUid) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'You cannot scan your own QR code.',
                            style: TextStyle(fontSize: 20),
                          ),
                        ),
                      );
                    } else {
                      isGuestProfileViewOpen = true;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              GuestProfileView(visitUserId: uid),
                        ),
                      ).then((_) {
                        isGuestProfileViewOpen = false;
                      });
                    }
                  }
                }),
            const Center(
              heightFactor: 10,
              child: Text(
                  "Scan the QR code of the user \n you wish to be friends with.",
                  style: TextStyle(color: Colors.white)),
            ),
            // const SizedBox(height: 15),
            // Positioned(
            //   bottom: 20.0, // Adjust distance from bottom as needed
            //   left: 0.0,
            //   right: 0.0,
            //   child: Center(
            //     child: RawMaterialButton(
            //       onPressed: decodeQrCodeFromImage,
            //       fillColor: Colors.blue,
            //       shape: const StadiumBorder(),
            //       padding:
            //           const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
            //       child: const Text(
            //         'Import Qr Code',
            //         style: TextStyle(
            //           color: Colors.white,
            //           fontSize: 18,
            //         ),
            //       ),
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}

class HoleInBoxWidget extends StatelessWidget {
  const HoleInBoxWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          color: Colors.transparent,
        ),
        Opacity(
          opacity: 0.5,
          child: ClipPath(
            clipper: HoleClipper(),
            child: Container(
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }
}

class HoleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    var holeSize = 300; // The size of the hole in the center.

    path.addRRect(RRect.fromRectAndRadius(
      Rect.fromCircle(
        center: size.center(Offset.zero),
        radius: holeSize / 2,
      ),
      const Radius.circular(20), // Replace 20 with your desired corner radius
    ));

    path.addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    path.fillType = PathFillType.evenOdd;
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class FriendsView extends StatefulWidget {
  const FriendsView({super.key});

  @override
  State<FriendsView> createState() => _FriendsViewState();
}
