import 'package:firebase_core/firebase_core.dart';
import 'package:event_wise_2/component/drawer.dart';
import 'package:flutter/material.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:event_wise_2/page/profile_page.dart';
import 'package:event_wise_2/details/event_hall_packages.dart';
import 'component/AppBar.dart';
import 'app_state.dart';
import 'page/home_page.dart';
import 'page/event_hall_page.dart';
import 'page/booking_page.dart'; 
import 'details/event_hall_package.dart'; 
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(ChangeNotifierProvider(
    create: (context) => ApplicationState(),
    builder: (context, child) => const MyApp(),
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
      routerConfig: _router(),
    );
  }

  GoRouter _router() {
    return GoRouter(
      routes: [
        GoRoute(
          path: '/sign-in',
          builder: (context, state) {
            return SignInScreen(
              actions: [
                ForgotPasswordAction((context, email) {
                  final uri = Uri(
                    path: '/sign-in/forgot-password',
                    queryParameters: <String, String?>{
                      'email': email,
                    },
                  );
                  context.push(uri.toString());
                }),
                AuthStateChangeAction((context, state) {
                  User? user;
                  if (state is SignedIn) {
                    user = state.user;
                  } else if (state is UserCreated) {
                    user = state.credential.user;
                  } else {
                    user = null;
                  }

                  if (user != null) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Welcome!')),
                      );
                      context.go('/');
                    }
                  }
                }),
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
            GoRoute(
              path: '/event-hall', 
              builder: (context, state) {
                return EventHallPage(
                  eventHallPackages: eventHallPackages,
                  headerMaxExtent: 200, 
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
          ],
        ),
      ],
    );
  }
}