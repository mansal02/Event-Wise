import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../service/database.dart'; // Import your DatabaseService

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DatabaseService _databaseService = DatabaseService();

  final List<String> _bookingStatuses = ['Pending', 'Accepted', 'Rejected']; // Define valid statuses once

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this); // Two tabs: Users, Bookings
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Users', icon: Icon(Icons.people)),
            Tab(text: 'Bookings', icon: Icon(Icons.event)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUserTab(),
          _buildBookingTab(),
        ],
      ),
    );
  }

  Widget _buildUserTab() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(), // Stream all users
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No registered users found.'));
        }

        final users = snapshot.data!.docs;

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index].data();
            final userId = users[index].id;
            return Card(
              margin: const EdgeInsets.all(8.0),
              child: ExpansionTile(
                title: Text(user['name'] ?? 'N/A'),
                subtitle: Text(user['email'] ?? 'N/A'),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('User ID: $userId'),
                        Text('Phone Number: ${user['phoneNumber'] ?? 'N/A'}'),
                        Text('Role: ${user['role'] ?? 'N/A'}'),
                        Text('Created At: ${user['createdAt'] != null ? (user['createdAt'] as Timestamp).toDate().toLocal().toString().split('.')[0] : 'N/A'}'),
                        Text('Last Login At: ${user['lastLoginAt'] != null ? (user['lastLoginAt'] as Timestamp).toDate().toLocal().toString().split('.')[0] : 'N/A'}'),
                        const Divider(),
                        const Text('Associated Bookings:', style: TextStyle(fontWeight: FontWeight.bold)),
                        // Nested StreamBuilder for user's bookings
                        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                          stream: _databaseService.getUserBookings(userId),
                          builder: (context, bookingSnapshot) {
                            if (bookingSnapshot.connectionState == ConnectionState.waiting) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8.0),
                                child: Text('Loading bookings...'),
                              );
                            }
                            if (bookingSnapshot.hasError) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Text('Error loading bookings: ${bookingSnapshot.error}'),
                              );
                            }
                            if (!bookingSnapshot.hasData || bookingSnapshot.data!.docs.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8.0),
                                child: Text('No bookings found for this user.'),
                              );
                            }

                            final userBookings = bookingSnapshot.data!.docs;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: userBookings.map((bookingDoc) {
                                final booking = bookingDoc.data();
                                final associatedBookingId = bookingDoc.id; // Get the booking ID for edit/delete
                                return Padding(
                                  padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '  - ${booking['eventHallName'] ?? 'N/A'} '
                                          '(Package: ${booking['packageName'] ?? 'N/A'})\n'
                                          '    Booked: ${booking['bookingDate'] != null ? (booking['bookingDate'] as Timestamp).toDate().toLocal().toString().split('.')[0] : 'N/A'}\n'
                                          '    Event: ${booking['eventDate'] != null ? (booking['eventDate'] as Timestamp).toDate().toLocal().toString().split('.')[0] : 'N/A'} '
                                          '${booking['eventTime'] ?? 'N/A'}',
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                                            onPressed: () => _editBookingDialog(associatedBookingId, booking),
                                            tooltip: 'Edit Booking',
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                            onPressed: () => _confirmDeleteBooking(associatedBookingId),
                                            tooltip: 'Delete Booking',
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _editUserDialog(userId, user),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _confirmDeleteUser(userId, user['name'] ?? 'this user'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBookingTab() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _databaseService.getAllBookings(), // Use the method from DatabaseService
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No bookings found.'));
        }

        final bookings = snapshot.data!.docs;

        return ListView.builder(
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            final booking = bookings[index].data();
            final bookingId = bookings[index].id;
            final userId = booking['userId'] as String?; // Get userId from booking

            return Card(
              margin: const EdgeInsets.all(8.0),
              child: ExpansionTile(
                title: Text('Booking ID: ${booking['bookingId'] ?? bookingId}'),
                subtitle: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>?>(
                  future: userId != null ? _databaseService.getUser(userId) : Future.value(null),
                  builder: (context, userSnapshot) {
                    if (userSnapshot.connectionState == ConnectionState.waiting) {
                      return const Text('User: Loading...');
                    }
                    if (userSnapshot.hasError || !userSnapshot.hasData || !userSnapshot.data!.exists) {
                      return const Text('User: Unknown/Deleted');
                    }
                    final userData = userSnapshot.data!.data();
                    return Text('User: ${userData?['name'] ?? userData?['email'] ?? 'N/A'}');
                  },
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('User ID: ${userId ?? 'N/A'}'),
                        Text('Event Hall: ${booking['eventHallName'] ?? 'N/A'}'),
                        Text('Package: ${booking['packageName'] ?? 'N/A'}'),
                        Text('Booking Date: ${booking['bookingDate'] != null ? (booking['bookingDate'] as Timestamp).toDate().toLocal().toString().split('.')[0] : 'N/A'}'),
                        Text('Event Date: ${booking['eventDate'] != null ? (booking['eventDate'] as Timestamp).toDate().toLocal().toString().split('.')[0] : 'N/A'}'),
                        Text('Event Time: ${booking['eventTime'] ?? 'N/A'}'),
                        Text('Status: ${booking['status'] ?? 'Pending'}'), // Example status
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _editBookingDialog(bookingId, booking),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _confirmDeleteBooking(bookingId),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _editUserDialog(String userId, Map<String, dynamic> currentUserData) {
    final TextEditingController nameController = TextEditingController(text: currentUserData['name']);
    final TextEditingController emailController = TextEditingController(text: currentUserData['email']);
    final TextEditingController phoneController = TextEditingController(text: currentUserData['phoneNumber']);
    final TextEditingController roleController = TextEditingController(text: currentUserData['role']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit User Information'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                ),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Phone Number'),
                  keyboardType: TextInputType.phone,
                ),
                TextField(
                  controller: roleController,
                  decoration: const InputDecoration(labelText: 'Role'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final updatedData = {
                  'name': nameController.text.trim(),
                  'email': emailController.text.trim(),
                  'phoneNumber': phoneController.text.trim(),
                  'role': roleController.text.trim(),
                };
                await _databaseService.updateUserData(userId, updatedData);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('User updated successfully!')),
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteUser(String userId, String userName) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete User'),
          content: Text('Are you sure you want to delete user "$userName"? This will also delete their bookings.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                // In a real app, you might want to delete related bookings first
                // or handle the user's data more comprehensively.
                // Assuming DatabaseService.deleteDocData for 'users' collection is implemented to delete user document
                await _databaseService.deleteDocData('users', userId);
                // You might also want to delete all bookings associated with this user
                // (This would require an additional method in DatabaseService, e.g., deleteAllUserBookings(userId))
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('User and their bookings (if any) deleted successfully!')),
                  );
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _editBookingDialog(String bookingId, Map<String, dynamic> currentBookingData) {
    final TextEditingController eventHallNameController = TextEditingController(text: currentBookingData['eventHallName']);
    final TextEditingController packageNameController = TextEditingController(text: currentBookingData['packageName']);
    final TextEditingController eventDateController = TextEditingController(text: currentBookingData['eventDate'] != null ? (currentBookingData['eventDate'] as Timestamp).toDate().toLocal().toString().split(' ')[0] : '');
    final TextEditingController eventTimeController = TextEditingController(text: currentBookingData['eventTime']);

    // Ensure selectedStatus is one of the valid options, otherwise default to 'Pending'
    String? initialStatus = currentBookingData['status'];
    String? selectedStatus = _bookingStatuses.contains(initialStatus) ? initialStatus : 'Pending';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Booking Information'),
          content: SingleChildScrollView(
            child: StatefulBuilder( // Use StatefulBuilder to manage dialog's internal state
              builder: (BuildContext context, StateSetter setState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: eventHallNameController,
                      decoration: const InputDecoration(labelText: 'Event Hall Name'),
                      enabled: false, // Made uneditable
                    ),
                    TextField(
                      controller: packageNameController,
                      decoration: const InputDecoration(labelText: 'Package Name'),
                      enabled: false, // Made uneditable
                    ),
                    TextField(
                      controller: eventDateController,
                      decoration: const InputDecoration(labelText: 'Event Date (YYYY-MM-DD)'),
                      keyboardType: TextInputType.datetime,
                      onTap: () async {
                        FocusScope.of(context).unfocus(); // Dismiss keyboard
                        DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2101),
                        );
                        if (pickedDate != null) {
                          setState(() { // Update state within StatefulBuilder
                            eventDateController.text = pickedDate.toLocal().toString().split(' ')[0]; 
                          });
                        }
                      },
                    ),
                    TextField(
                      controller: eventTimeController,
                      decoration: const InputDecoration(labelText: 'Event Time (e.g., 10:00 AM)'),
                    ),
                    // DropdownButtonFormField for status
                    DropdownButtonFormField<String>(
                      value: selectedStatus,
                      decoration: const InputDecoration(labelText: 'Status'),
                      items: _bookingStatuses // Use the predefined list of statuses
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() { // Update state within StatefulBuilder
                          selectedStatus = newValue;
                        });
                      },
                    ),
                  ],
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Timestamp? eventDateTimestamp;
                try {
                  if (eventDateController.text.isNotEmpty) {
                    eventDateTimestamp = Timestamp.fromDate(DateTime.parse(eventDateController.text));
                  }
                } catch (e) {
                  // Show snackbar for invalid date format
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Invalid event date format. Please use YYYY-MM-DD.')),
                    );
                  }
                  return; // Stop function execution if date is invalid
                }

                final updatedData = {
                  'eventHallName': eventHallNameController.text.trim(),
                  'packageName': packageNameController.text.trim(),
                  'eventDate': eventDateTimestamp,
                  'eventTime': eventTimeController.text.trim(),
                  'status': selectedStatus, // Use the selected status from Dropdown
                };
                await _databaseService.updateBooking(bookingId, updatedData);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Booking updated successfully!')),
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteBooking(String bookingId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Booking'),
          content: const Text('Are you sure you want to delete this booking?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _databaseService.deleteBooking(bookingId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Booking deleted successfully!')),
                  );
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}