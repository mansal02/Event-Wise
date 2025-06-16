import 'package:event_wise_2/component/drawer.dart';
import 'package:flutter/material.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:event_wise_2/page/profile_page.dart';
import 'component/AppBar.dart'; // new

import 'app_state.dart';
import 'page/home_page.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Explicitly import User type

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(ChangeNotifierProvider(
    create: (context) => ApplicationState(),
    builder: ((context, child) => const MyApp()),
  ));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Event Wise',
      routerConfig: GoRouter(
        routes: [
          GoRoute(
            path: '/sign-in',
            builder: (context, state) {
              return SignInScreen(
                actions: [
                  ForgotPasswordAction(((context, email) {
                    final uri = Uri(
                      path: '/sign-in/forgot-password',
                      queryParameters: <String, String?>{
                        'email': email,
                      },
                    );
                    context.push(uri.toString());
                  })),
                  AuthStateChangeAction(((context, state) {
                    User? user;
                    // Correctly extract the user based on the AuthState type
                    if (state is SignedIn) {
                      user = state.user;
                    } else if (state is UserCreated) {
                      user = state.credential?.user; // Access user from credential for UserCreated
                    } else {
                      user = null;
                    }

                    if (user != null) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Welcome!'),
                        ));
                        context.go('/'); // Navigate to home and clear the navigation stack
                      }
                    }
                  })),
                ],
              );
            },
            routes: [
              GoRoute(
                path: 'forgot-password',
                builder: (context, state) {
                  final arguments = state.uri.queryParameters;
                  return ForgotPasswordScreen(
                    email: arguments['email'],
                    headerMaxExtent: 200,
                  );
                },
              ),
            ],
          ),
          ShellRoute(
            builder: (context, state, child) {
              return Scaffold(
                appBar: CustomAppBar(),
                drawer: Drawerbar(menuItems: []),
                body: child,
              );
            },
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const HomePage(),
              ),
              GoRoute(
                path: '/profile',
                redirect: (context, state) {
                  final appState = Provider.of<ApplicationState>(context, listen: false);
                  if (!appState.loggedIn) {
                    return '/sign-in';
                  }
                  return null;
                },
                builder: (context, state) {
                  return const CustomProfilePage();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}