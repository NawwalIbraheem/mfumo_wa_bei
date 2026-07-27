import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 96),
      children: const [
        Text(
          'Arifa',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
        SizedBox(height: 12),
        _NotificationTile(
          icon: Icons.trending_up,
          title: 'Bei ya maharage imepanda',
          subtitle: 'Soko la Sabasaba limeongezeka kwa 4.1%.',
        ),
        SizedBox(height: 10),
        _NotificationTile(
          icon: Icons.storefront_outlined,
          title: 'Soko jipya limeongezwa',
          subtitle: 'Soko la Mazimbu sasa linaonekana kwenye mfumo.',
        ),
      ],
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      tileColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      leading: CircleAvatar(
        backgroundColor: const Color(0xFFE8F5E9),
        child: Icon(icon, color: const Color(0xFF0E7A3B)),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(subtitle),
    );
  }
}
