import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool priceAlertsEnabled = true;
  bool weeklySummaryEnabled = true;
  bool useSwahili = true;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
      children: [
        const Text(
          'Mipangilio',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 16),
        _SettingsSwitch(
          icon: Icons.notifications_active_outlined,
          title: 'Arifa za bei',
          subtitle: 'Pokea taarifa bei zinapobadilika sokoni.',
          value: priceAlertsEnabled,
          onChanged: (value) => setState(() => priceAlertsEnabled = value),
        ),
        const SizedBox(height: 10),
        _SettingsSwitch(
          icon: Icons.summarize_outlined,
          title: 'Muhtasari wa wiki',
          subtitle: 'Pokea muhtasari wa mwenendo wa bei kila wiki.',
          value: weeklySummaryEnabled,
          onChanged: (value) => setState(() => weeklySummaryEnabled = value),
        ),
        const SizedBox(height: 10),
        _SettingsSwitch(
          icon: Icons.language_outlined,
          title: 'Kiswahili',
          subtitle: 'Tumia Kiswahili kama lugha kuu ya mfumo.',
          value: useSwahili,
          onChanged: (value) => setState(() => useSwahili = value),
        ),
        const SizedBox(height: 18),
        const _SettingsInfoTile(
          icon: Icons.cloud_outlined,
          title: 'Chanzo cha data',
          value: 'API ya Mfumo wa Bei',
        ),
        const SizedBox(height: 10),
        const _SettingsInfoTile(
          icon: Icons.info_outline,
          title: 'Toleo',
          value: '1.0.0',
        ),
      ],
    );
  }
}

class _SettingsSwitch extends StatelessWidget {
  const _SettingsSwitch({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      tileColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      secondary: Icon(icon, color: const Color(0xFF0E7A3B)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(subtitle),
    );
  }
}

class _SettingsInfoTile extends StatelessWidget {
  const _SettingsInfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      tileColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      leading: Icon(icon, color: const Color(0xFF0E7A3B)),
      title: Text(title),
      trailing: Text(
        value,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}
