import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Example method to get data from a Firestore collection
  Future<List<Map<String, dynamic>>> getData(String collectionPath) async {
    try {
      QuerySnapshot snapshot = await _firestore.collection(collectionPath).get();
      return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      print("Error getting data: $e");
      return [];
    }
  }

  // Example method to add data to a Firestore collection
  Future<void> addData(String collectionPath, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(collectionPath).add(data);
    } catch (e) {
      print("Error adding data: $e");
    }
  }

  // Example method to update data in a Firestore document
  Future<void> updateData(String collectionPath, String docId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(collectionPath).doc(docId).update(data);
    } catch (e) {
      print("Error updating data: $e");
    }
  }

  // Example method to delete data from a Firestore document
  Future<void> deleteData(String collectionPath, String docId) async {
    try {
      await _firestore.collection(collectionPath).doc(docId).delete();
    } catch (e) {
      print("Error deleting data: $e");
    }
  }
}