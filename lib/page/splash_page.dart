import 'package:flutter/material.dart';
import 'package:kissan_konnect/core/color.dart'; // Import your color palette
import 'package:kissan_konnect/page/create_an_account.dart';
import 'package:kissan_konnect/page/sign_in.dart'; // Import the SignInPage

class SplashPage extends StatelessWidget {
  const SplashPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use MediaQuery to get the screen size
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: height * 0.05),
            const Text(
              'Let\'s plant with us',
              style: TextStyle(
                fontSize: 22.0,
                letterSpacing: 1.8,
                fontWeight: FontWeight.w900,
                color: Color(0xFF23606E), // darkBlue from the palette
              ),
            ),
            SizedBox(height: height * 0.02),
            const Text(
              'Bring nature home',
              style: TextStyle(
                color: Color(0xFFFACFCE), // lightCoral from the palette
                fontSize: 16,
                letterSpacing: 1.8,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(
              height: height * 0.4,
              width: width * 0.4,
              child: Image.asset('assets/images/Asset1.png'),
            ),
            SizedBox(height: height * 0.05),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SignInPage(),
                  ),
                );
              },
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: width * 0.2,
                  vertical: height * 0.02,
                ),
                decoration: BoxDecoration(
                  color: Color(0xFF008F8C), // teal from the palette
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: const Text(
                  'Sign In',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreateAccountPage(),
                  ),
                );
              },
              child: Text(
                'Create an account',
                style: TextStyle(
                  color: Color(0xFF23606E).withOpacity(0.9), // darkBlue with opacity
                  fontSize: 16,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                // Handle forgot password action
                // You might want to navigate to a forgot password page here
              },
              child: Text(
                'Forgot Password?',
                style: TextStyle(
                  color: Color(0xFF23606E).withOpacity(0.6), // darkBlue with opacity
                  letterSpacing: 1,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

