import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_profile_provider.dart';

class DrawerItem {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  DrawerItem({required this.label, required this.icon, required this.onTap});
}

class CustomDrawer extends StatelessWidget {
  final List<DrawerItem> items;

  const CustomDrawer({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildHeader(context),
          ...items.map(
            (item) => ListTile(
              leading: Icon(item.icon),
              title: Text(item.label),
              onTap: () {
                Navigator.pop(context); // close the drawer first
                item.onTap();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Consumer<UserProfileProvider>(
      builder: (context, profileProvider, _) {
        final profile = profileProvider.profile;
        return DrawerHeader(
          decoration: const BoxDecoration(color: Colors.deepPurple),
          child:
              profile == null
                  ? const Text(
                    "JazzX",
                    style: TextStyle(color: Colors.white, fontSize: 24),
                  )
                  : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.account_circle,
                        size: 48,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        profile.preferences.name,
                        style: const TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        // Show all user's instruments as a comma-separated string
                        profile.preferences.instruments.join(', '),
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
        );
      },
    );
  }
}
