// profile_page.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart'; // Ensure this is imported for ChangePasswordScreen

class CustomProfilePage extends StatefulWidget {
  const CustomProfilePage({super.key});

  @override
  State<CustomProfilePage> createState() => _CustomProfilePageState();
}

class _CustomProfilePageState extends State<CustomProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController; // Added phone controller
  bool _isPasswordVisible = false; // For password visibility toggle

  User? _currentUser; // To hold the current user data

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    // Initialize controllers with current user data
    _nameController = TextEditingController(text: _currentUser?.displayName ?? '');
    _emailController = TextEditingController(text: _currentUser?.email ?? '');
    _phoneController = TextEditingController(text: _currentUser?.phoneNumber ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Update Display Name
        if (_nameController.text != _currentUser?.displayName) {
          await _currentUser?.updateDisplayName(_nameController.text);
        }

        // Update Email
        // Note: Updating email often requires re-authentication and re-verification for security.
        // If the user's current session is old, Firebase will require a recent login.
        if (_emailController.text != _currentUser?.email) {
          await _currentUser?.updateEmail(_emailController.text);
          // After changing email, it's good practice to send a verification email again.
          await _currentUser?.sendEmailVerification();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Email updated. Please check your new email for verification!')
              ),
            );
          }
        }
        
        // Phone Number Update Note:
        // Updating phone numbers is a more complex process in Firebase Authentication,
        // typically requiring a PhoneAuthProvider with SMS verification.
        // Direct update via user.updatePhoneNumber() is not as straightforward as displayName/email.
        // This profile page will *display* the phone number, but the 'Update Profile' button
        // will NOT trigger a phone number update. A dedicated flow would be needed for that.
        // For example, using Firebase UI Auth's Phone Sign-in flow to update/verify a new number.


        // Reload user to get the latest data from Firebase
        await _currentUser?.reload();
        _currentUser = FirebaseAuth.instance.currentUser; // Get the refreshed user object
        setState(() {
          // Update controllers to reflect any changes from reload (e.g., photoURL if it was changed externally)
          _nameController.text = _currentUser?.displayName ?? '';
          _emailController.text = _currentUser?.email ?? '';
          _phoneController.text = _currentUser?.phoneNumber ?? '';
        }); 
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully!')),
          );
        }
      } on FirebaseAuthException catch (e) {
        String message = 'Failed to update profile.';
        if (e.code == 'requires-recent-login') {
          message = 'Please re-authenticate to update sensitive information like email.';
          // You might navigate to a re-authentication screen here.
        } else {
          message = e.message ?? message;
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('An unexpected error occurred: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _currentUser = FirebaseAuth.instance.currentUser; // Ensure current user is always up-to-date
    
    // Fallback for null user - ideally, this page should only be accessible if logged in
    if (_currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Profile')),
        body: const Center(child: Text('User not logged in.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF9A577E), // Match app bar gradient color
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Profile Image (editable - allows tapping for future image picker implementation)
              GestureDetector(
                onTap: () {
                  // TODO: Implement image picking and uploading logic here
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Image picker functionality coming soon!')),
                  );
                },
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: _currentUser?.photoURL != null
                      ? NetworkImage(_currentUser!.photoURL!)
                      : null,
                  child: _currentUser?.photoURL == null
                      ? Icon(Icons.person, size: 60, color: Colors.grey.shade600)
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              // Current Display Name and Email for quick overview
              Text(
                _currentUser?.displayName ?? 'No Name',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              Text(
                _currentUser?.email ?? 'No Email',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              // Editable Username (Display Name)
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Username (Display Name)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your username';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Editable Email
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.email),
                  suffixIcon: _currentUser!.emailVerified
                      ? const Icon(Icons.verified, color: Colors.green)
                      : const Icon(Icons.warning, color: Colors.orange), // Indicate unverified email
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Editable Phone Number (with crucial note)
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                // Removed readOnly: true. User can type, but 'Update Profile' won't save it directly.
                // A full phone number update requires PhoneAuthCredential and SMS verification.
              ),
              const SizedBox(height: 8),
              const Text(
                'Note: To change your phone number, a separate verification process is required by Firebase.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              // Update Profile Button
              ElevatedButton.icon(
                onPressed: _updateProfile,
                icon: const Icon(Icons.save),
                label: const Text('Update Profile'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50), // Full width button
                ),
              ),
              const SizedBox(height: 16),
              // Password Display (masked) and Change Password Button
              const Text(
                'Password:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextFormField(
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  hintText: '********', // Masked password for display
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                ),
                enabled: false, // Password cannot be directly edited or viewed unmasked here
              ),
              const SizedBox(height: 8),
              const Text(
                'Note: For security reasons, your password cannot be displayed unmasked. You can only change it.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  // Navigate to Firebase UI Auth's ChangePasswordScreen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ForgotPasswordScreen(
                        email: _currentUser?.email,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.lock_reset),
                label: const Text('Change Password'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50), // Full width button
                  backgroundColor: Colors.orange, // Differentiate button
                ),
              ),
              // Email verification button if email is not verified
              if (!_currentUser!.emailVerified)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: TextButton.icon(
                    onPressed: () async {
                      await _currentUser?.sendEmailVerification();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Verification email sent!')
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.mark_email_unread),
                    label: const Text('Resend Email Verification'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}