import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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
        title: const Text('Admin Panel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepPurple, // Modern app bar color
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white, // Indicator for selected tab
          labelColor: Colors.white, // Text color for selected tab
          unselectedLabelColor: Colors.deepPurple.shade200, // Text color for unselected tabs
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
          return const Center(child: CircularProgressIndicator(color: Colors.deepPurple));
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No registered users found.', style: TextStyle(color: Colors.grey)));
        }

        final users = snapshot.data!.docs;
        final List<Map<String, dynamic>> adminUsers = [];
        final List<Map<String, dynamic>> regularUsers = [];

        for (var userDoc in users) {
          final userData = userDoc.data();
          userData['id'] = userDoc.id; // Add document ID to user data for easier access
          if (userData['role'] == 'admin') {
            adminUsers.add(userData);
          } else {
            regularUsers.add(userData);
          }
        }

        return ListView(
          padding: const EdgeInsets.all(12.0),
          children: [
            _buildUserSection(context, 'Administrators', adminUsers, isAdminSection: true),
            const SizedBox(height: 20),
            _buildUserSection(context, 'Regular Users', regularUsers, isAdminSection: false),
          ],
        );
      },
    );
  }

  Widget _buildUserSection(BuildContext context, String title, List<Map<String, dynamic>> users, {required bool isAdminSection}) {
    if (users.isEmpty) {
      return Card(
        elevation: 3,
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isAdminSection ? Colors.deepPurple : Colors.blueGrey.shade800,
                ),
              ),
              const Divider(color: Colors.grey),
              Center(child: Text('No $title found.', style: const TextStyle(color: Colors.grey))),
            ],
          ),
        ),
      );
    }
    return Card(
      elevation: 5,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isAdminSection ? Colors.deepPurple : Colors.blueGrey.shade800,
              ),
            ),
            const Divider(color: Colors.grey),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(), // Important for nested list views
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                final userId = user['id'] as String;
                return _buildUserListItem(context, user, userId, isAdminSection);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserListItem(BuildContext context, Map<String, dynamic> user, String userId, bool isAdminUser) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: isAdminUser ? Colors.deepPurple.shade100 : Colors.blue.shade100,
          child: Icon(isAdminUser ? Icons.star : Icons.person, color: isAdminUser ? Colors.deepPurple : Colors.blue),
        ),
        title: Text(
          user['originalName'] ?? user['name'] ?? 'N/A',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(user['email'] ?? 'N/A', style: TextStyle(color: Colors.grey.shade600)),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('User ID:', userId),
                _buildInfoRow('Phone Number:', user['phoneNumber'] ?? 'N/A'),
                _buildInfoRow('Role:', user['role'] ?? 'N/A',
                    color: isAdminUser ? Colors.deepPurple : Colors.blue),
                _buildInfoRow('Created At:', user['createdAt'] != null ? (user['createdAt'] as Timestamp).toDate().toLocal().toString().split('.')[0] : 'N/A'),
                _buildInfoRow('Last Login At:', user['lastLoginAt'] != null ? (user['lastLoginAt'] as Timestamp).toDate().toLocal().toString().split('.')[0] : 'N/A'),
                const SizedBox(height: 10),
                const Text('Associated Bookings:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.blueGrey)),
                // Nested StreamBuilder for user's bookings
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _databaseService.getUserBookings(userId),
                  builder: (context, bookingSnapshot) {
                    if (bookingSnapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text('Loading bookings...', style: TextStyle(color: Colors.grey)),
                      );
                    }
                    if (bookingSnapshot.hasError) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text('Error loading bookings: ${bookingSnapshot.error}', style: const TextStyle(color: Colors.red)),
                      );
                    }
                    if (!bookingSnapshot.hasData || bookingSnapshot.data!.docs.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text('No bookings found for this user.', style: TextStyle(color: Colors.grey)),
                      );
                    }

                    final userBookings = bookingSnapshot.data!.docs;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: userBookings.map((bookingDoc) {
                        final booking = bookingDoc.data();
                        final associatedBookingId = bookingDoc.id; // Get the booking ID for edit/delete
                        return Padding(
                          padding: const EdgeInsets.only(left: 8.0, bottom: 4.0, top: 4.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8.0),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Hall: ${booking['eventHallName'] ?? 'N/A'}',
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                      ),
                                      Text(
                                        'Package: ${booking['packageName'] ?? 'N/A'}',
                                        style: const TextStyle(fontSize: 13, color: Colors.blueGrey),
                                      ),
                                      Text(
                                        'Booked: ${booking['bookingDate'] != null ? (booking['bookingDate'] as Timestamp).toDate().toLocal().toString().split('.')[0] : 'N/A'}',
                                        style: const TextStyle(fontSize: 13, color: Colors.blueGrey),
                                      ),
                                      Text(
                                        'Event: ${booking['eventDate'] != null ? (booking['eventDate'] as Timestamp).toDate().toLocal().toString().split('.')[0] : 'N/A'} ${booking['eventTime'] ?? 'N/A'}',
                                        style: const TextStyle(fontSize: 13, color: Colors.blueGrey),
                                      ),
                                      Text(
                                        'Status: ${booking['status'] ?? 'Pending'}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: _getStatusColor(booking['status']),
                                        ),
                                      ),
                                    ],
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
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Role Management Button
                    if (isAdminUser)
                      ElevatedButton.icon(
                        onPressed: () => _revokeAdminRole(userId, user['originalName'] ?? user['name']),
                        icon: const Icon(Icons.person_remove, size: 18),
                        label: const Text('Revoke Admin'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange, // A distinct color for revoke
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      )
                    else
                      ElevatedButton.icon(
                        onPressed: () => _grantAdminRole(userId, user['originalName'] ?? user['name']),
                        icon: const Icon(Icons.verified_user, size: 18),
                        label: const Text('Grant Admin'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green, // A distinct color for grant
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _editUserDialog(userId, user),
                      tooltip: 'Edit User',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _confirmDeleteUser(userId, user['originalName'] ?? user['name']),
                      tooltip: 'Delete User',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper for consistent info rows
  Widget _buildInfoRow(String label, String value, {Color color = Colors.black87}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label ',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
            ),
            TextSpan(
              text: value,
              style: TextStyle(color: color),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'Accepted':
        return Colors.green;
      case 'Rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildBookingTab() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _databaseService.getAllBookings(), // Use the method from DatabaseService
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.deepPurple));
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No bookings found.', style: TextStyle(color: Colors.grey)));
        }

        final bookings = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(12.0),
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            final booking = bookings[index].data();
            final bookingId = bookings[index].id;
            final userId = booking['userId'] as String?; // Get userId from booking

            return Card(
              margin: const EdgeInsets.all(8.0),
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
              child: ExpansionTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.teal.shade100,
                  child: const Icon(Icons.event_note, color: Colors.teal),
                ),
                title: Text(
                  'Booking ID: ${booking['bookingId'] ?? bookingId}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                subtitle: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>?>(
                  future: userId != null ? _databaseService.getUser(userId) : Future.value(null),
                  builder: (context, userSnapshot) {
                    if (userSnapshot.connectionState == ConnectionState.waiting) {
                      return const Text('User: Loading...', style: TextStyle(color: Colors.grey));
                    }
                    if (userSnapshot.hasError || !userSnapshot.hasData || !userSnapshot.data!.exists) {
                      return const Text('User: Unknown/Deleted', style: TextStyle(color: Colors.redAccent));
                    }
                    final userData = userSnapshot.data!.data();
                    return Text('User: ${userData?['originalName'] ?? userData?['name'] ?? userData?['email'] ?? 'N/A'}', style: TextStyle(color: Colors.grey.shade600));
                  },
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow('User ID:', userId ?? 'N/A'),
                        _buildInfoRow('Event Hall:', booking['eventHallName'] ?? 'N/A'),
                        _buildInfoRow('Package:', booking['packageName'] ?? 'N/A'),
                        _buildInfoRow('Booking Date:', booking['bookingDate'] != null ? (booking['bookingDate'] as Timestamp).toDate().toLocal().toString().split('.')[0] : 'N/A'),
                        _buildInfoRow('Event Date:', booking['eventDate'] != null ? (booking['eventDate'] as Timestamp).toDate().toLocal().toString().split('.')[0] : 'N/A'),
                        _buildInfoRow('Event Time:', booking['eventTime'] ?? 'N/A'),
                        _buildInfoRow('Status:', booking['status'] ?? 'Pending', color: _getStatusColor(booking['status'])),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _editBookingDialog(bookingId, booking),
                              tooltip: 'Edit Booking',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _confirmDeleteBooking(bookingId),
                              tooltip: 'Delete Booking',
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
    final TextEditingController nameController = TextEditingController(text: currentUserData['originalName'] ?? currentUserData['name']);
    final TextEditingController emailController = TextEditingController(text: currentUserData['email']);
    final TextEditingController phoneController = TextEditingController(text: currentUserData['phoneNumber']);
    String? selectedRole = currentUserData['role']; // Initial role

    final List<String> availableRoles = ['user', 'admin']; // Define available roles

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
          title: const Text('Edit User Information', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple)),
          content: SingleChildScrollView(
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Name',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        prefixIcon: const Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        prefixIcon: const Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      enabled: false, // Email usually not editable from admin panel
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: phoneController,
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        prefixIcon: const Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: selectedRole,
                      decoration: InputDecoration(
                        labelText: 'Role',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        prefixIcon: const Icon(Icons.verified_user),
                      ),
                      items: availableRoles.map((String role) {
                        return DropdownMenuItem<String>(
                          value: role,
                          child: Text(role.toUpperCase()),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedRole = newValue;
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
              style: TextButton.styleFrom(foregroundColor: Colors.grey.shade700),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final updatedData = {
                  'originalName': nameController.text.trim(),
                  'name': nameController.text.trim().toLowerCase(), // Update lowercase name too
                  'phoneNumber': phoneController.text.trim(),
                  'role': selectedRole,
                };
                await _databaseService.updateUserData(userId, updatedData);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('User updated successfully!', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green),
                  );
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
          title: const Text('Delete User', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
          content: Text('Are you sure you want to delete user "$userName"? This action is irreversible and will delete all associated data (like bookings).', style: const TextStyle(color: Colors.black87)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(foregroundColor: Colors.grey.shade700),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Delete associated bookings first
                final userBookingsSnapshot = await _databaseService.getUserBookings(userId).first;
                for (var doc in userBookingsSnapshot.docs) {
                  await _databaseService.deleteBooking(doc.id);
                }
                // Then delete the user
                await _databaseService.deleteDocData('users', userId);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('User and all their bookings deleted successfully!', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green),
                  );
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _grantAdminRole(String userId, String? userName) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
          title: const Text('Grant Admin Role', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
          content: Text('Are you sure you want to grant admin role to "${userName ?? 'this user'}"?', style: const TextStyle(color: Colors.black87)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(foregroundColor: Colors.grey.shade700),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _databaseService.grantAdminRole(userId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${userName ?? 'User'} is now an admin!', style: const TextStyle(color: Colors.white)), backgroundColor: Colors.green),
                  );
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Grant'),
            ),
          ],
        );
      },
    );
  }

  void _revokeAdminRole(String userId, String? userName) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
          title: const Text('Revoke Admin Role', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
          content: Text('Are you sure you want to revoke admin role from "${userName ?? 'this user'}"?', style: const TextStyle(color: Colors.black87)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(foregroundColor: Colors.grey.shade700),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _databaseService.revokeAdminRole(userId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${userName ?? 'User'}\'s admin role has been revoked!', style: const TextStyle(color: Colors.white)), backgroundColor: Colors.orange),
                  );
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Revoke'),
            ),
          ],
        );
      },
    );
  }

  void _editBookingDialog(String bookingId, Map<String, dynamic> currentBookingData) {
    final TextEditingController eventHallNameController = TextEditingController(text: currentBookingData['eventHallName']);
    final TextEditingController packageNameController = TextEditingController(text: currentBookingData['packageName']);
    final TextEditingController eventDateController = TextEditingController(text: currentBookingData['eventDate'] != null
        ? (currentBookingData['eventDate'] as Timestamp).toDate().toLocal().toString().split(' ')[0]: '');

    final TextEditingController eventTimeController = TextEditingController(text: currentBookingData['eventTime']);

    String? initialStatus = currentBookingData['status'];
    String? selectedStatus = _bookingStatuses.contains(initialStatus) ? initialStatus : 'Pending';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
          title: const Text('Edit Booking Information', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
          content: SingleChildScrollView(
            child: StatefulBuilder( // Use StatefulBuilder to manage dialog's internal state
              builder: (BuildContext context, StateSetter setState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: eventHallNameController,
                      decoration: InputDecoration(
                        labelText: 'Event Hall Name',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        prefixIcon: const Icon(Icons.meeting_room),
                      ),
                      enabled: false, // Made uneditable
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: packageNameController,
                      decoration: InputDecoration(
                        labelText: 'Package Name',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        prefixIcon: const Icon(Icons.category),
                      ),
                      enabled: false, // Made uneditable
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: eventDateController,
                      decoration: InputDecoration(
                        labelText: 'Event Date (YYYY-MM-DD)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        prefixIcon: const Icon(Icons.calendar_today),
                      ),
                      keyboardType: TextInputType.datetime,
                      onTap: () async {
                        FocusScope.of(context).unfocus(); // Dismiss keyboard
                        DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2101),
                          builder: (context, child) {
                            return Theme(
                              data: ThemeData.light().copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: Colors.teal, // header background color
                                  onPrimary: Colors.white, // header text color
                                  onSurface: Colors.black, // body text color
                                ),
                                textButtonTheme: TextButtonThemeData(
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.teal, // button text color
                                  ),
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (pickedDate != null) {
                          setState(() { // Update state within StatefulBuilder
                            eventDateController.text = pickedDate.toLocal().toString().split(' ')[0];
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: eventTimeController,
                      decoration: InputDecoration(
                        labelText: 'Event Time (e.g., 10:00 AM)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        prefixIcon: const Icon(Icons.access_time),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // DropdownButtonFormField for status
                    DropdownButtonFormField<String>(
                      value: selectedStatus,
                      decoration: InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        prefixIcon: const Icon(Icons.check_circle_outline),
                      ),
                      items: _bookingStatuses // Use the predefined list of statuses
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value, style: TextStyle(color: _getStatusColor(value), fontWeight: FontWeight.bold)),
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
              style: TextButton.styleFrom(foregroundColor: Colors.grey.shade700),
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
                      const SnackBar(content: Text('Invalid event date format. Please use YYYY-MM-DD.', style: TextStyle(color: Colors.white)), backgroundColor: Colors.red),
                    );
                  }
                  return; // Stop function execution if date is invalid
                }

                final updatedData = {
                  'eventHallName': eventHallNameController.text.trim(),
                  'packageName': packageNameController.text.trim(), // Corrected from eventNameController
                  'eventDate': eventDateTimestamp,
                  'eventTime': eventTimeController.text.trim(),
                  'status': selectedStatus, // Use the selected status from Dropdown
                };
                await _databaseService.updateBooking(bookingId, updatedData);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Booking updated successfully!', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green),
                  );
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
          title: const Text('Delete Booking', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
          content: const Text('Are you sure you want to delete this booking? This action is irreversible.', style: TextStyle(color: Colors.black87)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(foregroundColor: Colors.grey.shade700),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _databaseService.deleteBooking(bookingId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Booking deleted successfully!', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green),
                  );
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
