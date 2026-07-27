import 'package:flutter/material.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key, required this.permissions});

  final Set<String> permissions;

  @override
  Widget build(BuildContext context) {
    final items = <_AdminModule>[
      if (permissions.contains('users.list'))
        const _AdminModule(
          icon: Icons.group_outlined,
          title: 'Users',
          subtitle: 'Manage system users',
        ),
      if (permissions.contains('roles.list'))
        const _AdminModule(
          icon: Icons.badge_outlined,
          title: 'Roles',
          subtitle: 'Manage user roles',
        ),
      if (permissions.contains('permissions.list'))
        const _AdminModule(
          icon: Icons.key_outlined,
          title: 'Permissions',
          subtitle: 'Review access permissions',
        ),
      if (permissions.contains('areas.list'))
        const _AdminModule(
          icon: Icons.map_outlined,
          title: 'Areas',
          subtitle: 'Manage service areas',
        ),
      if (permissions.contains('markets.list'))
        const _AdminModule(
          icon: Icons.storefront_outlined,
          title: 'Markets',
          subtitle: 'Manage market records',
        ),
      if (permissions.contains('commodities.list'))
        const _AdminModule(
          icon: Icons.inventory_2_outlined,
          title: 'Commodities',
          subtitle: 'Manage rice and bean commodities',
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
              (context, index) => _AdminItem(module: items[index]),
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

class _AdminModule {
  const _AdminModule({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;
}

class _AdminItem extends StatelessWidget {
  const _AdminItem({required this.module});

  final _AdminModule module;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => _AdminModuleScreen(module: module),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(module.icon, color: const Color(0xFF0E7A3B)),
              const Spacer(),
              Text(
                module.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                module.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminModuleScreen extends StatelessWidget {
  const _AdminModuleScreen({required this.module});

  final _AdminModule module;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(module.title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
        children: [
          Icon(module.icon, size: 44, color: const Color(0xFF0E7A3B)),
          const SizedBox(height: 14),
          Text(
            module.title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            module.subtitle,
            style: const TextStyle(color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 20),
          ListTile(
            tileColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            leading: const Icon(Icons.info_outline, color: Color(0xFF0E7A3B)),
            title: const Text(
              'API connection pending',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: const Text(
              'This section is ready for list, create, edit and delete actions once the admin endpoints are connected.',
            ),
          ),
        ],
      ),
    );
  }
}
