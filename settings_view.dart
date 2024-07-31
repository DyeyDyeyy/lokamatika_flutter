import 'dart:io';
import 'dart:ui';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/rendering.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:lokamatika/home_view.dart';
import 'package:lokamatika/login_view.dart';
import 'package:lokamatika/models/models.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lokamatika/webview_survey.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// import 'package:lokamatika/app_tutorials_carousel.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'login_view.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({
    super.key,
  });

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // bool _themeMode = true;
  // late bool _toggleLocation;
  // final IconData _iconLight = Icons.toggle_off;
  // final IconData _icondark = Icons.toggle_on;
  // final IconData _offLocation = Icons.toggle_off;
  // final IconData _onLocation = Icons.toggle_on;
  // String _email = '';
  // Uint8List? _image;

  String _username = '';
  String _number = "";
  // ignore: unused_field
  String _imageUrl = '';
  String data = '';
  late final String qrData;
  bool dirExists = false;
  dynamic externalDir = '/storage/emulated/0/Pictures/Qr_code';

  final User? _user = FirebaseAuth.instance.currentUser;
  final TextEditingController usernameController = TextEditingController();
  final ScreenshotController screenshotController = ScreenshotController();
  final GlobalKey _qrkey = GlobalKey();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  Future<void> editField(String field) async {
    String newValue = " ";
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xff6054a4),
        title: Text(
          "Edit $field",
          style: const TextStyle(color: Colors.white),
        ),
        content: TextFormField(
          style: const TextStyle(color: Colors.white),
          cursorColor: Colors.white,
          cursorWidth: 3,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Input new $field',
            labelStyle: const TextStyle(color: Colors.white),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(
                  color: Color(0xfffe9923)), // Border color when focused
            ),
            enabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(
                  color: Color(0xfffe9923)), // Border color when not focused
            ),
          ),
          onChanged: (value) {
            newValue = value;
          },
        ),
        actions: [
          // Cancel button
          TextButton(
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () => Navigator.pop(context)),
          // Save
          TextButton(
            child: const Text(
              'Save',
              style: TextStyle(color: Colors.white),
            ),
            onPressed: () {
              Navigator.of(context).pop(newValue);
            },
          ),
        ],
      ),
    );
    // Update the values in Firestore
    if (newValue.trim().isNotEmpty) {
      // Only updates if there is the value in the textfield changes
      await FirebaseFirestore.instance
          .doc("users/${FirebaseAuth.instance.currentUser!.uid}")
          .update({field: newValue});

      // Update the _username variable in the widget state
      setState(() {
        if (field == 'username') {
          _username = newValue;
        } else if (field == 'number') {
          _number = newValue;
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUsername();
    _loadImageUrl();
    _loadUserNumber();
    // _loadUseremail();
    // _toggleLocation = true;
    qrData = _user!.uid;
  }

  Future<void> _loadUsername() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .doc("users/${FirebaseAuth.instance.currentUser!.uid}")
          .get();

      final username = snapshot.get("username") as String?;
      setState(() {
        _username = username ?? "Guest";
      });
    } on Exception catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> _loadUserNumber() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .doc("users/${FirebaseAuth.instance.currentUser!.uid}")
          .get();

      final number = snapshot.data()!["number"];
      setState(() {
        _number = number ?? "Empty";
      });
    } on Exception catch (e) {
      debugPrint(e.toString());
    }
  }
  // Future<void> _loadUseremail() async {
  //   try {
  //     final snapshot = await FirebaseFirestore.instance
  //         .doc("users/${FirebaseAuth.instance.currentUser!.uid}")
  //         .get();

  //     final email = snapshot.get("email") as String?;
  //     setState(() {
  //       _email = email ?? "  ";
  //     });
  //   } on Exception catch (e) {
  //     debugPrint(e.toString());
  //   }
  // }

  Future<void> _loadImageUrl() async {
    // Replace 'yourCollection' and 'yourDocument' with your Firestore collection and document names
    DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
        .doc("profilepicture/${FirebaseAuth.instance.currentUser!.uid}")
        .get();

    // Replace 'imageUrl' with the field name where you store the image URL in your Firestore document
    String imageUrl = documentSnapshot.get('url') ?? '';
    setState(() {
      _imageUrl = imageUrl;
    });
  }

  Future<void> signOut() async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      // Sign out from all providers
      await Future.wait([
        // Sign out from Google if signed in with Google
        _googleSignIn.signOut(),
        // Sign out from Firebase Auth
        FirebaseAuth.instance.signOut(),
      ]);
      if (currentUser.isAnonymous) {
        final anonymousUserDoc =
            FirebaseFirestore.instance.doc('users/${currentUser.uid}');
        await anonymousUserDoc.delete();
        // await currentUser.delete();
      }
      // Clear any active database references or listeners
      // FirebaseFirestore.instance.clearPersistence();

      goToLogin();
    }
    if (context.mounted) {
      showDialog(
          context: context,
          builder: (context) => const Dialog(
                backgroundColor: Color(0xfffe9923),
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    "The app will exit to restart its background service.",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ));
    }
    Future.delayed(const Duration(seconds: 6)).then((value) {
      SystemNavigator.pop();
    });
  }

  void goToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginView(),
      ),
    );
  }
  // pickImage(ImageSource source) async {
  //   final ImagePicker imagePicker = ImagePicker();
  //   XFile? file = await imagePicker.pickImage(source: source);
  //   if (file != null) {
  //     return await file.readAsBytes();
  //   }
  //   debugPrint('No image selected');
  // }

  // Future<String> selectImage() async {
  //   Uint8List img = await pickImage(ImageSource.gallery);
  //   setState(() {
  //     _image = img;
  //   });
  //   // String username = _username;
  //   String resp =
  //       "${FirebaseAuth.instance.currentUser!.uid}-${await StoreData().saveData(/*username: username,*/ file: _image!)}";
  //   return resp;
  // }

  Future<void> _captureAndSavePng() async {
    try {
      RenderRepaintBoundary boundary =
          _qrkey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      var image = await boundary.toImage(pixelRatio: 3.0);

      //Drawing White Background because Qr Code is Black
      final whitePaint = Paint()..color = Colors.white;
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder,
          Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()));
      canvas.drawRect(
          Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
          whitePaint);
      canvas.drawImage(image, Offset.zero, Paint());
      final picture = recorder.endRecording();
      final img = await picture.toImage(image.width, image.height);
      ByteData? byteData = await img.toByteData(format: ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      //Check for duplicate file name to avoid Override
      String fileName = 'qr_code';
      int i = 1;
      while (await File('$externalDir/$fileName.png').exists()) {
        fileName = 'qr_code_$i';
        i++;
      }

      // Check if Directory Path exists or not
      dirExists = await File(externalDir).exists();
      //if not then create the path
      if (!dirExists) {
        await Directory(externalDir).create(recursive: true);
        dirExists = true;
      }

      final file = await File('$externalDir/$fileName.png').create();
      await file.writeAsBytes(pngBytes);

      if (!mounted) return;
      const snackBar = SnackBar(content: Text('QR code saved to gallery'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    } catch (e) {
      if (!mounted) return;
      const snackBar = SnackBar(content: Text('Something went wrong!!!'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  void goToHome() => Navigator.pushReplacement(
      context, MaterialPageRoute(builder: (context) => const HomeView()));

  // Future<void> linkWithGoogle() async {
  //   try {
  //     _processIndicator(); // Show progress indicator

  //     // Get current user and check if signed in anonymously
  //     final User? user = _auth.currentUser;
  //     if (user == null || !user.isAnonymous) {
  //       _snackBarNotif('User is not signed in anonymously or already linked.');
  //       Navigator.pop(context);
  //       return;
  //     }

  //     // Sign in with Google
  //     final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
  //     if (googleUser == null) {
  //       Navigator.pop(context);
  //       return;
  //     }

  //     final GoogleSignInAuthentication googleAuth =
  //         await googleUser.authentication;
  //     final AuthCredential credential = GoogleAuthProvider.credential(
  //       accessToken: googleAuth.accessToken,
  //       idToken: googleAuth.idToken,
  //     );

  //     // Check if Google account is already linked
  //     final List<UserInfo> providerData = user.providerData;
  //     bool isGoogleLinked = false;
  //     for (var info in providerData) {
  //       if (info.providerId == 'google.com') {
  //         isGoogleLinked = true;
  //         break;
  //       }
  //     }

  //     if (isGoogleLinked) {
  //       _snackBarNotif('Google account is already linked.');
  //       Navigator.pop(context);
  //       return;
  //     }

  //     // Link Google account to anonymous account (if not already linked)
  //     await user.linkWithCredential(credential);

  //     // Merge data from anonymous account to Google account, replacing the UID
  //     await mergeData(user, googleUser);

  //     Navigator.pop(context);
  //   } catch (e) {
  //     print('Failed to link accounts: $e');
  //     Navigator.pop(context);
  //   }
  // }

  // Future<void> mergeData(
  //     User? anonymousUser, GoogleSignInAccount googleUser) async {
  //   final CollectionReference users =
  //       FirebaseFirestore.instance.collection('users');
  //   final DocumentReference anonymousUserDoc = users.doc(anonymousUser!.uid);
  //   final DocumentReference googleUserDoc = users.doc(googleUser.id);

  //   final anonymousUserData = await anonymousUserDoc.get();
  //   final googleUserData = await googleUserDoc.get();
  //   await anonymousUserDoc.update({'email': googleUser.email});

  //   if (!googleUserData.exists) {
  //     await googleUserDoc.update({'uid': googleUser.id});
  //     await googleUserDoc.set(anonymousUserData.data()!);
  //   }

  //   // Delete the anonymous user document
  //   await anonymousUserDoc.delete();
  //   _snackBarNotif('Successfully linked your Google Account');
  // }

  /////////////////////////////////////////////////////////////////////////////

  // Future<void> linkWithGoogle() async {
  //   try {
  //     _processIndicator(); // Show progress indicator

  //     // Get current user
  //     final User? user = _auth.currentUser;
  //     if (user == null) {
  //       _snackBarNotif('User is not signed in.');
  //       Navigator.pop(context);
  //       return;
  //     }

  //     // Check if user is email verified
  //     if (user.emailVerified) {
  //       // Sync data from email verified account to Google account
  //       await syncDataWithEmail(user);
  //     } else {
  //       // Link Google account to anonymous account
  //       await linkGoogleToAnonymous(user);
  //     }

  //     Navigator.pop(context);
  //   } catch (e) {
  //     print('Failed to link accounts: $e');
  //     Navigator.pop(context);
  //   }
  // }

  // Future<void> syncDataWithEmail(User user) async {
  //   try {
  //     // Get data from email verified account
  //     final userData = await FirebaseFirestore.instance
  //         .collection('users')
  //         .doc(user.uid)
  //         .get();

  //     // Link Google account to email verified account
  //     final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
  //     if (googleUser == null) {
  //       throw Exception('Failed to sign in with Google.');
  //     }

  //     final GoogleSignInAuthentication googleAuth =
  //         await googleUser.authentication;
  //     final AuthCredential credential = GoogleAuthProvider.credential(
  //       accessToken: googleAuth.accessToken,
  //       idToken: googleAuth.idToken,
  //     );

  //     await user.linkWithCredential(credential);

  //     // Update data in Google account
  //     await FirebaseFirestore.instance
  //         .collection('users')
  //         .doc(googleUser.id)
  //         .set(userData.data()!);

  //     _snackBarNotif('Successfully linked your Google Account');
  //   } catch (e) {
  //     print('Failed to sync data with email: $e');
  //     throw e;
  //   }
  // }

  // Future<void> linkGoogleToAnonymous(User user) async {
  //   try {
  //     // Sign in with Google
  //     final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
  //     if (googleUser == null) {
  //       throw Exception('Failed to sign in with Google.');
  //     }

  //     final GoogleSignInAuthentication googleAuth =
  //         await googleUser.authentication;
  //     final AuthCredential credential = GoogleAuthProvider.credential(
  //       accessToken: googleAuth.accessToken,
  //       idToken: googleAuth.idToken,
  //     );

  //     // Link Google account to anonymous account
  //     await user.linkWithCredential(credential);

  //     // Transfer data from anonymous account to Google account
  //     await transferDataToGoogle(user, googleUser);

  //     Navigator.pop(context);
  //   } catch (e) {
  //     print('Failed to link accounts: $e');
  //     Navigator.pop(context);
  //   }
  // }

  // Future<void> transferDataToGoogle(
  //     User user, GoogleSignInAccount googleUser) async {
  //   try {
  //     // Get data from anonymous account
  //     final userData = await FirebaseFirestore.instance
  //         .collection('users')
  //         .doc(user.uid)
  //         .get();

  //     // Update data in Google account
  //     await FirebaseFirestore.instance
  //         .collection('users')
  //         .doc(googleUser.id)
  //         .set(userData.data()!);

  //     // Delete anonymous account
  //     await FirebaseFirestore.instance
  //         .collection('users')
  //         .doc(user.uid)
  //         .delete();

  //     _snackBarNotif('Successfully linked your Google Account');
  //   } catch (e) {
  //     print('Failed to transfer data to Google: $e');
  //     throw e;
  //   }
  // }

  SizedBox spacer() {
    return const SizedBox(height: 20);
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });

      await _uploadImage();
    }
  }

  Future<void> _uploadImage() async {
    if (_imageFile == null) return;

    try {
      FirebaseStorage storage = FirebaseStorage.instance;
      Reference ref =
          storage.ref().child('profile').child('${_auth.currentUser!.uid}.jpg');
      UploadTask uploadTask = ref.putFile(_imageFile!);

      await uploadTask.whenComplete(() async {
        String imageUrl = await ref.getDownloadURL();

        await FirebaseFirestore.instance
            .collection('profilepicture')
            .doc(_auth.currentUser!.uid)
            .set({'url': imageUrl});
      });

      setState(() {
        _imageFile = null; // Reset the image file after upload
      });

      debugPrint('Image uploaded successfully');
    } catch (e) {
      print('Failed to upload image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // final _imageUrl = Icon(Icons.person);
    return MaterialApp(
      // theme: _themeMode ? lightMode : darkMode,
      home: Container(
        decoration: gradientBg,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
              child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Container(
                    decoration:
                        BoxDecoration(shape: BoxShape.circle, boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withOpacity(0.5),
                        spreadRadius: 5,
                        blurRadius: 25,
                      )
                    ]),
                    child: Stack(
                      children: [
                        StreamBuilder<String>(
                          stream: FirebaseFirestore.instance
                              .doc(
                                  "profilepicture/${FirebaseAuth.instance.currentUser!.uid}")
                              .snapshots()
                              .map((event) => event.get("url")),
                          builder: (BuildContext context,
                              AsyncSnapshot<String> snapshot) {
                            if (snapshot.hasData) {
                              return CircleAvatar(
                                radius: 64,
                                backgroundImage: NetworkImage(snapshot.data!),
                              );
                            } else {
                              return const CircleAvatar(
                                radius: 64,
                                child: Icon(Icons.person),
                              );
                            }
                          },
                        ),
                        Positioned(
                          bottom: -5,
                          left: 74,
                          child: Container(
                            margin: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.deepPurple,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              onPressed: _pickImage,
                              icon: const Icon(
                                Icons.add_a_photo,
                                color: Colors.amber,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  spacer(),
                  TextBox(
                      text: _username,
                      editName: 'Edit Name',
                      onPressed: () => editField('username')),
                  spacer(),
                  TextBox(
                      text: _number,
                      editName: 'Edit Number',
                      onPressed: () => editField('number')),
                  spacer(),
                  Stack(children: [
                    Container(
                      decoration: BoxDecoration(boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withOpacity(0.5),
                          spreadRadius: 5,
                          blurRadius: 25,
                        )
                      ]),
                      child: StatefulBuilder(
                        builder: (context, setState) {
                          return RepaintBoundary(
                            key: _qrkey,
                            child: Container(
                              color: Colors.white,
                              child: QrImageView(
                                data:
                                    qrData /*_user!.uid ,${_user!.email},$username' */,
                                version: QrVersions.auto,
                                size: 250.0,
                                gapless: true,
                                errorStateBuilder: (ctx, err) {
                                  return const CircularProgressIndicator();
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Positioned(
                        bottom: 100,
                        right: 30,
                        // left: 10,
                        // top: 10,
                        child: ElevatedButton(
                            style: ButtonStyle(
                              elevation: MaterialStateProperty.all(5.0),
                              backgroundColor:
                                  MaterialStateProperty.all(Colors.deepPurple),
                              // shape: MaterialStateProperty.all(
                              //   const CircleBorder(),
                              // ),
                            ),
                            onPressed: () {
                              _captureAndSavePng();
                            },
                            child: const Row(
                              children: [
                                Text("Save QR Code",
                                    style: TextStyle(
                                        fontSize: 16, color: Colors.white)),
                                Icon(
                                  Icons.download,
                                  color: Colors.amber,
                                  size: 30,
                                ),
                              ],
                            )))
                  ]),
                  spacer(),
                  Column(
                    children: [
                      // Row(
                      //   mainAxisAlignment: MainAxisAlignment.center,
                      //   children: [
                      //     const Text("Location Sharing"),
                      //     Switch.adaptive(
                      //       value: _toggleLocation,
                      //       onChanged: (value) {
                      //         setState(() {
                      //           _toggleLocation = value;
                      //         });
                      //       },
                      //     ),
                      //     const SizedBox(
                      //       width: 20
                      //     ),
                      //     TextButton.icon(
                      //         onPressed: () {
                      //           signOut();
                      //           Navigator.pushReplacement(
                      //             context,
                      //             MaterialPageRoute(
                      //               builder: (context) => const LoginView(),
                      //             ),
                      //           );
                      //         },
                      //         icon: const Icon(Icons.logout),
                      //         label: const Text(
                      //           "Sign Out",
                      //           style: TextStyle(color: Colors.white),
                      //         )),
                      //   ],
                      // ),

                      Container(
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.amber.withOpacity(0.5),
                                spreadRadius: 5,
                                blurRadius: 25,
                              )
                            ]),
                        child: ElevatedButton(
                          onPressed: () {
                            showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return const Dialog(
                                    child: LinkAnonToEmail(),
                                  );
                                });
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xff6054a4)),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.link),
                              // SquareTile(imagePath: 'lib/assets/google.png'),
                              Text('Link your guest account to email',
                                  style: TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 9),
                      Container(
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.amber.withOpacity(0.5),
                                spreadRadius: 5,
                                blurRadius: 25,
                              )
                            ]),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const WebViewSurvey()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff6054a4),
                            foregroundColor: Colors.white,
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.star,
                                color: Colors.amber,
                              ),
                              Text('Evalutate our App'),
                              Icon(
                                Icons.star,
                                color: Colors.amberAccent,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 9),
                      Container(
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.amber.withOpacity(0.5),
                                spreadRadius: 5,
                                blurRadius: 25,
                              )
                            ]),
                        child: ElevatedButton(
                          onPressed: signOut,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xff6054a4)),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.logout,
                                color: Colors.redAccent,
                              ),
                              SizedBox(width: 10),
                              Text('Sign Out',
                                  style: TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )),
        ),
      ),
    );
  }
}

// ThemeData lightMode = ThemeData(
//     brightness: Brightness.light,
//     colorScheme: const ColorScheme.light(
//       background: Color(0xfffe9923),
//       primary: Color(0xff6054a4),
//       secondary: Color(0xff3652AD),
//       inversePrimary: Colors.black,
//     ),
//     textTheme: ThemeData.light().textTheme.apply(
//           bodyColor: Colors.black,
//           displayColor: Colors.black,
//         ));

// ThemeData darkMode = ThemeData(
//     brightness: Brightness.dark,
//     colorScheme: ColorScheme.dark(
//       background: Colors.grey.shade900,
//       primary: Colors.grey.shade800,
//       secondary: Colors.grey.shade700,
//       inversePrimary: Colors.white,
//     ),
//     textTheme: ThemeData.dark().textTheme.apply(
//           bodyColor: Colors.grey[300],
//           displayColor: Colors.white,
//         ));

class LinkAnonToEmail extends StatefulWidget {
  const LinkAnonToEmail({super.key});

  @override
  State<LinkAnonToEmail> createState() => _LinkAnonToEmailState();
}

class _LinkAnonToEmailState extends State<LinkAnonToEmail> {
  // Firebase authentication instance
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Text editing controllers for email, password, and confirm password fields
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Flag to toggle the visibility of the password text field
  bool _obscureText = true;

  /// Toggles the visibility of the password text field
  void _togglePasswordVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  // Builds an error dialog with the given error message
  void _buildErrorDialog(String errorMessage) {
    // Use the captured context inside the builder function

    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Failed to sign up'),
        content: Text(errorMessage),
      ),
    );
  }

  // // Handles the sign-up process with Firebase Auth
  // Future<void> _signUp(String email, String password) async {
  //   try {
  //     // Create a new user with the provided email and password
  //     await _auth.createUserWithEmailAndPassword(
  //       email: email,
  //       password: password,
  //     );

  //     if (_auth.currentUser != null) {
  //     } else {
  //       // If sign up fails, show an error dialog and print the error message
  //       throw Exception('User not logged in');
  //     }

  //     // Add sign up logic with Firebase Auth here

  //     debugPrint('User signed up successfully: $email');
  //   } catch (e) {
  //     // If sign up fails, show an error dialog and print the error message
  //     _buildErrorDialog(e.toString().split('] ').last);

  //     debugPrint('Sign up failed: $e');
  //   }
  // }

// Test Textbox opacity
  Widget _buildEmailField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3), // Adjust opacity as needed
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextFormField(
        controller: _emailController,
        style: const TextStyle(color: Colors.white),
        cursorColor: Colors.white,
        cursorWidth: 3,
        decoration: const InputDecoration(
          prefixIcon: Icon(
            Icons.email,
            color: Colors.white,
          ),
          // hintText: 'Email',
          border: InputBorder.none,
          labelText: "Email",
          labelStyle: TextStyle(color: Colors.white),
        ),
        validator: (value) {
          const pattern = r'[^\w@.]';
          final regex = RegExp(pattern);

          if (value!.isEmpty) {
            return 'Please enter your email';
          } else if (value.characters.any(regex.hasMatch) ||
              !(value.characters.contains('@') &&
                  value.characters.contains('.')) ||
              value.endsWith('.') ||
              value.startsWith('.') ||
              value.startsWith('@')) {
            return 'Please enter a valid email';
          }
          return null;
        },
      ),
    );
  }

  // Builds a password text field with the given controller and label text
  Widget _buildPasswordField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3), // Adjust opacity as needed
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextFormField(
        controller: _passwordController,
        style: const TextStyle(color: Colors.white),
        cursorColor: Colors.white,
        cursorWidth: 3,
        obscureText: _obscureText,
        decoration: InputDecoration(
          prefixIcon: const Icon(
            Icons.lock,
            color: Colors.white,
          ),
          border: InputBorder.none,
          labelText: "Password",
          labelStyle: const TextStyle(color: Colors.white),
          suffixIcon: IconButton(
            icon: Icon(
              _obscureText ? Icons.visibility : Icons.visibility_off,
              color: Colors.white,
            ),
            onPressed: _togglePasswordVisibility,
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter your password';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildConfirmPasswordField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3), // Adjust opacity as needed
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextFormField(
        controller: _confirmPasswordController,
        style: const TextStyle(color: Colors.white),
        cursorColor: Colors.white,
        cursorWidth: 3,
        obscureText: _obscureText,
        decoration: InputDecoration(
          prefixIcon: const Icon(
            Icons.lock,
            color: Colors.white,
          ),
          border: InputBorder.none,
          labelText: "Confirm Password",
          labelStyle: const TextStyle(color: Colors.white),
          suffixIcon: IconButton(
            icon: Icon(
              _obscureText ? Icons.visibility : Icons.visibility_off,
              color: Colors.white,
            ),
            onPressed: _togglePasswordVisibility,
          ),
        ),
        validator: (value) {
          if (value!.isEmpty) {
            return 'Please enter your password';
          } else if (_confirmPasswordController.text !=
              _passwordController.text) {
            return 'Passwords do not match';
          }
          return null;
        },
      ),
    );
  }

  Future<void> _linkAccounts(String email, String password) async {
    try {
      final currentUser = _auth.currentUser;

      if (currentUser != null && currentUser.isAnonymous) {
        AuthCredential credential = EmailAuthProvider.credential(
          email: email,
          password: password,
        );

        await currentUser.linkWithCredential(credential);

        // Fetch data from the anonymous account
        DocumentSnapshot userData = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        // Update data in the newly linked email account
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .set(userData.data() as Map<String, dynamic>);

        // Delete the anonymous account
        // await currentUser.delete();

        debugPrint('Anonymous account linked to email: $email');
        _showSuccessDialog();
      } else {
        _buildErrorDialog('User is not signed in anonymously.');
      }
    } catch (e) {
      _buildErrorDialog(e.toString().split('] ').last);
      debugPrint('Failed to link accounts: $e');
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: Colors.amber,
        title: const Text('Account linked successfully',
            style: TextStyle(color: Colors.white)),
        content: const Text('Your guest account has been linked to your email.',
            style: TextStyle(color: Colors.white)),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(
                  context); // Close the dialog and the LinkAnonToEmail dialog
            },
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Container(
          height: 433,
          decoration: gradientBg.copyWith(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(width: 2, color: Colors.white)),
          child: Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  const Text('Register',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                      )),
                  const SizedBox(height: 12),
                  // Build the email field
                  _buildEmailField(),

                  const SizedBox(height: 12),
                  // Build the password field
                  _buildPasswordField(),

                  const SizedBox(height: 12),
                  // Build the confirm password field
                  _buildConfirmPasswordField(),

                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff6054a4)),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: Colors.white),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff6054a4)),
                        child: const Text(
                          'Link',
                          style: TextStyle(color: Colors.white),
                        ),
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            // Call the sign-up function with the email and password
                            _linkAccounts(
                              _emailController.text,
                              _passwordController.text,
                            );
                            // Navigator.pop(context);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class TextBox extends StatelessWidget {
  final String text;
  final String editName;
  final void Function()? onPressed;
  const TextBox({
    super.key,
    required this.text,
    required this.editName,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(boxShadow: [
        BoxShadow(
          offset: const Offset(0, 0),
          blurRadius: 25,
          spreadRadius: 5,
          color: Colors.amber.withOpacity(0.5),
        )
      ], color: Colors.deepPurple, borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        title: Text(
          text,
          style: const TextStyle(
              color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        trailing: Container(
          width: 110,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  editName,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
              // const SizedBox(width: 3),
              IconButton(
                onPressed: onPressed,
                icon: const Icon(
                  Icons.edit,
                  color: Colors.amber,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
