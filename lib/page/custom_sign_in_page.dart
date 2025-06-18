import 'package:event_wise_2/service/database.dart'; // Import your DatabaseService
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CustomSignInPage extends StatefulWidget {
  const CustomSignInPage({super.key});

  @override
  State<CustomSignInPage> createState() => _CustomSignInPageState();
}

class _CustomSignInPageState extends State<CustomSignInPage> {
  final TextEditingController _emailUsernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final DatabaseService _databaseService = DatabaseService();
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Clear error message when text fields are changed
    _emailUsernameController.addListener(_clearErrorMessage);
    _passwordController.addListener(_clearErrorMessage);
  }

  @override
  void dispose() {
    _emailUsernameController.removeListener(_clearErrorMessage);
    _passwordController.removeListener(_clearErrorMessage);
    _emailUsernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _clearErrorMessage() {
    if (_errorMessage != null) {
      setState(() {
        _errorMessage = null;
      });
    }
  }

  // Helper to check if the input string is likely an email
  bool _isEmail(String input) {
    return input.contains('@') && input.contains('.');
  }

  Future<void> _signIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final String identifier = _emailUsernameController.text.trim();
    final String password = _passwordController.text.trim();
    String? emailToSignIn;

    if (identifier.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter both email/username and password.';
      });
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      if (_isEmail(identifier)) {
        // If it looks like an email, try to sign in directly
        emailToSignIn = identifier;
      } else {
        // Otherwise, assume it's a username and try to find the associated email in Firestore
        // Convert the identifier to lowercase for consistent lookup with how usernames are stored.
        final String lowerCaseIdentifier = identifier.toLowerCase();
        final querySnapshot = await _databaseService.firestore
            .collection('users')
            .where('name', isEqualTo: lowerCaseIdentifier) // Query using lowercase
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          final userData = querySnapshot.docs.first.data();
          emailToSignIn = userData['email'];
        } else {
          setState(() {
            _errorMessage = 'No user found with that username.';
          });
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      if (emailToSignIn != null) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailToSignIn,
          password: password,
        );
        // User is signed in, navigate to home or intended page
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Welcome back!')),
          );
          context.go('/');
        }
      }
    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'user-not-found' || e.code == 'invalid-email') {
        // These can occur if email was not found or was malformed, or if username lookup failed to yield a valid email.
        message = 'Invalid credentials. Please check your email/username and password.';
      } else if (e.code == 'wrong-password') {
        message = 'Wrong password provided. Please try again.';
      } else {
        message = 'Authentication error: ${e.message}';
      }
      setState(() {
        _errorMessage = message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred during sign-in.';
      });
      print('Sign-in error: $e'); // For debugging
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Stylish Logo/App Name
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Colors.deepPurple, Colors.blueAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
                child: const Text(
                  'EventWise',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white, // Color is masked by shader
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Text(
                'Welcome Back!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Sign in to continue your event journey.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 40),

              // Email/Username Input Field
              _buildTextField(
                controller: _emailUsernameController,
                labelText: 'Email or Username',
                icon: Icons.person, // Changed icon to be more generic for both
                keyboardType: TextInputType.emailAddress, // Still good for email, flexible for username
              ),
              const SizedBox(height: 20),

              // Password Input Field
              _buildTextField(
                controller: _passwordController,
                labelText: 'Password',
                icon: Icons.lock,
                obscureText: true,
              ),
              const SizedBox(height: 30),

              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 15.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),

              // Sign In Button
              _isLoading
                  ? const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.deepPurpleAccent),
                    )
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.deepPurpleAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 8,
                          shadowColor: Colors.deepPurpleAccent.withOpacity(0.4),
                        ),
                        onPressed: _signIn,
                        child: const Text(
                          'Sign In',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
              const SizedBox(height: 20),

              // Forgot Password Link
              TextButton(
                onPressed: () {
                  context.push('/sign-in/forgot-password');
                },
                child: const Text(
                  'Forgot Password?',
                  style: TextStyle(
                    color: Colors.deepPurple,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Register Now Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Don\'t have an account?',
                    style: TextStyle(fontSize: 16),
                  ),
                  TextButton(
                    onPressed: () {
                      context.push('/register');
                    },
                    child: const Text(
                      'Register Now',
                      style: TextStyle(
                        color: Colors.deepOrange,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.black87),
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: TextStyle(color: Colors.grey[600]),
          prefixIcon: Icon(icon, color: Colors.deepPurple),
          border: InputBorder.none, // Remove default border
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: Colors.deepPurpleAccent, width: 2),
          ),
        ),
      ),
    );
  }
}
