import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Public getter to access the Firestore instance
  FirebaseFirestore get firestore => _firestore;

  // --- User Management Methods ---

  /// Creates or updates a user's profile document in Firestore.
  /// This should be called after a user signs up or logs in, to ensure their profile
  /// data (name, role, phone number) is synchronized with Firestore.
  Future<void> saveUser(User user, String? name, String? phoneNumber, String role) async {
    // Convert username to lowercase for consistent storage and lookup
    final String lowerCaseName = name?.toLowerCase() ?? user.displayName?.toLowerCase() ?? 'anonymous user';

    final userDocRef = _firestore.collection('users').doc(user.uid);
    try {
      await userDocRef.set({
        'name': lowerCaseName, // Store lowercase name
        'originalName': name, // Store original casing if needed for display
        'email': user.email,
        'phoneNumber': phoneNumber ?? user.phoneNumber ?? '',
        'role': role, // e.g., 'user', 'admin'
        'createdAt': FieldValue.serverTimestamp(), // Set only on creation
        'lastLoginAt': FieldValue.serverTimestamp(), // Update on every login/save
      }, SetOptions(merge: true)); // Use merge: true to update existing fields without overwriting the whole document
      print('User data saved/updated for: ${user.uid} with username: $lowerCaseName');
    } catch (e) {
      print("Error saving user data: $e");
    }
  }

  /// Fetches a user's profile document from Firestore.
  Future<DocumentSnapshot<Map<String, dynamic>>?> getUser(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      return userDoc.exists ? userDoc : null;
    } catch (e) {
      print("Error getting user data: $e");
      return null;
    }
  }

  /// Checks if a username already exists in the 'users' collection.
  Future<bool> isUsernameTaken(String username) async {
    // Convert username to lowercase for consistent lookup
    final String lowerCaseUsername = username.toLowerCase();
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('name', isEqualTo: lowerCaseUsername) // Query using lowercase
          .limit(1) // Limit to 1 result for efficiency
          .get();
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print("Error checking username existence: $e");
      return false; // Assume not taken on error to allow user to proceed or handle differently
    }
  }

  /// Updates specific fields in a user's profile document.
  Future<void> updateUserData(String userId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(userId).update(data);
      print('User data updated for: $userId');
    } catch (e) {
      print("Error updating user data: $e");
    }
  }

  // --- Admin Management Methods ---

  /// Fetches all users who have the 'admin' role.
  /// This can be used to display a list of administrators in an admin panel.
  Stream<QuerySnapshot<Map<String, dynamic>>> getAdmins() {
    return _firestore.collection('users')
        .where('role', isEqualTo: 'admin')
        .snapshots();
  }

  /// Grants the 'admin' role to a specific user.
  /// Ensure you have proper authentication and authorization checks before calling this.
  Future<void> grantAdminRole(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({'role': 'admin'});
      print('User $userId granted admin role.');
    } catch (e) {
      print("Error granting admin role to user $userId: $e");
    }
  }

  /// Revokes the 'admin' role from a specific user, setting their role to 'user'.
  /// You might adjust the default role ('user') based on your application's needs.
  Future<void> revokeAdminRole(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({'role': 'user'});
      print('User $userId revoked admin role.');
    } catch (e) {
      print("Error revoking admin role from user $userId: $e");
    }
  }

  // --- Booking Management Methods ---

  /// Adds a new booking to the 'bookings' collection.
  Future<void> addBooking(Map<String, dynamic> bookingData) async {
    try {
      // Add the booking and let Firestore auto-generate the document ID
      DocumentReference docRef = await _firestore.collection('bookings').add(bookingData);
      // Optionally, you can update the document to include its own ID if needed
      await docRef.update({'bookingId': docRef.id});
      print('Booking added with ID: ${docRef.id}');
    } catch (e) {
      print("Error adding booking: $e");
    }
  }

  /// Fetches all bookings for a specific user.
  Stream<QuerySnapshot<Map<String, dynamic>>> getUserBookings(String userId) {
    return _firestore.collection('bookings')
        .where('userId', isEqualTo: userId)
        .orderBy('bookingDate', descending: true)
        .snapshots();
  }

  /// Fetches all bookings (for admin view).
  Stream<QuerySnapshot<Map<String, dynamic>>> getAllBookings() {
    return _firestore.collection('bookings')
        .orderBy('bookingDate', descending: true)
        .snapshots();
  }

  /// Updates an existing booking.
  Future<void> updateBooking(String bookingId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update(data);
      print('Booking updated: $bookingId');
    } catch (e) {
      print("Error updating booking: $e");
    }
  }

  /// Deletes a booking.
  Future<void> deleteBooking(String bookingId) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).delete();
      print('Booking deleted: $bookingId');
    } catch (e) {
      print("Error deleting booking: $e");
    }
  }

  // --- Generic Firestore Methods (can be used for other collections like 'admins' if separated) ---

  /// Example method to get data from a Firestore collection
  Future<List<Map<String, dynamic>>> getData(String collectionPath) async {
    try {
      QuerySnapshot snapshot = await _firestore.collection(collectionPath).get();
      return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      print("Error getting data from $collectionPath: $e");
      return [];
    }
  }

  /// Example method to add data to a Firestore collection
  Future<void> addData(String collectionPath, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(collectionPath).add(data);
    } catch (e) {
      print("Error adding data to $collectionPath: $e");
    }
  }

  /// Example method to update data in a Firestore document
  Future<void> updateDocData(String collectionPath, String docId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(collectionPath).doc(docId).update(data);
    } catch (e) {
      print("Error updating data in $collectionPath/$docId: $e");
    }
  }

  /// Example method to delete data from a Firestore document
  Future<void> deleteDocData(String collectionPath, String docId) async {
    try {
      await _firestore.collection(collectionPath).doc(docId).delete();
    } catch (e) {
      print("Error deleting data from $collectionPath/$docId: $e");
    }
  }
}
