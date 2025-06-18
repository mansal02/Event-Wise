// comments.dart
import 'dart:async';

import 'package:flutter/material.dart';

class Comments extends StatefulWidget {
  // Add the canComment parameter here
  final FutureOr<void> Function(String message) addMessage;
  final bool canComment; // This is the new parameter

  const Comments({
    super.key,
    required this.addMessage,
    this.canComment = true, // Set a default value to avoid breaking existing calls
  });

  @override
  State<Comments> createState() => _CommentsState();
}

class _CommentsState extends State<Comments> {
  final _formKey = GlobalKey<FormState>(debugLabel: '_CommentsState');
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Form(
        key: _formKey,
        child: Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _controller,
                readOnly: !widget.canComment, // Make it read-only if canComment is false
                decoration: InputDecoration(
                  hintText: widget.canComment ? 'Leave a message' : 'Login to comment', // Change hint text
                ),
                validator: (value) {
                  if (widget.canComment && (value == null || value.isEmpty)) { // Only validate if commenting is allowed
                    return 'Enter your message to continue';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
              onPressed: widget.canComment // Only enable if canComment is true
                  ? () async {
                      if (_formKey.currentState!.validate()) {
                        await widget.addMessage(_controller.text);
                        _controller.clear();
                      }
                    }
                  : null, // Disable the button if cannot comment
              child: Row(
                children: const [
                  Icon(Icons.send),
                  SizedBox(width: 4),
                  Text('SEND'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}