import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sureplan/login/login_page.dart';
import 'package:sureplan/signup/signup_page.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> with WidgetsBindingObserver {
  /// Rotating images
  int _currentPage = 1000;
  late PageController _pageController;
  Timer? _timer;

  final List<String> _images = [
    "lib/welcome/image_one.png",
    "lib/welcome/image_two.png",
    "lib/welcome/image_three.png",
    "lib/welcome/image_four.png",
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pageController = PageController(viewportFraction: 0.7, initialPage: 1000);
    _startTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _timer?.cancel();
    } else if (state == AppLifecycleState.resumed) {
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 3), (Timer timer) {
      if (mounted && (ModalRoute.of(context)?.isCurrent ?? false)) {
        _rotateImage();
      }
    });
  }

  void _rotateImage() {
    if (!mounted || !_pageController.hasClients) return;

    setState(() {
      _currentPage = _pageController.page!.round() + 1;
    });

    _pageController.animateToPage(
      _currentPage,
      duration: const Duration(milliseconds: 1600),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 500,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) {
                  final imageIndex = index % _images.length;
                  return Center(
                    child: Container(
                      height: 450,
                      width: 300,
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        image: DecorationImage(
                          image: AssetImage(_images[imageIndex]),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            SizedBox(height: 5),

            Padding(
              padding: const EdgeInsets.only(bottom: 50.0, left: 20, right: 20),
              child: Column(
                children: [
                  Text(
                    "Welcome to",
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 25,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  Text(
                    "Sureplan",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 5),

                  Text(
                    "Bring people together with beautiful event invitations. Built for everyone to send, receive, and enjoy.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600], fontSize: 20),
                  ),

                  SizedBox(height: 30),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 60,
                        width: 170,
                        child: TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              side: BorderSide(color: Colors.black),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),

                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginPage(),
                              ),
                            );
                          },

                          child: Text("Login", style: TextStyle(fontSize: 25)),
                        ),
                      ),

                      SizedBox(width: 20),

                      SizedBox(
                        height: 60,
                        width: 170,
                        child: TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              side: BorderSide(color: Colors.black),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),

                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SignupPage(),
                              ),
                            );
                          },

                          child: Text(
                            "Sign Up",
                            style: TextStyle(fontSize: 25),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
