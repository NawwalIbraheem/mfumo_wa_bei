import 'package:flutter/material.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key, required this.permissions});

  final Set<String> permissions;

  @override
  Widget build(BuildContext context) {
    final items = <_AdminItem>[
      if (permissions.contains('users.list'))
        const _AdminItem(icon: Icons.group_outlined, label: 'Users'),
      if (permissions.contains('roles.list'))
        const _AdminItem(icon: Icons.badge_outlined, label: 'Roles'),
      if (permissions.contains('permissions.list'))
        const _AdminItem(icon: Icons.key_outlined, label: 'Permissions'),
      if (permissions.contains('areas.list'))
        const _AdminItem(icon: Icons.map_outlined, label: 'Areas'),
      if (permissions.contains('markets.list'))
        const _AdminItem(icon: Icons.storefront_outlined, label: 'Markets'),
      if (permissions.contains('commodities.list'))
        const _AdminItem(
          icon: Icons.inventory_2_outlined,
          label: 'Commodities',
        ),
    ];

    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
            child: Text(
              'Admin',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (context, index) => items[index],
              childCount: items.length,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}

class _AdminItem extends StatelessWidget {
  const _AdminItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF0E7A3B)),
          const Spacer(),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
