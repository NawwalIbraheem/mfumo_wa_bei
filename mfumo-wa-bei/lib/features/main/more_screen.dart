import 'package:flutter/material.dart';

import '../../features/main/help_screen.dart';
import '../../features/main/settings_screen.dart';
import '../../features/users/account_screen.dart';

class MoreNavigationItem {
  const MoreNavigationItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.builder,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final WidgetBuilder builder;
}

class MoreScreen extends StatelessWidget {
  const MoreScreen({
    super.key,
    required this.extraItems,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.role,
    required this.onLogout,
  });

  final List<MoreNavigationItem> extraItems;
  final String name;
  final String email;
  final String phoneNumber;
  final String role;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 96),
      children: [
        const Text(
          'Zaidi',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 16),
        for (final item in extraItems) ...[
          _MoreTile(
            icon: item.icon,
            title: item.title,
            subtitle: item.subtitle,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => Scaffold(
                    appBar: AppBar(title: Text(item.title)),
                    body: item.builder(context),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
        ],
        _MoreTile(
          icon: Icons.person_outline,
          title: 'Akaunti',
          subtitle: 'Wasifu, mawasiliano na kutoka kwenye akaunti',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => Scaffold(
                  appBar: AppBar(title: const Text('Akaunti')),
                  body: AccountScreen(
                    name: name,
                    email: email,
                    phoneNumber: phoneNumber,
                    role: role,
                    onLogout: onLogout,
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        _MoreTile(
          icon: Icons.settings_outlined,
          title: 'Mipangilio',
          subtitle: 'Mapendeleo ya mfumo',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => Scaffold(
                  appBar: AppBar(title: const Text('Mipangilio')),
                  body: const SettingsScreen(),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        _MoreTile(
          icon: Icons.help_outline,
          title: 'Msaada',
          subtitle: 'Maswali na maelekezo ya kutumia mfumo',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => Scaffold(
                  appBar: AppBar(title: const Text('Msaada')),
                  body: const HelpScreen(),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _MoreTile extends StatelessWidget {
  const _MoreTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      tileColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      leading: CircleAvatar(
        backgroundColor: const Color(0xFFE8F5E9),
        child: Icon(icon, color: const Color(0xFF0E7A3B)),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(subtitle),
      trailing: onTap == null ? null : const Icon(Icons.chevron_right),
    );
  }
}
