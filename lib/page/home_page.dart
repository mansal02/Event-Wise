import 'package:flutter/material.dart';

import '../component/event_hall_preview.dart';
import '../component/header.dart';
import '../component/preview_list.dart';
import '../details/event_hall_package.dart'; // The package model
import '../details/event_hall_packages.dart'; // The original list of packages

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _searchQuery = ''; // State variable to hold the current search query
  List<EventHallPackage> _filteredEventHallPackages = []; // List to hold filtered packages

  @override
  void initState() {
    super.initState();
    _filterPackages(); // Call filter once initially to show all packages
  }

  // Method to update the search query and trigger a re-filter
  void _updateSearchQuery(String query) {
    setState(() {
      _searchQuery = query;
      _filterPackages(); // Re-filter packages whenever the query changes
    });
  }

  // Method to filter the event hall packages based on the search query
  void _filterPackages() {
    if (_searchQuery.isEmpty) {
      // If search query is empty, show all packages
      _filteredEventHallPackages = List.from(eventHallPackages); // Create a mutable copy
    } else {
      // Filter packages whose title or description contains the search query
      _filteredEventHallPackages = eventHallPackages.where((package) {
        final queryLower = _searchQuery.toLowerCase();
        return package.title.toLowerCase().contains(queryLower) ||
               package.description.toLowerCase().contains(queryLower);
      }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Header(
              size: size,
              onSearchChanged: _updateSearchQuery, // <--- THIS IS THE CRUCIAL LINE
            ),
            PreviewList(), // Assuming this widget does not need to be filtered by search
            EventHallPreview(
              eventHallPackages: _filteredEventHallPackages, // Pass the filtered list
              size: size,
            ),
          ],
        ),
      ),
    );
  }
}