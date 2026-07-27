import 'package:flutter/material.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({
    super.key,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.role,
    required this.onLogout,
  });

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
        Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: const Color(0xFF0E7A3B),
              child: Text(
                _initials(name),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(role.toUpperCase()),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        _AccountTile(
          icon: Icons.email_outlined,
          label: 'Barua pepe',
          value: email,
        ),
        const SizedBox(height: 10),
        _AccountTile(
          icon: Icons.phone_outlined,
          label: 'Namba ya simu',
          value: phoneNumber,
        ),
        const SizedBox(height: 22),
        FilledButton.icon(
          onPressed: onLogout,
          icon: const Icon(Icons.logout),
          label: const Text('Ondoka'),
        ),
      ],
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts
        .take(2)
        .map((part) => part.isEmpty ? '' : part[0])
        .join()
        .toUpperCase();
  }
}

class _AccountTile extends StatelessWidget {
  const _AccountTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      tileColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      leading: Icon(icon, color: const Color(0xFF0E7A3B)),
      title: Text(label),
      subtitle: Text(value),
    );
  }
}
