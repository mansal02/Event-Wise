import 'package:firebase_auth/firebase_auth.dart'
    hide EmailAuthProvider, PhoneAuthProvider;
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../firebase_repo/authentication.dart';

import 'package:flutter/material.dart';
import 'sidebar_list.dart';
import 'package:go_router/go_router.dart';
import '../page/settings_page.dart';

class Drawerbar extends StatelessWidget {
  final List<Map<String, String>> menuItems;

  const Drawerbar({super.key, required this.menuItems});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.black,
      child: Consumer<ApplicationState>(
        builder: (context, appState, _) {
          final auth = FirebaseAuth.instance;
          final user = auth.currentUser;

          return Column(
            children: [
              DrawerHeader(
                
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 65,
                    ),
                    if (appState.loggedIn && user != null)
                      Text(
                        user.displayName ?? user.email ?? 'N/A',
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                      )
                    else
                      AuthFunc(
                        loggedIn: appState.loggedIn,
                        signOut: () {
                          FirebaseAuth.instance.signOut();
                        },
                      ),
                  ],
                ),
              ),
              SideBarList(
                icon: Icons.home,
                text: 'H O M E',
                onTap: () {
                  context.go('/');
                },
              ),
              if (appState.loggedIn)
                SideBarList(
                  icon: Icons.person,
                  text: 'P R O F I L E',
                  onTap: () {
                    context.go('/profile');
                  },
                ),
              SideBarList(
                icon: Icons.settings,
                text: 'S E T T I N G S',
                onTap: () {
                  context.go('/settings');
                },
              ),
              SideBarList(
                icon: Icons.calendar_today,
                text: 'E V E N T S   H A L L',
                onTap: () {
                  context.go('/event-hall');
                },
              ),
              SideBarList(
                icon: Icons.event_available,
                text: 'M Y   B O O K I N G S',
                onTap: () {
                  context.go('/mybookings');
                },
              ),
              if (appState.loggedIn && appState.isAdmin)
                SideBarList(
                  icon: Icons.admin_panel_settings,
                  text: 'A D M I N   P A N E L',
                  onTap: () {
                    context.go('/admin');
                  },
                ),
              const Spacer(),
              if (appState.loggedIn)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: SideBarList(
                    icon: Icons.logout,
                    text: 'L O G O U T',
                    onTap: () {
                      FirebaseAuth.instance.signOut();
                      context.go('/');
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}