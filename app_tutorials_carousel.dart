import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lokamatika/home_view.dart';
import 'package:lokamatika/models/lokamatika_colors.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'app_tutorials/app_tutoorials.dart';

class AppTutorials extends StatefulWidget {
  const AppTutorials({Key? key}) : super(key: key);

  @override
  State<AppTutorials> createState() => _AppTutorialsState();
}

class _AppTutorialsState extends State<AppTutorials> {
  final PageController _controller = PageController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool onLastPage = false;
  String? fcmToken;

  @override
  void initState() {
    super.initState();
    fetchToken();
  }

  void goToHome() => Navigator.pushReplacement(
      context, MaterialPageRoute(builder: (context) => const HomeView()));

  Future<void> fetchToken() async {
    fcmToken = await FirebaseMessaging.instance.getToken();
  }

  void _processIndicator() {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent user from dismissing the dialog
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  void _buildErrorDialog(String errorMessage) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: const Color(0xfffe9923),
        title: const Center(child: Text('Failed to sign in')),
        content: Text(errorMessage),
      ),
    );
  }

  Future<void> anonymousAccountCreation() async {
    try {
      _processIndicator();
      UserCredential userCredential = await _auth.signInAnonymously();
      // Access the signed-in user's information
      User? user = userCredential.user;
      if (user != null) {
        if (kDebugMode) {
          print('Signed in anonymously with uid: ${user.uid}');
        }

        await FirebaseFirestore.instance.runTransaction((transaction) async {
          transaction.set(
              FirebaseFirestore.instance.collection('users').doc(user.uid), {
            'email': 'Guest',
            'username': 'Guest',
          });
          transaction.set(
              FirebaseFirestore.instance
                  .collection('profilepicture')
                  .doc(user.uid),
              {
                'url':
                    'https://cdn3.iconfinder.com/data/icons/login-6/512/LOGIN-10-512.png',
              });

          transaction.set(
              FirebaseFirestore.instance.collection('tokens').doc(user.uid), {
            'token': fcmToken,
          });

          transaction
              .set(FirebaseFirestore.instance.collection('sos').doc(user.uid), {
            'istriggered': false,
          });

          Position position = await Geolocator.getCurrentPosition();
          transaction.set(
              FirebaseFirestore.instance.collection('location').doc(user.uid), {
            'trails': <GeoPoint>[
              GeoPoint(position.latitude, position.longitude)
            ],
            'location': GeoPoint(position.latitude, position.longitude),
            'timestamps': <DateTime>[DateTime.now()],
          });
        });
        _signAccountIn(fcmToken!);
        Navigator.pop(context);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to sign in anonymously: $e');
      }
    }
  }

  Future<void> _signAccountIn(String fcmToken) async {
    try {
      await FirebaseAuth.instance.signInAnonymously();
      if (FirebaseAuth.instance.currentUser != null) {
        await FirebaseFirestore.instance
            .collection('tokens')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .set({'token': fcmToken}, SetOptions(merge: true));
        goToHome();
      }
    } catch (e) {
      if (e.toString().contains('INVALID_ANONYMOUS_CREDENTIALS')) {
        _buildErrorDialog('Invalid email or password.');
      } else {
        _buildErrorDialog(e.toString().split('] ').last);
      }

      debugPrint('Sign in failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: gradientBg,
      child: Scaffold(
        backgroundColor: Colors.amber,
        body: Stack(
          children: [
            PageView(
              controller: _controller,
              onPageChanged: (index) {
                setState(() {
                  onLastPage = (index == 14);
                });
              },
              children: const [
                FirstView(),
                SecondView(),
                ThirdView(),
                FourthView(),
                FifthView(),
                SixthView(),
                SeventhView(),
                EigthView(),
                NinthView(),
                TenthView(),
                EleventhView(),
                ThwelfthView(),
                ThirtheenthView(),
                FourtheenthView(),
                FifteenView(),
              ],
            ),
            Container(
                alignment: Alignment.bottomCenter,
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // skip button
                    onLastPage
                        ? TextButton(
                            onPressed: () {
                              _controller.previousPage(
                                  duration: const Duration(milliseconds: 500),
                                  curve: Curves.easeIn);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xff6054a4),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Back'),
                          )
                        : TextButton(
                            onPressed: () {
                              _controller.jumpToPage(14);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xff6054a4),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Skip'),
                          ),

                    // dot page indicator
                    Flexible(
                      child: SmoothPageIndicator(
                        controller: _controller,
                        count: 15,
                        effect: const WormEffect(
                            spacing: 5.0,
                            radius: 10.0,
                            dotWidth: 10.0,
                            dotHeight: 10.0,
                            strokeWidth: 1.5,
                            type: WormType.thin,
                            dotColor: Colors.deepPurple,
                            activeDotColor: Colors.white),
                      ),
                    ),

                    // next & done button
                    onLastPage
                        ? TextButton(
                            onPressed: anonymousAccountCreation,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xff6054a4),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Done'),
                          )
                        : TextButton(
                            onPressed: () {
                              _controller.nextPage(
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeIn,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xff6054a4),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Next'),
                          ),
                  ],
                ))
          ],
        ),
      ),
    );
  }
}
