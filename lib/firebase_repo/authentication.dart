import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widget/widgets.dart';

class AuthFunc extends StatelessWidget {
  const AuthFunc({super.key, required this.loggedIn, required this.signOut});

  final bool loggedIn;
  final void Function() signOut;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.only(left: 24, bottom: 8),
              child: StyledButton(
                onPressed: () {
                  // Navigate to your custom sign-in page
                  !loggedIn ? context.push('/sign-in') : signOut();
                },
                child: !loggedIn ? const Text('Login') : const Text('Logout'),
              ),
            ),
          ),
        ),
      ],
    );
  }
}