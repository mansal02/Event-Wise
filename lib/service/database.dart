import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- User Management Methods ---

  /// Creates or updates a user's profile document in Firestore.
  /// This should be called after a user signs up or logs in, to ensure their profile
  /// data (name, role, phone number) is synchronized with Firestore.
  Future<void> saveUser(User user, String? name, String? phoneNumber, String role) async {
    final userDocRef = _firestore.collection('users').doc(user.uid);
    try {
      await userDocRef.set({
        'name': name ?? user.displayName ?? 'Anonymous User',
        'email': user.email,
        'phoneNumber': phoneNumber ?? user.phoneNumber ?? '',
        'role': role, // e.g., 'user', 'admin'
        'createdAt': FieldValue.serverTimestamp(), // Set only on creation
        'lastLoginAt': FieldValue.serverTimestamp(), // Update on every login/save
      }, SetOptions(merge: true)); // Use merge: true to update existing fields without overwriting the whole document
      print('User data saved/updated for: ${user.uid}');
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

  /// Updates specific fields in a user's profile document.
  Future<void> updateUserData(String userId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(userId).update(data);
      print('User data updated for: $userId');
    } catch (e) {
      print("Error updating user data: $e");
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