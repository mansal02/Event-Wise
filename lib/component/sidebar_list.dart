import 'package:flutter/material.dart';

class SideBarList extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  const SideBarList({
    super.key,
    required this.icon,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 10.0),
      child: ListTile(
        leading: Icon(icon, size: 24, color: Colors.white),
        title: Text(text, style: const TextStyle(fontSize: 18, color: Colors.white)),
        onTap: onTap,
      ),
    );
  }
}