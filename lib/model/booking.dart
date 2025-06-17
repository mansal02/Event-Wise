import 'package:cloud_firestore/cloud_firestore.dart';

class Booking {
  final String bookingId;
  final String userId;
  final String eventHallPackageId;
  final String eventName;
  final double eventPrice;
  final String details;
  final int visitorPax;
  final DateTime startDate;
  final DateTime endDate;
  final int days;
  final List<String> addOns;
  final double totalPrice;
  final DateTime bookingDate;
  final String status; // e.g., 'pending', 'confirmed', 'cancelled', 'completed'

  Booking({
    required this.bookingId,
    required this.userId,
    required this.eventHallPackageId,
    required this.eventName,
    required this.eventPrice,
    required this.details,
    required this.visitorPax,
    required this.startDate,
    required this.endDate,
    required this.days,
    required this.addOns,
    required this.totalPrice,
    required this.bookingDate,
    required this.status,
  });

  // Factory constructor to create a Booking object from a Firestore DocumentSnapshot
  factory Booking.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Booking(
      bookingId: doc.id, // Use Firestore's document ID as the bookingId
      userId: data['userId'] ?? '',
      eventHallPackageId: data['eventHallPackageId'] ?? '',
      eventName: data['eventName'] ?? 'Unknown Event',
      eventPrice: (data['eventPrice'] as num?)?.toDouble() ?? 0.0,
      details: data['details'] ?? '',
      visitorPax: (data['visitorPax'] as num?)?.toInt() ?? 0,
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      days: (data['days'] as num?)?.toInt() ?? 0,
      addOns: List<String>.from(data['addOns'] ?? []),
      totalPrice: (data['totalPrice'] as num?)?.toDouble() ?? 0.0,
      bookingDate: (data['bookingDate'] as Timestamp).toDate(),
      status: data['status'] ?? 'pending',
    );
  }

  // Optional: Convert Booking object to a Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'eventHallPackageId': eventHallPackageId,
      'eventName': eventName,
      'eventPrice': eventPrice,
      'details': details,
      'visitorPax': visitorPax,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'days': days,
      'addOns': addOns,
      'totalPrice': totalPrice,
      'bookingDate': Timestamp.fromDate(bookingDate),
      'status': status,
    };
  }
}
