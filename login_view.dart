import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'home_view.dart';
import 'models/models.dart';

String? fcmToken;

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Flag to toggle the visibility of the password text field
  bool _obscureText = true;

  /// Toggles the visibility of the password text field
  void _togglePasswordVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  void goToHome() => Navigator.pushReplacement(
      context, MaterialPageRoute(builder: (context) => const HomeView()));

  Future<void> fetchToken() async {
    fcmToken = await FirebaseMessaging.instance.getToken();
  }

  @override
  void initState() {
    super.initState();
    fetchToken();
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

  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser != null) {
        final GoogleSignInAuthentication authentication =
            await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: authentication.accessToken,
          idToken: authentication.idToken,
        );

        await _auth.signInWithCredential(credential);

        final User? user = _auth.currentUser;

        if (user != null) {
          final DocumentSnapshot userDoc =
              await _firestore.collection('users').doc(user.uid).get();
          if (userDoc.exists) {
            print('User data exists: ${userDoc.data()}');
            goToHome(); // User data exists, so navigate to Home View
          } else {
            await _firestore.runTransaction((transaction) async {
              transaction.set(
                _firestore.collection('users').doc(user.uid),
                {
                  'email': user.email,
                  'username': user.displayName,
                },
              );
              transaction.set(
                _firestore.collection('profilepicture').doc(user.uid),
                {
                  'url':
                      'https://cdn3.iconfinder.com/data/icons/login-6/512/LOGIN-10-512.png',
                },
              );
              transaction.set(
                _firestore.collection('tokens').doc(user.uid),
                {
                  'token': fcmToken,
                },
              );
              transaction.set(
                  FirebaseFirestore.instance.collection('sos').doc(user.uid), {
                'istriggered': false,
              });

              Position position = await Geolocator.getCurrentPosition();
              transaction.set(
                _firestore.collection('location').doc(user.uid),
                {
                  'trails': <GeoPoint>[
                    GeoPoint(position.latitude, position.longitude)
                  ],
                  'location': GeoPoint(position.latitude, position.longitude),
                  'timestamps': <DateTime>[DateTime.now()],
                },
              );
            });
            print('Initial data set for user: ${user.displayName}');
            goToHome(); // Initial data set, so navigate to Home View
          }
        }
      }
    } catch (e) {
      print('Failed to sign in with Google: $e');
    }
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
            'username': 'Guest account',
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

  Future<void> _signIn(String email, String password, String fcmToken) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (FirebaseAuth.instance.currentUser != null) {
        await FirebaseFirestore.instance
            .collection('tokens')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .set({'token': fcmToken}, SetOptions(merge: true));
        goToHome();
      }

      debugPrint('User signed up successfully: $email');
    } catch (e) {
      if (e.toString().contains('INVALID_LOGIN_CREDENTIALS')) {
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
        backgroundColor: Colors.transparent,
        body: SafeArea(
          // height: MediaQuery.of(context).size.height,
          child: SingleChildScrollView(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 50),
                  lokamatikaLogo,
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _formKey,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(
                                    0.3), // Adjust opacity as needed
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
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
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your email';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 25),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(
                                    0.3), // Adjust opacity as needed
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
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
                                    labelStyle:
                                        const TextStyle(color: Colors.white),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureText
                                            ? Icons.visibility
                                            : Icons.visibility_off,
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
                              ),
                            ),
                            const SizedBox(height: 25),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 16.0),
                              child: Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    ElevatedButton(
                                      onPressed: () async {
                                        if (_formKey.currentState!.validate()) {
                                          await _signIn(
                                            _emailController.text,
                                            _passwordController.text,
                                            fcmToken!,
                                          );
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              const Color(0xff6054a4)),
                                      child: const Text('Login',
                                          style:
                                              TextStyle(color: Colors.white)),
                                    ),
                                    const SizedBox(width: 34),
                                    ElevatedButton(
                                      onPressed: () {
                                        showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return const Dialog(
                                                child: SignUpView(),
                                              );
                                            });
                                      },
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              const Color(0xff6054a4)),
                                      child: const Text(
                                        'Register',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                  ],
                                ),
                              ),
                            ),
                            // const SizedBox(height: 14),
                            // Column(
                            //   children: [
                            //     Padding(
                            //       padding: const EdgeInsets.symmetric(
                            //           horizontal: 25.0),
                            //       child: Row(
                            //         children: [
                            //           Expanded(
                            //             child: Divider(
                            //               thickness: 0.5,
                            //               color: Colors.grey.shade100,
                            //             ),
                            //           ),
                            //           Padding(
                            //             padding: const EdgeInsets.symmetric(
                            //                 horizontal: 10.0),
                            //             child: Text(
                            //               'Or continue with',
                            //               style: TextStyle(
                            //                 color: Colors.grey.shade100,
                            //               ),
                            //             ),
                            //           ),
                            //           Expanded(
                            //             child: Divider(
                            //               thickness: 0.5,
                            //               color: Colors.grey.shade100,
                            //             ),
                            //           ),
                            //         ],
                            //       ),
                            //     ),
                            //   ],
                            // ),
                            // const SizedBox(height: 8),
                            // Column(
                            //   children: [
                            //     Container(
                            //       margin:
                            //           const EdgeInsets.symmetric(horizontal: 65),
                            //       child: ElevatedButton(
                            //         onPressed: signInWithGoogle,
                            //         style: ElevatedButton.styleFrom(
                            //             backgroundColor: const Color(0xff6054a4)),
                            //         child: const Row(
                            //           mainAxisAlignment:
                            //               MainAxisAlignment.spaceAround,
                            //           children: [
                            //             SquareTile(
                            //                 imagePath: 'lib/assets/google.png'),
                            //             Text('Google Login',
                            //                 style:
                            //                     TextStyle(color: Colors.white)),
                            //           ],
                            //         ),
                            //       ),
                            //     ),
                            //     const SizedBox(height: 8),
                            //     const SizedBox(height: 14),
                            //     Container(
                            //       margin: const EdgeInsets.symmetric(
                            //           horizontal: 50),
                            //       child: ElevatedButton(
                            //           onPressed: anonymousAccountCreation,
                            //           style: ElevatedButton.styleFrom(
                            //               backgroundColor:
                            //                   const Color(0xff6054a4)),
                            //           child: const Row(
                            //             mainAxisAlignment:
                            //                 MainAxisAlignment.spaceAround,
                            //             children: [
                            //               Icon(Icons.person,
                            //                   color: Colors.white),
                            //               Text('Use Guest Account',
                            //                   style: TextStyle(
                            //                       color: Colors.white)),
                            //             ],
                            //           )),
                            //     ),
                            //   ],
                            // ),
                          ],
                        ),
                      ),
                    ),
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

class SignUpView extends StatefulWidget {
  const SignUpView({super.key});

  @override
  State<SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends State<SignUpView> {
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

  // Handles the sign-up process with Firebase Auth
  Future<void> _signUp(String email, String password) async {
    try {
      // Create a new user with the provided email and password
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (_auth.currentUser != null) {
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          transaction.set(
              FirebaseFirestore.instance
                  .collection('users')
                  .doc(_auth.currentUser!.uid),
              {
                'username':
                    _auth.currentUser!.email.toString().split('@').first,
                'email': _auth.currentUser!.email.toString(),
              });

          transaction.set(
              FirebaseFirestore.instance
                  .collection('profilepicture')
                  .doc(_auth.currentUser!.uid),
              {
                'url':
                    'https://cdn3.iconfinder.com/data/icons/login-6/512/LOGIN-10-512.png',
              });

          transaction.set(
              FirebaseFirestore.instance
                  .collection('tokens')
                  .doc(_auth.currentUser!.uid),
              {
                'token': fcmToken,
              });

          transaction.set(
              FirebaseFirestore.instance
                  .collection('sos')
                  .doc(_auth.currentUser!.uid),
              {
                'istriggered': false,
              });

          transaction.set(
              FirebaseFirestore.instance
                  .collection('location')
                  .doc(_auth.currentUser!.uid),
              {
                'trails': <GeoPoint>[
                  await Geolocator.getCurrentPosition().then(
                      (value) => GeoPoint(value.latitude, value.longitude)),
                ],
                'location': await Geolocator.getCurrentPosition()
                    .then((value) => GeoPoint(value.latitude, value.longitude)),
                'timestamps': <DateTime>[DateTime.now()],
              });
        });

        // ignore: use_build_context_synchronously
        Navigator.pop(context);

        // ignore: use_build_context_synchronously
        showDialog(
          context: context,
          builder: (context) => const AlertDialog(
            backgroundColor: Colors.amber,
            title: Text(
              'Sign Up Sucess',
              style: TextStyle(color: Colors.white),
            ),
            content: Text('You can now sign in.',
                style: TextStyle(color: Colors.white)),
          ),
        );
      } else {
        // If sign up fails, show an error dialog and print the error message
        throw Exception('User not logged in');
      }

      // Add sign up logic with Firebase Auth here

      debugPrint('User signed up successfully: $email');
    } catch (e) {
      // If sign up fails, show an error dialog and print the error message
      _buildErrorDialog(e.toString().split('] ').last);

      debugPrint('Sign up failed: $e');
    }
  }

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
                          'Register',
                          style: TextStyle(color: Colors.white),
                        ),
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            // Call the sign-up function with the email and password
                            _signUp(
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
