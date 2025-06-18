// profile_page.dart
import 'dart:io'; // For File

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Import for image picking

// Removed: import 'package:firebase_storage/firebase_storage.dart'; // Removed for Firebase Storage

import '../service/database.dart'; // Import the DatabaseService

class CustomProfilePage extends StatefulWidget {
  const CustomProfilePage({super.key});

  @override
  State<CustomProfilePage> createState() => _CustomProfilePageState();
}

class _CustomProfilePageState extends State<CustomProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _newPasswordController; // For new password
  late TextEditingController _confirmPasswordController; // For confirming new password
  
  bool _isPasswordVisible = false;
  // Removed: bool _isUploadingImage = false; // No longer needed without upload

  User? _currentUser;
  final DatabaseService _databaseService = DatabaseService(); // Initialize DatabaseService
  final ImagePicker _picker = ImagePicker(); // Image picker instance
  File? _imageFile; // To store the picked image

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    // Initialize controllers with current user data
    _nameController = TextEditingController(text: _currentUser?.displayName ?? '');
    _emailController = TextEditingController(text: _currentUser?.email ?? '');
    _phoneController = TextEditingController(text: _currentUser?.phoneNumber ?? '');
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();

    // Fetch and display additional user data from Firestore if available
    _fetchAndSetUserProfile();
  }

  Future<void> _fetchAndSetUserProfile() async {
    if (_currentUser != null) {
      final userDoc = await _databaseService.getUser(_currentUser!.uid);
      if (userDoc != null && userDoc.exists) {
        setState(() {
          _nameController.text = userDoc.data()?['name'] ?? _currentUser?.displayName ?? '';
          _phoneController.text = userDoc.data()?['phoneNumber'] ?? _currentUser?.phoneNumber ?? '';
          // Email is primarily from FirebaseAuth, but can be synced from Firestore if needed
          _emailController.text = userDoc.data()?['email'] ?? _currentUser?.email ?? '';
        });
      } else {
        // If no Firestore document exists, create one with default role 'user'
        await _databaseService.saveUser(_currentUser!, _currentUser?.displayName, _currentUser?.phoneNumber, 'user');
        // Re-fetch to ensure controllers are updated after initial save
        _fetchAndSetUserProfile();
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        // No more _isUploadingImage = true; as we are not uploading
      });
      // Removed call to _uploadImageToFirebase();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image selected! (Not uploaded without Firebase Storage)')),
        );
      }
    }
  }

  // Removed: Future<void> _uploadImageToFirebase() async { ... } method as it's no longer used.

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      try {
        if (_currentUser == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User not logged in.')),
          );
          return;
        }

        Map<String, dynamic> firestoreUpdateData = {};

        // Update Display Name in Firebase Auth
        if (_nameController.text != _currentUser?.displayName) {
          await _currentUser?.updateDisplayName(_nameController.text);
          firestoreUpdateData['name'] = _nameController.text;
          firestoreUpdateData['originalName'] = _nameController.text; // Update originalName if display name changes
        }

        // Update Email in Firebase Auth
        if (_emailController.text != _currentUser?.email) {
          // Check if the new email is different and if it's not already verified
          if (_currentUser?.emailVerified == true && _emailController.text != _currentUser?.email) {
             ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please update your email via Firebase Authentication if it\'s already verified.')),
            );
            return; // Exit if email is verified and user tries to change it via this field
          }
          await _currentUser?.verifyBeforeUpdateEmail(_emailController.text);
          firestoreUpdateData['email'] = _emailController.text; // Update email in Firestore as well
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Email updated. Please check your new email for verification!')
              ),
            );
          }
        }
        
        // Update Phone Number in Firestore (Firebase Auth directly handles phone authentication,
        // but for profile display/storage, we can put it in Firestore)
        if (_phoneController.text != (_currentUser?.phoneNumber ?? '')) {
          firestoreUpdateData['phoneNumber'] = _phoneController.text;
          // Note: Actual Firebase Auth phone number *update* involves SMS verification
          // and linking credentials, which is more complex than simple profile updates.
          // This simply stores the new number in your Firestore profile.
        }

        // Update Firestore document if there are changes
        if (firestoreUpdateData.isNotEmpty) {
          await _databaseService.updateUserData(_currentUser!.uid, firestoreUpdateData);
        }

        // Reload user to get the latest data from Firebase Auth
        await _currentUser?.reload();
        _currentUser = FirebaseAuth.instance.currentUser; // Get the refreshed user object
        setState(() {
          // Update controllers to reflect any changes from reload or Firestore
          _nameController.text = _currentUser?.displayName ?? '';
          _emailController.text = _currentUser?.email ?? '';
          _phoneController.text = _currentUser?.phoneNumber ?? ''; // This might not update if Firebase Auth phone is not updated
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

  Future<void> _changePassword() async {
    if (_formKey.currentState!.validate()) {
      final newPassword = _newPasswordController.text;
      final confirmPassword = _confirmPasswordController.text;

      if (newPassword.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a new password.')),
        );
        return;
      }
      if (newPassword != confirmPassword) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('New password and confirm password do not match.')),
        );
        return;
      }

      try {
        if (_currentUser == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User not logged in.')),
          );
          return;
        }

        await _currentUser?.updatePassword(newPassword);
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Password updated successfully!')),
          );
        }
      } on FirebaseAuthException catch (e) {
        String message = 'Failed to change password.';
        if (e.code == 'requires-recent-login') {
          message = 'This operation is sensitive and requires recent authentication. Please log out and log in again, then try changing your password.';
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
    _currentUser = FirebaseAuth.instance.currentUser;
    
    if (_currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: Text('User not logged in.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF9A577E),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: _pickImage, // No need to check _isUploadingImage as it's removed
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: _imageFile != null
                          ? FileImage(_imageFile!) as ImageProvider<Object>? // Show picked image
                          : (_currentUser?.photoURL != null
                              ? NetworkImage(_currentUser!.photoURL!)
                              : null),
                      child: (_imageFile == null && _currentUser?.photoURL == null)
                          ? Icon(Icons.person, size: 60, color: Colors.grey.shade600)
                          : null,
                    ),
                    // Removed: if (_isUploadingImage) const CircularProgressIndicator(),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _currentUser?.displayName ?? 'No Name',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              Text(
                _currentUser?.email ?? 'No Email',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 24),
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
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.email),
                  suffixIcon: _currentUser!.emailVerified
                      ? const Icon(Icons.verified, color: Colors.green)
                      : const Icon(Icons.warning, color: Colors.orange),
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
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 8),
              const Text(
                'Note: To change your phone number, a separate verification process is required by Firebase.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _updateProfile,
                icon: const Icon(Icons.save),
                label: const Text('Update Profile'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Change Password:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextFormField(
                controller: _newPasswordController,
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'New Password',
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
                validator: (value) {
                  if (value != null && value.isNotEmpty && value.length < 6) {
                    return 'Password must be at least 6 characters long.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Confirm New Password',
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
                validator: (value) {
                  if (value != null && value.isNotEmpty && value != _newPasswordController.text) {
                    return 'Passwords do not match.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _changePassword,
                icon: const Icon(Icons.lock_reset),
                label: const Text('Set New Password'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: Colors.orange,
                ),
              ),
              if (!_currentUser!.emailVerified)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: TextButton.icon(
                    icon: const Icon(Icons.email),
                    label: const Text('Send Verification Email'),
                    onPressed: () async {
                      await _currentUser?.sendEmailVerification();
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Verification email sent!')),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
