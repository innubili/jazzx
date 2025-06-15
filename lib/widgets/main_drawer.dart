import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../widgets/custom_drawer.dart';
import '../providers/user_profile_provider.dart';

class MainDrawer extends StatelessWidget {
  const MainDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<UserProfileProvider>(
      context,
      listen: false,
    );
    final profile = profileProvider.profile;
    final bool isAdmin = profile?.preferences.admin ?? false;
    return CustomDrawer(
      items: [
        DrawerItem(
          label: 'Session (Home)',
          icon: Icons.home,
          onTap: () => _navigate(context, '/'),
        ),
        DrawerItem(
          label: 'Metronome',
          icon: Icons.music_note,
          onTap: () => _navigate(context, '/metronome'),
        ),
        DrawerItem(
          label: 'My Songs',
          icon: Icons.bookmark,
          onTap: () => _navigate(context, '/user-songs'),
        ),
        DrawerItem(
          label: 'Jazz Standards',
          icon: Icons.library_music,
          onTap: () => _navigate(context, '/jazz-standards'),
        ),
        DrawerItem(
          label: 'Session Log',
          icon: Icons.history,
          onTap: () => _navigate(context, '/session-log'),
        ),
        DrawerItem(
          label: 'Statistics',
          icon: Icons.bar_chart,
          onTap: () => _navigate(context, '/statistics'),
        ),
        DrawerItem(
          label: 'Settings',
          icon: Icons.settings,
          onTap: () => _navigate(context, '/settings'),
        ),
        if (isAdmin) ...[
          DrawerItem(
            label: 'Admin',
            icon: Icons.admin_panel_settings,
            onTap: () => _navigate(context, '/admin'),
          ),
        ],
        DrawerItem(
          label: 'About',
          icon: Icons.info,
          onTap: () => _navigate(context, '/about'),
        ),
        DrawerItem(
          label: 'Logout',
          icon: Icons.logout,
          onTap: () => _logout(context),
        ),
      ],
    );
  }

  void _navigate(BuildContext context, String routeName) {
    Navigator.pop(context); // Close drawer first
    Navigator.pushNamed(context, routeName);
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirm Logout'),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Logout'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      await FirebaseAuth.instance.signOut();
      // ❌ no manual navigation anymore!
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Logged out successfully")),
        );
      }
    }
  }
}
