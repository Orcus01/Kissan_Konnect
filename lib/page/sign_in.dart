import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kissan_konnect/page/create_an_account.dart';
import 'package:kissan_konnect/page/forget_password.dart';
import 'package:kissan_konnect/widgets/bottom_nav.dart';

class SignInPage extends StatefulWidget {
  SignInPage({Key? key}) : super(key: key);

  @override
  _SignInPageState createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? errorMessage;
  bool isDarkTheme = false;

  @override
  Widget build(BuildContext context) {
    Color backgroundColor = isDarkTheme ? const Color(0xFF0B3C5D) : const Color(0xFFF1F7FD);
    Color primaryButtonColor = isDarkTheme ? const Color(0xFF0A74DA) : const Color(0xFF0066CC);
    Color secondaryButtonColor = isDarkTheme ? const Color(0xFF134E87) : Colors.grey[200]!;
    Color textColor = isDarkTheme ? const Color(0xFF7ED0F9) : const Color(0xFF0A3D62);
    Color iconBackgroundColor = isDarkTheme ? const Color(0xFF00203F) : const Color(0xFFEDF5F9);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            double widthFactor = constraints.maxWidth > 600 ? 0.5 : 0.8;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: FractionallySizedBox(
                widthFactor: widthFactor,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Welcome Back!",
                      style: TextStyle(
                        fontSize: 28.0,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 30.0),
                    _buildTextField(
                      "Username",
                      Icons.person,
                      _emailController,
                      isDarkTheme,
                    ),
                    const SizedBox(height: 16.0),
                    _buildTextField(
                      "Password",
                      Icons.lock,
                      _passwordController,
                      isDarkTheme,
                      isPassword: true,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ForgetPasswordPage(),
                            ),
                          );
                        },
                        child: Text(
                          "Forgot Password?",
                          style: TextStyle(
                            color: textColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30.0),
                    _buildSignInButton(isDarkTheme, primaryButtonColor),
                    const SizedBox(height: 20.0),
                    if (errorMessage != null)
                      Text(
                        errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    const SizedBox(height: 10.0),
                    _buildSocialButtons(isDarkTheme, iconBackgroundColor),
                    const SizedBox(height: 20.0),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CreateAccountPage(),
                          ),
                        );
                      },
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: "Don't have an account? ",
                              style: TextStyle(
                                color: textColor,
                              ),
                            ),
                            TextSpan(
                              text: "Sign Up",
                              style: TextStyle(
                                color: primaryButtonColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20.0),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          isDarkTheme = !isDarkTheme;
                        });
                      },
                      child: Text(
                        isDarkTheme ? "Switch to Light Theme" : "Switch to Dark Theme",
                        style: TextStyle(
                          color: textColor,
                          fontSize: 12.0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTextField(
      String hintText, IconData icon, TextEditingController controller, bool isDarkTheme,
      {bool isPassword = false}) {
    Color fillColor = isDarkTheme ? const Color(0xFF134E87) : Colors.grey[200]!;
    Color iconColor = isDarkTheme ? Colors.white : Colors.black;
    Color hintColor = isDarkTheme ? Colors.white70 : Colors.black54;

    return TextField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: iconColor),
        hintText: hintText,
        hintStyle: TextStyle(color: hintColor),
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
      ),
      style: TextStyle(color: iconColor),
    );
  }

  Widget _buildSignInButton(bool isDarkTheme, Color buttonColor) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () async {
          try {
            UserCredential userCredential = await FirebaseAuth.instance
                .signInWithEmailAndPassword(
              email: _emailController.text,
              password: _passwordController.text,
            );
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const BottomNavBar(),
              ),
            );
          } catch (e) {
            setState(() {
              errorMessage = "Failed to sign in. Please check your credentials.";
            });
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30.0),
          ),
        ),
        child: const Text(
          "Sign In",
          style: TextStyle(fontSize: 18.0, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildSocialButtons(bool isDarkTheme, Color backgroundColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildSocialIconButton(
          "assets/icons/google_icon.png",
          backgroundColor,
          () {
            // Google sign-in logic here
          },
        ),
        const SizedBox(width: 20.0),
        _buildSocialIconButton(
          "assets/icons/facebook_icon.png",
          backgroundColor,
          () {
            // Facebook sign-in logic here
          },
        ),
      ],
    );
  }

  Widget _buildSocialIconButton(String assetPath, Color backgroundColor, VoidCallback onPressed) {
    return CircleAvatar(
      backgroundColor: backgroundColor,
      radius: 25.0,
      child: IconButton(
        icon: Image.asset(
          assetPath,
          height: 24,
        ),
        onPressed: onPressed,
      ),
    );
  }
}
