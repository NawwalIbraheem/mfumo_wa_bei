import 'package:flutter/material.dart';

import '../../core/network/api_service.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({
    super.key,
    required this.permissions,
    required this.token,
  });

  final Set<String> permissions;
  final String token;

  @override
  Widget build(BuildContext context) {
    final items = <_AdminModule>[
      if (permissions.contains('users.list'))
        const _AdminModule(
          icon: Icons.group_outlined,
          title: 'Users',
          subtitle: 'Manage system users',
          endpoint: '/users',
          protected: true,
          primaryField: 'email',
          secondaryFields: ['username', 'profile.role', 'is_active'],
        ),
      if (permissions.contains('roles.list'))
        const _AdminModule(
          icon: Icons.badge_outlined,
          title: 'Roles',
          subtitle: 'Manage user roles',
          endpoint: '/users/roles',
          protected: true,
          primaryField: 'name',
          secondaryFields: ['code', 'permissions.length'],
        ),
      if (permissions.contains('permissions.list'))
        const _AdminModule(
          icon: Icons.key_outlined,
          title: 'Permissions',
          subtitle: 'Review access permissions',
          endpoint: '/users/permissions',
          protected: true,
          primaryField: 'name',
          secondaryFields: ['code', 'description'],
        ),
      if (_hasAny([
        'areas.create',
        'areas.bulk_import',
        'areas.update',
        'areas.delete',
      ]))
        const _AdminModule(
          icon: Icons.map_outlined,
          title: 'Areas',
          subtitle: 'Manage service areas',
          endpoint: '/areas',
          protected: false,
          primaryField: 'name',
          secondaryFields: ['level', 'parent.name'],
        ),
      if (_hasAny(['markets.create', 'markets.update', 'markets.delete']))
        const _AdminModule(
          icon: Icons.storefront_outlined,
          title: 'Markets',
          subtitle: 'Manage market records',
          endpoint: '/markets',
          protected: false,
          primaryField: 'name',
          secondaryFields: ['admin_area.name', 'status'],
        ),
      if (_hasAny([
        'commodities.create',
        'commodities.update',
        'commodities.delete',
      ]))
        const _AdminModule(
          icon: Icons.inventory_2_outlined,
          title: 'Commodities',
          subtitle: 'Manage rice and bean commodities',
          endpoint: '/commodities',
          protected: false,
          primaryField: 'name',
          secondaryFields: ['unit', 'categories.length'],
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
        if (items.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: Text('Huna ruhusa za admin.')),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, index) =>
                    _AdminItem(module: items[index], token: token),
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

  bool _hasAny(List<String> codes) {
    return codes.any(permissions.contains);
  }
}

class _AdminModule {
  const _AdminModule({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.endpoint,
    required this.protected,
    required this.primaryField,
    required this.secondaryFields,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String endpoint;
  final bool protected;
  final String primaryField;
  final List<String> secondaryFields;
}

class _AdminItem extends StatelessWidget {
  const _AdminItem({required this.module, required this.token});

  final _AdminModule module;
  final String token;

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
              builder: (_) => _AdminModuleScreen(module: module, token: token),
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

class _AdminModuleScreen extends StatefulWidget {
  const _AdminModuleScreen({required this.module, required this.token});

  final _AdminModule module;
  final String token;

  @override
  State<_AdminModuleScreen> createState() => _AdminModuleScreenState();
}

class _AdminModuleScreenState extends State<_AdminModuleScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() {
    if (widget.module.protected) {
      return _apiService.protectedList(
        token: widget.token,
        path: widget.module.endpoint,
      );
    }
    return _apiService.publicList(widget.module.endpoint);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.module.title)),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ErrorState(
              message: snapshot.error.toString(),
              onRetry: () => setState(() => _future = _load()),
            );
          }

          final rows = snapshot.data ?? const <Map<String, dynamic>>[];
          if (rows.isEmpty) {
            return const Center(child: Text('Hakuna taarifa kwa sasa.'));
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() => _future = _load());
              await _future;
            },
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
              itemCount: rows.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final row = rows[index];
                return _RecordTile(module: widget.module, row: row);
              },
            ),
          );
        },
      ),
    );
  }
}

class _RecordTile extends StatelessWidget {
  const _RecordTile({required this.module, required this.row});

  final _AdminModule module;
  final Map<String, dynamic> row;

  @override
  Widget build(BuildContext context) {
    final secondary = module.secondaryFields
        .map((field) => _readValue(row, field))
        .where((value) => value.isNotEmpty)
        .join(' • ');

    return ListTile(
      tileColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      leading: CircleAvatar(
        backgroundColor: const Color(0xFFE8F5E9),
        child: Icon(module.icon, color: const Color(0xFF0E7A3B)),
      ),
      title: Text(
        _readValue(row, module.primaryField, fallback: module.title),
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: secondary.isEmpty ? null : Text(secondary),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Jaribu tena'),
            ),
          ],
        ),
      ),
    );
  }
}

String _readValue(
  Map<String, dynamic> source,
  String path, {
  String fallback = '',
}) {
  dynamic value = source;
  for (final segment in path.split('.')) {
    if (segment == 'length') {
      if (value is List) {
        value = value.length;
      } else {
        return fallback;
      }
    } else if (value is Map<String, dynamic>) {
      value = value[segment];
    } else {
      return fallback;
    }
  }

  if (value == null) {
    return fallback;
  }
  if (value is bool) {
    return value ? 'active' : 'inactive';
  }
  final text = value.toString().trim();
  return text.isEmpty ? fallback : text;
}
