import 'package:event_wise_2/component/drawer.dart';
import 'package:event_wise_2/details/event_hall_packages.dart';
import 'package:event_wise_2/page/admin_page.dart';
import 'package:event_wise_2/page/custom_register_page.dart';
import 'package:event_wise_2/page/custom_sign_in_page.dart';
import 'package:event_wise_2/page/payment_page.dart';
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
import 'page/booking_edit_page.dart';
import 'page/booking_page.dart';
import 'page/event_hall_page.dart';
import 'page/home_page.dart';
import 'page/mybookings.dart';
import 'component/theme_notifier.dart'; 
import 'page/settings_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ApplicationState()),
        ChangeNotifierProvider(create: (context) => ThemeNotifier()), 
      ],
      child: const MyApp(),
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
    final themeNotifier = Provider.of<ThemeNotifier>(context); // Listen to theme changes

    return MaterialApp.router(
      title: 'Event Wise',
      debugShowCheckedModeBanner: false,
theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: const Color(0xFFB8860B),
        hintColor: const Color(0xFFD4AF37),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(color: Colors.black45, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black),
          bodyMedium: TextStyle(color: Colors.black87),
          titleLarge: TextStyle(color: Colors.black),
          displayLarge: TextStyle(color: Colors.black),
          displayMedium: TextStyle(color: Colors.black),
          displaySmall: TextStyle(color: Colors.black),
          headlineMedium: TextStyle(color: Colors.black),
          headlineSmall: TextStyle(color: Colors.black),
          titleMedium: TextStyle(color: Colors.black),
          labelLarge: TextStyle(color: Colors.black),
          bodySmall: TextStyle(color: Colors.black),
          labelSmall: TextStyle(color: Colors.black),
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFB8860B),
          brightness: Brightness.light,
        ).copyWith(
          secondary: Colors.black,
          surface: Colors.white,
          onSurface: Colors.black,
          background: Colors.white,
          onBackground: Colors.black,
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFFB8860B), // Dark Gold
        hintColor: const Color(0xFFD4AF37),   // Regular Gold
        scaffoldBackgroundColor: Colors.black, // Default background for dark mode
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white70),
          titleLarge: TextStyle(color: Colors.white),
          displayLarge: TextStyle(color: Colors.white),
          displayMedium: TextStyle(color: Colors.white),
          displaySmall: TextStyle(color: Colors.white),
          headlineMedium: TextStyle(color: Colors.white),
          headlineSmall: TextStyle(color: Colors.white),
          titleMedium: TextStyle(color: Colors.white),
          labelLarge: TextStyle(color: Colors.white),
          bodySmall: TextStyle(color: Colors.white),
          labelSmall: TextStyle(color: Colors.white),
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFB8860B),
          brightness: Brightness.dark,
        ).copyWith(
          secondary: Colors.black,
          surface: Colors.black,
          onSurface: const Color.fromARGB(255, 37, 33, 33),
          background: Colors.black,
          onBackground: Colors.white,
        ),
      ),
      themeMode: themeNotifier.themeMode, 
      routerConfig: _router(),
    );
  }

  GoRouter _router() {
    return GoRouter(
      routes: [
        GoRoute(
          path: '/sign-in',
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
              appBar: const CustomAppBar(),
              drawer: const Drawerbar(menuItems: []),
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
            GoRoute(
              path: '/mybookings',
              builder: (context, state) {
                return MyBookingsPage();
              },
            ),
            GoRoute(
              path: '/payment',
              builder: (context, state) {
                final Map<String, dynamic> args = state.extra as Map<String, dynamic>;
                final String bookingId = args['bookingId'] as String;
                final Map<String, dynamic> bookingData = args['bookingData'] as Map<String, dynamic>;
                return PaymentPage(
                  bookingId: bookingId,
                  bookingData: bookingData,
                );
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
            GoRoute(
              path: '/admin',
              redirect: (context, state) {
                final appState = Provider.of<ApplicationState>(
                  context,
                  listen: false,
                );
                if (!appState.loggedIn || !appState.isAdmin) {
                  return '/sign-in';
                }
                return null;
              },
              builder: (context, state) {
                return const AdminPage();
              },
            ),
            // New route for settings page
            GoRoute(
              path: '/settings',
              builder: (context, state) {
                return const SettingsPage();
              },
            ),
          ],
        ),
      ],
    );
  }
}