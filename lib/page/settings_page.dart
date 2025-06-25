// lib/settings_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:event_wise_2/component/theme_notifier.dart'; // Make sure this path is correct based on your project structure

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(color: Colors.white),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFB8860B), // Dark Gold as primary
                Colors.black,      // Black as secondary
              ],
              stops: [0.00, 1.0],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.black,      // Start with black
              Color(0xFFB8860B), // End with dark gold
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ListView(
          children: [
            ListTile(
              title: const Text('Dark Mode', style: TextStyle(color: Colors.white)),
              trailing: Switch(
                value: themeNotifier.themeMode == ThemeMode.dark,
                onChanged: (value) {
                  themeNotifier.toggleTheme();
                },
                activeColor: const Color(0xFFB8860B), // Dark Gold for active switch
                inactiveThumbColor: Colors.grey,
                inactiveTrackColor: Colors.grey.withOpacity(0.5),
              ),
            ),
            // You can add more settings options here (e.g., Notifications, Language)
          ],
        ),
      ),
    );
  }
}