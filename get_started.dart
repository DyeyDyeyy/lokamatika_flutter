import 'package:flutter/material.dart';
import 'package:lokamatika/app_tutorials_carousel.dart';
import 'package:lokamatika/models/lokamatika_colors.dart';
import 'package:lottie/lottie.dart';

// import 'package:lokamatika/login_view.dart';

class GetStarted extends StatefulWidget {
  const GetStarted({super.key});

  @override
  State<GetStarted> createState() => _GetStartedState();
}

class _GetStartedState extends State<GetStarted> {
  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Container(
      decoration: gradientBg,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(screenWidth * 0.05),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: screenHeight * 0.1),
                    Lottie.asset('lib/assets/location.json',
                        width: screenWidth * 0.8),
                    SizedBox(height: screenHeight * 0.05),
                    Center(
                      child: Text(
                        'Welcome!',
                        style: TextStyle(
                          fontFamily: 'Pacifico',
                          fontSize: screenWidth * 0.1,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Center(
                      child: Text(
                        'Locate friends & enjoy life at ease.',
                        style: TextStyle(
                          fontFamily: 'Pacifico',
                          fontSize: screenWidth * 0.03,
                          color: Colors.grey.shade300,
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.1),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const AppTutorials() /* LoginView()*/));
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.2,
                            vertical: screenHeight * 0.025),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        backgroundColor: const Color(0xff6054a4),
                        foregroundColor: Colors.white,
                        shadowColor: Colors.deepPurple.shade700,
                        elevation: 5.0,
                        animationDuration: const Duration(milliseconds: 200),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Get Started'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
