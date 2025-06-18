import 'package:event_wise_2/component/drawer.dart';
import 'package:event_wise_2/details/event_hall_packages.dart';
import 'package:event_wise_2/page/admin_page.dart'; // From 'admin' branch
import 'package:event_wise_2/page/custom_register_page.dart';
import 'package:event_wise_2/page/custom_sign_in_page.dart';
import 'package:event_wise_2/page/profile_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'app_state.dart';
import 'component/AppBar.dart';
import 'details/event_hall_package.dart';
import 'firebase_options.dart';
import 'page/booking_edit_page.dart'; // Import the BookingEditPage widget
import 'page/booking_page.dart'; // From 'main' branch
import 'page/event_hall_page.dart'; // From 'main' branch
import 'page/home_page.dart'; // From 'main' branch
import 'page/mybookings.dart'; // From 'main' branch


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    ChangeNotifierProvider(
      create: (context) => ApplicationState(),
      builder: (context, child) => const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(title: 'Event Wise', routerConfig: _router());
  }

  GoRouter _router() {
    return GoRouter(
      routes: [
        GoRoute(
          path: '/sign-in',
          // Replace FirebaseUI's SignInScreen with your CustomSignInPage
          builder: (context, state) {
            return const CustomSignInPage();
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

        GoRoute(
          path: '/register',
          builder: (context, state) {
            return const CustomRegisterPage();
          },
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
            GoRoute(path: '/', builder: (context, state) => const HomePage()),
            GoRoute(
              path: '/profile',
              redirect: (context, state) {
                final appState = Provider.of<ApplicationState>(
                  context,
                  listen: false,
                );
                if (!appState.loggedIn) {
                  return '/sign-in';
                }
                return null;
              },
              builder: (context, state) {
                return const CustomProfilePage();
              },
            ),
            GoRoute(
              path: '/event-hall',
              builder: (context, state) {
                return EventHallPage(
                  eventHallPackages: eventHallPackages,
                  headerMaxExtent: 200,
                );
              },
            ),
            // Routes from 'main' branch
            GoRoute(
              path: '/mybookings',
              builder: (context, state) {
                return MyBookingsPage();
              },
            ),
            GoRoute(

              path: '/edit-booking',
              builder: (context, state) {
                final extra = state.extra as Map<String, dynamic>;
                return BookingEditPage(
                  docId: extra['docId'],
                  data: extra['data'],
                );
              },
            ),


GoRoute(
  path: '/booking',
  builder: (context, state) {
    final EventHallPackage? package = state.extra as EventHallPackage?;
    if (package == null) {
      return const Text('Error: Event Hall Package details not found.');
    }
    return BookingPage(eventHallPackage: package);
  },
),

            // Route from 'admin' branch
            GoRoute(
              path: '/admin', // New route for admin page
              redirect: (context, state) {

                final appState = Provider.of<ApplicationState>(
                  context,
                  listen: false,
                );

                // In a real app, you would also check for admin role:
                if (!appState.loggedIn || !appState.isAdmin) {
                  return '/sign-in';
                }
                return null;
              },
              builder: (context, state) {
                return const AdminPage(); // The new AdminPage
              },
            ),
          ],
        ),
      ],
    );
  }
}
