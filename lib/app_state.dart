import 'package:firebase_auth/firebase_auth.dart'
    hide EmailAuthProvider, PhoneAuthProvider;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:event_wise_2/service/database.dart';

import 'firebase_options.dart';

class ApplicationState extends ChangeNotifier {
  ApplicationState() {
    init();
  }

  bool _loggedIn = false;
  bool get loggedIn => _loggedIn;

  bool _isAdmin = false; 
  bool get isAdmin => _isAdmin;

  final DatabaseService _databaseService = DatabaseService();

  Future<void> init() async {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);

    FirebaseUIAuth.configureProviders([
      EmailAuthProvider(),
      PhoneAuthProvider(),
    ]);

    FirebaseAuth.instance.userChanges().listen((user) async { 
      if (user != null) {
        _loggedIn = true;

        final userDoc = await _databaseService.getUser(user.uid);
        if (userDoc != null && userDoc.exists) {
          final userData = userDoc.data();
          _isAdmin = (userData?['role'] == 'admin'); 
        } else {
          _isAdmin = false; 
        }
      } else {
        _loggedIn = false;
        _isAdmin = false; 
      }
      notifyListeners();
    });
  }
}