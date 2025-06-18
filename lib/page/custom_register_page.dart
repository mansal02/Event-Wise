import 'package:event_wise_2/service/database.dart'; // Import your DatabaseService
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CustomRegisterPage extends StatefulWidget {
  const CustomRegisterPage({super.key});

  @override
  State<CustomRegisterPage> createState() => _CustomRegisterPageState();
}

class _CustomRegisterPageState extends State<CustomRegisterPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _reEnterPasswordController =
      TextEditingController();
  final DatabaseService _databaseService = DatabaseService();
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Clear error message when text fields are changed
    _emailController.addListener(_clearErrorMessage);
    _usernameController.addListener(_clearErrorMessage);
    _passwordController.addListener(_clearErrorMessage);
    _reEnterPasswordController.addListener(_clearErrorMessage);
  }

  @override
  void dispose() {
    _emailController.removeListener(_clearErrorMessage);
    _usernameController.removeListener(_clearErrorMessage);
    _passwordController.removeListener(_clearErrorMessage);
    _reEnterPasswordController.removeListener(_clearErrorMessage);
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _reEnterPasswordController.dispose();
    super.dispose();
  }

  void _clearErrorMessage() {
    if (_errorMessage != null) {
      setState(() {
        _errorMessage = null;
      });
    }
  }

  Future<void> _register() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final String email = _emailController.text.trim();
    final String username = _usernameController.text.trim();
    final String password = _passwordController.text.trim();
    final String reEnteredPassword = _reEnterPasswordController.text.trim();

    if (password != reEnteredPassword) {
      setState(() {
        _errorMessage = 'Passwords do not match.';
      });
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      // Check if email already exists in Firebase Auth
      try {
        final methods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);
        if (methods.isNotEmpty) {
          setState(() {
            _errorMessage = 'Email already registered. Please use a different email or sign in.';
          });
          setState(() {
            _isLoading = false;
          });
          return;
        }
      } on FirebaseAuthException catch (e) {
        // If 'auth/user-not-found', email is not registered, which is fine.
        // Any other error while checking email should be reported.
        if (e.code != 'auth/user-not-found') {
          setState(() {
            _errorMessage = 'Error checking email: ${e.message}';
          });
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      // Check if username already exists in Firestore (now using lowercase for consistency)
      final bool isUsernameExists = await _databaseService.isUsernameTaken(username);
      if (isUsernameExists) {
        setState(() {
          _errorMessage = 'Username already taken. Please choose a different username.';
        });
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Create user with email and password in Firebase Authentication
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update user display name in Firebase Auth
      await userCredential.user?.updateDisplayName(username);

      // Save user data to Firestore, ensuring username is stored in lowercase
      if (userCredential.user != null) {
        await _databaseService.saveUser(
          userCredential.user!,
          username, // Pass original username, saveUser will convert to lowercase
          null, // No phone number in this form
          'user', // Default role for new users
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration successful!')),
        );
        context.go('/'); // Navigate to home or intended page after registration
      }
    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'weak-password') {
        message = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        // This case should ideally be caught by fetchSignInMethodsForEmail, but as a fallback.
        message = 'The account already exists for that email. Please sign in.';
      } else if (e.code == 'invalid-email') {
        message = 'The email address is not valid.';
      } else {
        message = 'Registration error: ${e.message}';
      }
      setState(() {
        _errorMessage = message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred during registration.';
      });
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
              // Colorful Header
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Colors.orange, Colors.redAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
                child: const Text(
                  'Join EventWise',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Text(
                'Create your account to start booking events!',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Email Input
              _buildTextField(
                controller: _emailController,
                labelText: 'Email',
                icon: Icons.email,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),

              // Username Input
              _buildTextField(
                controller: _usernameController,
                labelText: 'Username',
                icon: Icons.person,
              ),
              const SizedBox(height: 20),

              // Password Input
              _buildTextField(
                controller: _passwordController,
                labelText: 'Password',
                icon: Icons.lock,
                obscureText: true,
              ),
              const SizedBox(height: 20),

              // Re-enter Password Input
              _buildTextField(
                controller: _reEnterPasswordController,
                labelText: 'Re-enter Password',
                icon: Icons.lock_reset,
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

              // Register Button
              _isLoading
                  ? const CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.deepOrangeAccent),
                    )
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.deepOrangeAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 8,
                          shadowColor: Colors.deepOrangeAccent.withOpacity(0.4),
                        ),
                        onPressed: _register,
                        child: const Text(
                          'Register',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
              const SizedBox(height: 20),

              // Back to Sign In
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Already have an account?',
                    style: TextStyle(fontSize: 16),
                  ),
                  TextButton(
                    onPressed: () {
                      context.go('/sign-in');
                    },
                    child: const Text(
                      'Sign In',
                      style: TextStyle(
                        color: Colors.deepPurple,
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
          prefixIcon: Icon(icon, color: Colors.orange),
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
                const BorderSide(color: Colors.deepOrangeAccent, width: 2),
          ),
        ),
      ),
    );
  }
}
