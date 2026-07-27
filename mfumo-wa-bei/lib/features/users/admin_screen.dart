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
          type: _AdminModuleType.users,
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
          type: _AdminModuleType.roles,
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
          type: _AdminModuleType.permissions,
        ),
      if (_hasAny([
        'commodities.categories.create',
        'commodities.categories.update',
        'commodities.categories.delete',
      ]))
        const _AdminModule(
          icon: Icons.category_outlined,
          title: 'Categories',
          subtitle: 'Manage commodity categories',
          endpoint: '/commodities/categories',
          protected: false,
          primaryField: 'name',
          secondaryFields: ['description'],
          type: _AdminModuleType.categories,
        ),
      if (_hasAny([
        'commodities.units.create',
        'commodities.units.update',
        'commodities.units.delete',
      ]))
        const _AdminModule(
          icon: Icons.straighten_outlined,
          title: 'Units',
          subtitle: 'Manage commodity units',
          endpoint: '/commodities/units',
          protected: false,
          primaryField: 'name',
          secondaryFields: ['symbol', 'description'],
          type: _AdminModuleType.units,
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
          type: _AdminModuleType.areas,
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
          type: _AdminModuleType.markets,
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
          type: _AdminModuleType.commodities,
        ),
      if (_hasAny(['listings.create', 'listings.update', 'listings.delete']))
        const _AdminModule(
          icon: Icons.assignment_outlined,
          title: 'Listings',
          subtitle: 'Manage commodity listings',
          endpoint: '/listings',
          protected: false,
          primaryField: 'title',
          secondaryFields: ['commodity.name', 'adm_area.name', 'status'],
          type: _AdminModuleType.listings,
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
    this.type = _AdminModuleType.generic,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String endpoint;
  final bool protected;
  final String primaryField;
  final List<String> secondaryFields;
  final _AdminModuleType type;
}

enum _AdminModuleType {
  generic,
  users,
  roles,
  permissions,
  categories,
  units,
  areas,
  markets,
  commodities,
  listings,
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
              builder: (_) => _AdminModuleScreen(
                module: module,
                token: token,
                permissions: _permissionsOf(context),
              ),
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

Set<String> _permissionsOf(BuildContext context) {
  final screen = context.findAncestorWidgetOfExactType<AdminScreen>();
  return screen?.permissions ?? const <String>{};
}

class _AdminModuleScreen extends StatefulWidget {
  const _AdminModuleScreen({
    required this.module,
    required this.token,
    required this.permissions,
  });

  final _AdminModule module;
  final String token;
  final Set<String> permissions;

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
      floatingActionButton: _buildFab(),
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
                return _RecordTile(
                  module: widget.module,
                  row: row,
                  onTap:
                      widget.module.type == _AdminModuleType.users &&
                          widget.permissions.contains('users.read')
                      ? () => _openUserDetail(row)
                      : widget.module.type == _AdminModuleType.roles &&
                            widget.permissions.contains('roles.read')
                      ? () => _openRoleDetail(row)
                      : widget.module.type == _AdminModuleType.permissions &&
                            widget.permissions.contains('permissions.read')
                      ? () => _openPermissionDetail(row)
                      : widget.module.type == _AdminModuleType.categories
                      ? () => _openCategoryDetail(row)
                      : widget.module.type == _AdminModuleType.units
                      ? () => _openUnitDetail(row)
                      : widget.module.type == _AdminModuleType.areas
                      ? () => _openAreaDetail(row)
                      : widget.module.type == _AdminModuleType.markets
                      ? () => _openMarketDetail(row)
                      : widget.module.type == _AdminModuleType.commodities
                      ? () => _openCommodityDetail(row)
                      : widget.module.type == _AdminModuleType.listings
                      ? () => _openListingDetail(row)
                      : null,
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget? _buildFab() {
    if (widget.module.type == _AdminModuleType.users &&
        widget.permissions.contains('users.create')) {
      return FloatingActionButton.extended(
        onPressed: _showCreateUser,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('User'),
      );
    }
    if (widget.module.type == _AdminModuleType.roles &&
        widget.permissions.contains('roles.create')) {
      return FloatingActionButton.extended(
        onPressed: _showCreateRole,
        icon: const Icon(Icons.add_moderator_outlined),
        label: const Text('Role'),
      );
    }
    if (widget.module.type == _AdminModuleType.categories &&
        widget.permissions.contains('commodities.categories.create')) {
      return FloatingActionButton.extended(
        onPressed: _showCreateCategory,
        icon: const Icon(Icons.add_outlined),
        label: const Text('Category'),
      );
    }
    if (widget.module.type == _AdminModuleType.units &&
        widget.permissions.contains('commodities.units.create')) {
      return FloatingActionButton.extended(
        onPressed: _showCreateUnit,
        icon: const Icon(Icons.add_outlined),
        label: const Text('Unit'),
      );
    }
    if (widget.module.type == _AdminModuleType.commodities &&
        widget.permissions.contains('commodities.create')) {
      return FloatingActionButton.extended(
        onPressed: _showCreateCommodity,
        icon: const Icon(Icons.add_outlined),
        label: const Text('Commodity'),
      );
    }
    if (widget.module.type == _AdminModuleType.markets &&
        widget.permissions.contains('markets.create')) {
      return FloatingActionButton.extended(
        onPressed: _showCreateMarket,
        icon: const Icon(Icons.add_outlined),
        label: const Text('Market'),
      );
    }
    if (widget.module.type == _AdminModuleType.areas &&
        (widget.permissions.contains('areas.create') ||
            widget.permissions.contains('areas.bulk_import'))) {
      return FloatingActionButton.extended(
        onPressed: _showAreaActions,
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text('Area'),
      );
    }
    if (widget.module.type == _AdminModuleType.listings &&
        widget.permissions.contains('listings.create')) {
      return FloatingActionButton.extended(
        onPressed: _showCreateListing,
        icon: const Icon(Icons.add_outlined),
        label: const Text('Listing'),
      );
    }
    return null;
  }

  Future<void> _openUserDetail(Map<String, dynamic> row) async {
    final userId = row['user_id']?.toString();
    if (userId == null || userId.isEmpty) {
      return;
    }
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => _UserDetailScreen(
          token: widget.token,
          userId: userId,
          permissions: widget.permissions,
        ),
      ),
    );
    if (changed == true && mounted) {
      setState(() => _future = _load());
    }
  }

  Future<void> _showCreateUser() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _UserFormSheet(
        token: widget.token,
        onSubmit: (body) => _apiService.protectedCreate(
          token: widget.token,
          path: '/users',
          body: body,
        ),
      ),
    );
    if (created == true && mounted) {
      setState(() => _future = _load());
    }
  }

  Future<void> _openRoleDetail(Map<String, dynamic> row) async {
    final roleId = row['role_id']?.toString() ?? row['code']?.toString();
    if (roleId == null || roleId.isEmpty) {
      return;
    }
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => _RoleDetailScreen(
          token: widget.token,
          roleId: roleId,
          permissions: widget.permissions,
        ),
      ),
    );
    if (changed == true && mounted) {
      setState(() => _future = _load());
    }
  }

  Future<void> _openPermissionDetail(Map<String, dynamic> row) async {
    final permissionId = row['permission_id']?.toString();
    if (permissionId == null || permissionId.isEmpty) {
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _PermissionDetailScreen(
          token: widget.token,
          permissionId: permissionId,
        ),
      ),
    );
  }

  Future<void> _showCreateRole() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _RoleFormSheet(
        onSubmit: (body) => _apiService.protectedCreate(
          token: widget.token,
          path: '/users/roles',
          body: body,
        ),
      ),
    );
    if (created == true && mounted) {
      setState(() => _future = _load());
    }
  }

  Future<void> _openCategoryDetail(Map<String, dynamic> row) async {
    final categoryId = row['category_id']?.toString();
    if (categoryId == null || categoryId.isEmpty) {
      return;
    }
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => _CategoryDetailScreen(
          token: widget.token,
          categoryId: categoryId,
          permissions: widget.permissions,
        ),
      ),
    );
    if (changed == true && mounted) {
      setState(() => _future = _load());
    }
  }

  Future<void> _showCreateCategory() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _CategoryFormSheet(
        onSubmit: (body) => _apiService.protectedCreate(
          token: widget.token,
          path: '/commodities/categories',
          body: body,
        ),
      ),
    );
    if (created == true && mounted) {
      setState(() => _future = _load());
    }
  }

  Future<void> _openUnitDetail(Map<String, dynamic> row) async {
    final unitId = row['unit_id']?.toString();
    if (unitId == null || unitId.isEmpty) {
      return;
    }
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => _UnitDetailScreen(
          token: widget.token,
          unitId: unitId,
          permissions: widget.permissions,
        ),
      ),
    );
    if (changed == true && mounted) {
      setState(() => _future = _load());
    }
  }

  Future<void> _showCreateUnit() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _UnitFormSheet(
        onSubmit: (body) => _apiService.protectedCreate(
          token: widget.token,
          path: '/commodities/units',
          body: body,
        ),
      ),
    );
    if (created == true && mounted) {
      setState(() => _future = _load());
    }
  }

  Future<void> _openAreaDetail(Map<String, dynamic> row) async {
    final areaId = row['area_id']?.toString();
    if (areaId == null || areaId.isEmpty) {
      return;
    }
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => _AreaDetailScreen(
          token: widget.token,
          areaId: areaId,
          permissions: widget.permissions,
        ),
      ),
    );
    if (changed == true && mounted) {
      setState(() => _future = _load());
    }
  }

  Future<void> _showAreaActions() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.permissions.contains('areas.create'))
              ListTile(
                leading: const Icon(Icons.add_location_alt_outlined),
                title: const Text('Create area'),
                onTap: () => Navigator.pop(context, 'create'),
              ),
            if (widget.permissions.contains('areas.bulk_import'))
              ListTile(
                leading: const Icon(Icons.playlist_add_outlined),
                title: const Text('Bulk import area path'),
                onTap: () => Navigator.pop(context, 'bulk'),
              ),
          ],
        ),
      ),
    );
    if (action == 'create') {
      await _showCreateArea();
    } else if (action == 'bulk') {
      await _showBulkImportArea();
    }
  }

  Future<void> _showCreateArea() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _AreaFormSheet(
        token: widget.token,
        onSubmit: (body) => _apiService.protectedCreate(
          token: widget.token,
          path: '/areas',
          body: body,
        ),
      ),
    );
    if (created == true && mounted) {
      setState(() => _future = _load());
    }
  }

  Future<void> _showBulkImportArea() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _AreaBulkImportSheet(
        onSubmit: (body) => _apiService.protectedCreate(
          token: widget.token,
          path: '/areas/bulk',
          body: body,
        ),
      ),
    );
    if (created == true && mounted) {
      setState(() => _future = _load());
    }
  }

  Future<void> _openMarketDetail(Map<String, dynamic> row) async {
    final marketId = row['market_id']?.toString();
    if (marketId == null || marketId.isEmpty) {
      return;
    }
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => _MarketDetailScreen(
          token: widget.token,
          marketId: marketId,
          permissions: widget.permissions,
        ),
      ),
    );
    if (changed == true && mounted) {
      setState(() => _future = _load());
    }
  }

  Future<void> _showCreateMarket() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _MarketFormSheet(
        token: widget.token,
        onSubmit: (body) => _apiService.protectedCreate(
          token: widget.token,
          path: '/markets',
          body: body,
        ),
      ),
    );
    if (created == true && mounted) {
      setState(() => _future = _load());
    }
  }

  Future<void> _openCommodityDetail(Map<String, dynamic> row) async {
    final commodityId = row['commodity_id']?.toString();
    if (commodityId == null || commodityId.isEmpty) {
      return;
    }
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => _CommodityDetailScreen(
          token: widget.token,
          commodityId: commodityId,
          permissions: widget.permissions,
        ),
      ),
    );
    if (changed == true && mounted) {
      setState(() => _future = _load());
    }
  }

  Future<void> _showCreateCommodity() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _CommodityFormSheet(
        token: widget.token,
        onSubmit: (body) => _apiService.protectedCreate(
          token: widget.token,
          path: '/commodities',
          body: body,
        ),
      ),
    );
    if (created == true && mounted) {
      setState(() => _future = _load());
    }
  }

  Future<void> _openListingDetail(Map<String, dynamic> row) async {
    final listingId = row['listing_id']?.toString();
    if (listingId == null || listingId.isEmpty) {
      return;
    }
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => _ListingDetailScreen(
          token: widget.token,
          listingId: listingId,
          permissions: widget.permissions,
        ),
      ),
    );
    if (changed == true && mounted) {
      setState(() => _future = _load());
    }
  }

  Future<void> _showCreateListing() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _ListingFormSheet(
        token: widget.token,
        onSubmit: (body) => _apiService.protectedCreate(
          token: widget.token,
          path: '/listings',
          body: body,
        ),
      ),
    );
    if (created == true && mounted) {
      setState(() => _future = _load());
    }
  }
}

class _RecordTile extends StatelessWidget {
  const _RecordTile({required this.module, required this.row, this.onTap});

  final _AdminModule module;
  final Map<String, dynamic> row;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final secondary = module.secondaryFields
        .map((field) => _readValue(row, field))
        .where((value) => value.isNotEmpty)
        .join(' • ');

    return ListTile(
      onTap: onTap,
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
      trailing: onTap == null ? null : const Icon(Icons.chevron_right),
    );
  }
}

class _UserDetailScreen extends StatefulWidget {
  const _UserDetailScreen({
    required this.token,
    required this.userId,
    required this.permissions,
  });

  final String token;
  final String userId;
  final Set<String> permissions;

  @override
  State<_UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<_UserDetailScreen> {
  final ApiService _apiService = ApiService();
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Map<String, dynamic>> _load() {
    return _apiService.protectedDetail(
      token: widget.token,
      path: '/users/${widget.userId}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User')),
      body: FutureBuilder<Map<String, dynamic>>(
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
          final user = snapshot.data ?? const <String, dynamic>{};
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
            children: [
              _UserHeader(user: user),
              const SizedBox(height: 16),
              _InfoTile(label: 'Username', value: _readValue(user, 'username')),
              _InfoTile(label: 'Email', value: _readValue(user, 'email')),
              _InfoTile(
                label: 'First name',
                value: _readValue(user, 'first_name', fallback: '-'),
              ),
              _InfoTile(
                label: 'Last name',
                value: _readValue(user, 'last_name', fallback: '-'),
              ),
              _InfoTile(label: 'Role', value: _readValue(user, 'profile.role')),
              _InfoTile(
                label: 'Phone',
                value: _readValue(user, 'profile.phone_number', fallback: '-'),
              ),
              _InfoTile(label: 'Active', value: _readValue(user, 'is_active')),
              const SizedBox(height: 20),
              if (widget.permissions.contains('users.update'))
                FilledButton.icon(
                  onPressed: () => _edit(user),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit user'),
                ),
              if (widget.permissions.contains('users.delete')) ...[
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _delete,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete user'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _edit(Map<String, dynamic> user) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _UserFormSheet(
        token: widget.token,
        user: user,
        onSubmit: (body) => _apiService.protectedUpdate(
          token: widget.token,
          path: '/users/${widget.userId}',
          body: body,
        ),
      ),
    );
    if (changed == true && mounted) {
      setState(() => _future = _load());
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete user?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    try {
      await _apiService.protectedDelete(
        token: widget.token,
        path: '/users/${widget.userId}',
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }
}

class _UserHeader extends StatelessWidget {
  const _UserHeader({required this.user});

  final Map<String, dynamic> user;

  @override
  Widget build(BuildContext context) {
    final name = [
      _readValue(user, 'first_name'),
      _readValue(user, 'last_name'),
    ].where((part) => part.isNotEmpty).join(' ');
    final email = _readValue(user, 'email', fallback: 'User');
    return ListTile(
      tileColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      leading: const CircleAvatar(
        backgroundColor: Color(0xFFE8F5E9),
        child: Icon(Icons.person_outline, color: Color(0xFF0E7A3B)),
      ),
      title: Text(
        name.isEmpty ? email : name,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: Text(email),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      tileColor: Colors.white,
      title: Text(label),
      subtitle: Text(value.isEmpty ? '-' : value),
    );
  }
}

class _RoleDetailScreen extends StatefulWidget {
  const _RoleDetailScreen({
    required this.token,
    required this.roleId,
    required this.permissions,
  });

  final String token;
  final String roleId;
  final Set<String> permissions;

  @override
  State<_RoleDetailScreen> createState() => _RoleDetailScreenState();
}

class _RoleDetailScreenState extends State<_RoleDetailScreen> {
  final ApiService _apiService = ApiService();
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Map<String, dynamic>> _load() {
    return _apiService.protectedDetail(
      token: widget.token,
      path: '/users/roles/${widget.roleId}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Role')),
      body: FutureBuilder<Map<String, dynamic>>(
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
          final role = snapshot.data ?? const <String, dynamic>{};
          final assigned = role['permissions'] is List
              ? role['permissions'] as List
              : const [];
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
            children: [
              _InfoTile(label: 'Name', value: _readValue(role, 'name')),
              _InfoTile(label: 'Code', value: _readValue(role, 'code')),
              _InfoTile(
                label: 'Description',
                value: _readValue(role, 'description', fallback: '-'),
              ),
              _InfoTile(
                label: 'System role',
                value: _readValue(role, 'is_system'),
              ),
              const SizedBox(height: 16),
              const Text(
                'Permissions',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              const SizedBox(height: 8),
              for (final permission
                  in assigned.whereType<Map<String, dynamic>>())
                _InfoTile(
                  label: permission['code']?.toString() ?? 'Permission',
                  value: permission['name']?.toString() ?? '',
                ),
              const SizedBox(height: 20),
              if (widget.permissions.contains('roles.update'))
                FilledButton.icon(
                  onPressed: () => _edit(role),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit role'),
                ),
              if (widget.permissions.contains('roles.permissions.update')) ...[
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: () => _editPermissions(role),
                  icon: const Icon(Icons.key_outlined),
                  label: const Text('Update permissions'),
                ),
              ],
              if (widget.permissions.contains('roles.delete')) ...[
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _delete,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete role'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _edit(Map<String, dynamic> role) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _RoleFormSheet(
        role: role,
        onSubmit: (body) => _apiService.protectedReplace(
          token: widget.token,
          path: '/users/roles/${widget.roleId}',
          body: body,
        ),
      ),
    );
    if (changed == true && mounted) {
      setState(() => _future = _load());
    }
  }

  Future<void> _editPermissions(Map<String, dynamic> role) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _RolePermissionsSheet(
        token: widget.token,
        role: role,
        roleId: widget.roleId,
      ),
    );
    if (changed == true && mounted) {
      setState(() => _future = _load());
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete role?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    try {
      await _apiService.protectedDelete(
        token: widget.token,
        path: '/users/roles/${widget.roleId}',
      );
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }
}

class _RoleFormSheet extends StatefulWidget {
  const _RoleFormSheet({required this.onSubmit, this.role});

  final Map<String, dynamic>? role;
  final Future<Map<String, dynamic>> Function(Map<String, dynamic> body)
  onSubmit;

  @override
  State<_RoleFormSheet> createState() => _RoleFormSheetState();
}

class _RoleFormSheetState extends State<_RoleFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codeController;
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final role = widget.role ?? const <String, dynamic>{};
    _codeController = TextEditingController(text: _readValue(role, 'code'));
    _nameController = TextEditingController(text: _readValue(role, 'name'));
    _descriptionController = TextEditingController(
      text: _readValue(role, 'description'),
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        8,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.role == null ? 'Create role' : 'Edit role',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            _sheetField(_codeController, 'Code', enabled: !_isSubmitting),
            _sheetField(_nameController, 'Name', enabled: !_isSubmitting),
            _sheetField(
              _descriptionController,
              'Description',
              enabled: !_isSubmitting,
              required: false,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: _isSubmitting ? null : _submit,
                child: Text(_isSubmitting ? 'Saving...' : 'Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await widget.onSubmit({
        'code': _codeController.text.trim(),
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
      });
      if (mounted) {
        Navigator.pop(context, true);
      }
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }
}

class _RolePermissionsSheet extends StatefulWidget {
  const _RolePermissionsSheet({
    required this.token,
    required this.role,
    required this.roleId,
  });

  final String token;
  final Map<String, dynamic> role;
  final String roleId;

  @override
  State<_RolePermissionsSheet> createState() => _RolePermissionsSheetState();
}

class _RolePermissionsSheetState extends State<_RolePermissionsSheet> {
  final ApiService _apiService = ApiService();
  late Future<List<Map<String, dynamic>>> _future;
  late final Set<String> _selectedIds;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _future = _apiService.protectedList(
      token: widget.token,
      path: '/users/permissions',
    );
    final ids = widget.role['permission_ids'];
    _selectedIds = ids is List
        ? ids.map((id) => id.toString()).toSet()
        : <String>{};
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.85,
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ErrorState(
              message: snapshot.error.toString(),
              onRetry: () => setState(() {
                _future = _apiService.protectedList(
                  token: widget.token,
                  path: '/users/permissions',
                );
              }),
            );
          }
          final permissions = snapshot.data ?? const <Map<String, dynamic>>[];
          return Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Role permissions',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: permissions.length,
                  itemBuilder: (context, index) {
                    final permission = permissions[index];
                    final id = permission['permission_id']?.toString() ?? '';
                    return CheckboxListTile(
                      value: _selectedIds.contains(id),
                      onChanged: _isSubmitting
                          ? null
                          : (value) => setState(() {
                              if (value == true) {
                                _selectedIds.add(id);
                              } else {
                                _selectedIds.remove(id);
                              }
                            }),
                      title: Text(permission['name']?.toString() ?? id),
                      subtitle: Text(permission['code']?.toString() ?? ''),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: _isSubmitting ? null : _submit,
                    child: Text(_isSubmitting ? 'Saving...' : 'Save'),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    try {
      await _apiService.protectedUpdate(
        token: widget.token,
        path: '/users/roles/${widget.roleId}',
        body: {'permission_ids': _selectedIds.toList()},
      );
      if (mounted) {
        Navigator.pop(context, true);
      }
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }
}

class _PermissionDetailScreen extends StatefulWidget {
  const _PermissionDetailScreen({
    required this.token,
    required this.permissionId,
  });

  final String token;
  final String permissionId;

  @override
  State<_PermissionDetailScreen> createState() =>
      _PermissionDetailScreenState();
}

class _PermissionDetailScreenState extends State<_PermissionDetailScreen> {
  final ApiService _apiService = ApiService();
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _apiService.protectedDetail(
      token: widget.token,
      path: '/users/permissions/${widget.permissionId}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Permission')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ErrorState(
              message: snapshot.error.toString(),
              onRetry: () => setState(() {
                _future = _apiService.protectedDetail(
                  token: widget.token,
                  path: '/users/permissions/${widget.permissionId}',
                );
              }),
            );
          }
          final permission = snapshot.data ?? const <String, dynamic>{};
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
            children: [
              _InfoTile(label: 'Name', value: _readValue(permission, 'name')),
              _InfoTile(label: 'Code', value: _readValue(permission, 'code')),
              _InfoTile(
                label: 'Description',
                value: _readValue(permission, 'description', fallback: '-'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CategoryDetailScreen extends StatefulWidget {
  const _CategoryDetailScreen({
    required this.token,
    required this.categoryId,
    required this.permissions,
  });

  final String token;
  final String categoryId;
  final Set<String> permissions;

  @override
  State<_CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<_CategoryDetailScreen> {
  final ApiService _apiService = ApiService();
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Map<String, dynamic>> _load() {
    return _apiService.publicDetail(
      '/commodities/categories/${widget.categoryId}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Category')),
      body: FutureBuilder<Map<String, dynamic>>(
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
          final category = snapshot.data ?? const <String, dynamic>{};
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
            children: [
              _InfoTile(label: 'Name', value: _readValue(category, 'name')),
              _InfoTile(
                label: 'Description',
                value: _readValue(category, 'description', fallback: '-'),
              ),
              const SizedBox(height: 20),
              if (widget.permissions.contains('commodities.categories.update'))
                FilledButton.icon(
                  onPressed: () => _edit(category),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit category'),
                ),
              if (widget.permissions.contains(
                'commodities.categories.delete',
              )) ...[
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _delete,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete category'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _edit(Map<String, dynamic> category) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _CategoryFormSheet(
        category: category,
        onSubmit: (body) => _apiService.protectedUpdate(
          token: widget.token,
          path: '/commodities/categories/${widget.categoryId}',
          body: body,
        ),
      ),
    );
    if (changed == true && mounted) {
      setState(() => _future = _load());
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete category?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    try {
      await _apiService.protectedDelete(
        token: widget.token,
        path: '/commodities/categories/${widget.categoryId}',
      );
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }
}

class _CategoryFormSheet extends StatefulWidget {
  const _CategoryFormSheet({required this.onSubmit, this.category});

  final Map<String, dynamic>? category;
  final Future<Map<String, dynamic>> Function(Map<String, dynamic> body)
  onSubmit;

  @override
  State<_CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends State<_CategoryFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final category = widget.category ?? const <String, dynamic>{};
    _nameController = TextEditingController(text: _readValue(category, 'name'));
    _descriptionController = TextEditingController(
      text: _readValue(category, 'description'),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        8,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.category == null ? 'Create category' : 'Edit category',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            _sheetField(_nameController, 'Name', enabled: !_isSubmitting),
            _sheetField(
              _descriptionController,
              'Description',
              enabled: !_isSubmitting,
              required: false,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: _isSubmitting ? null : _submit,
                child: Text(_isSubmitting ? 'Saving...' : 'Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await widget.onSubmit({
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
      });
      if (mounted) {
        Navigator.pop(context, true);
      }
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }
}

class _UnitDetailScreen extends StatefulWidget {
  const _UnitDetailScreen({
    required this.token,
    required this.unitId,
    required this.permissions,
  });

  final String token;
  final String unitId;
  final Set<String> permissions;

  @override
  State<_UnitDetailScreen> createState() => _UnitDetailScreenState();
}

class _UnitDetailScreenState extends State<_UnitDetailScreen> {
  final ApiService _apiService = ApiService();
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Map<String, dynamic>> _load() {
    return _apiService.publicDetail('/commodities/units/${widget.unitId}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Unit')),
      body: FutureBuilder<Map<String, dynamic>>(
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
          final unit = snapshot.data ?? const <String, dynamic>{};
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
            children: [
              _InfoTile(label: 'Name', value: _readValue(unit, 'name')),
              _InfoTile(label: 'Symbol', value: _readValue(unit, 'symbol')),
              _InfoTile(
                label: 'Description',
                value: _readValue(unit, 'description', fallback: '-'),
              ),
              const SizedBox(height: 20),
              if (widget.permissions.contains('commodities.units.update'))
                FilledButton.icon(
                  onPressed: () => _edit(unit),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit unit'),
                ),
              if (widget.permissions.contains('commodities.units.delete')) ...[
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _delete,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete unit'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _edit(Map<String, dynamic> unit) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _UnitFormSheet(
        unit: unit,
        onSubmit: (body) => _apiService.protectedUpdate(
          token: widget.token,
          path: '/commodities/units/${widget.unitId}',
          body: body,
        ),
      ),
    );
    if (changed == true && mounted) {
      setState(() => _future = _load());
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete unit?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    try {
      await _apiService.protectedDelete(
        token: widget.token,
        path: '/commodities/units/${widget.unitId}',
      );
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }
}

class _UnitFormSheet extends StatefulWidget {
  const _UnitFormSheet({required this.onSubmit, this.unit});

  final Map<String, dynamic>? unit;
  final Future<Map<String, dynamic>> Function(Map<String, dynamic> body)
  onSubmit;

  @override
  State<_UnitFormSheet> createState() => _UnitFormSheetState();
}

class _UnitFormSheetState extends State<_UnitFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _symbolController;
  late final TextEditingController _descriptionController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final unit = widget.unit ?? const <String, dynamic>{};
    _nameController = TextEditingController(text: _readValue(unit, 'name'));
    _symbolController = TextEditingController(text: _readValue(unit, 'symbol'));
    _descriptionController = TextEditingController(
      text: _readValue(unit, 'description'),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _symbolController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        8,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.unit == null ? 'Create unit' : 'Edit unit',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            _sheetField(_nameController, 'Name', enabled: !_isSubmitting),
            _sheetField(_symbolController, 'Symbol', enabled: !_isSubmitting),
            _sheetField(
              _descriptionController,
              'Description',
              enabled: !_isSubmitting,
              required: false,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: _isSubmitting ? null : _submit,
                child: Text(_isSubmitting ? 'Saving...' : 'Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await widget.onSubmit({
        'name': _nameController.text.trim(),
        'symbol': _symbolController.text.trim(),
        'description': _descriptionController.text.trim(),
      });
      if (mounted) {
        Navigator.pop(context, true);
      }
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }
}

class _AreaDetailScreen extends StatefulWidget {
  const _AreaDetailScreen({
    required this.token,
    required this.areaId,
    required this.permissions,
  });

  final String token;
  final String areaId;
  final Set<String> permissions;

  @override
  State<_AreaDetailScreen> createState() => _AreaDetailScreenState();
}

class _AreaDetailScreenState extends State<_AreaDetailScreen> {
  final ApiService _apiService = ApiService();
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Map<String, dynamic>> _load() {
    return _apiService.publicDetail('/areas/${widget.areaId}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Area')),
      body: FutureBuilder<Map<String, dynamic>>(
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
          final area = snapshot.data ?? const <String, dynamic>{};
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
            children: [
              _InfoTile(label: 'Name', value: _readValue(area, 'name')),
              _InfoTile(label: 'Level', value: _readValue(area, 'level')),
              _InfoTile(
                label: 'Parent',
                value: _readValue(area, 'parent.name', fallback: '-'),
              ),
              const SizedBox(height: 20),
              if (widget.permissions.contains('areas.update'))
                FilledButton.icon(
                  onPressed: () => _edit(area),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit area'),
                ),
              if (widget.permissions.contains('areas.delete')) ...[
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _delete,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete area'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _edit(Map<String, dynamic> area) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _AreaFormSheet(
        token: widget.token,
        area: area,
        onSubmit: (body) => _apiService.protectedUpdate(
          token: widget.token,
          path: '/areas/${widget.areaId}',
          body: body,
        ),
      ),
    );
    if (changed == true && mounted) {
      setState(() => _future = _load());
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete area?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _apiService.protectedDelete(
        token: widget.token,
        path: '/areas/${widget.areaId}',
      );
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }
}

class _AreaFormSheet extends StatefulWidget {
  const _AreaFormSheet({
    required this.token,
    required this.onSubmit,
    this.area,
  });

  final String token;
  final Map<String, dynamic>? area;
  final Future<Map<String, dynamic>> Function(Map<String, dynamic> body)
  onSubmit;

  @override
  State<_AreaFormSheet> createState() => _AreaFormSheetState();
}

class _AreaFormSheetState extends State<_AreaFormSheet> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late Future<List<Map<String, dynamic>>> _areasFuture;
  String _level = 'region';
  String? _parentId;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final area = widget.area ?? const <String, dynamic>{};
    _nameController = TextEditingController(text: _readValue(area, 'name'));
    _level = _readValue(area, 'level', fallback: 'region');
    _parentId = _readValue(area, 'parent.area_id');
    if (_parentId != null && _parentId!.isEmpty) {
      _parentId = null;
    }
    _areasFuture = _apiService.publicList('/areas');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.75,
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _areasFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ErrorState(
              message: snapshot.error.toString(),
              onRetry: () => setState(() {
                _areasFuture = _apiService.publicList('/areas');
              }),
            );
          }
          final areas = snapshot.data ?? const <Map<String, dynamic>>[];
          final parentOptions = areas
              .where(
                (area) =>
                    area['area_id']?.toString() !=
                    widget.area?['area_id']?.toString(),
              )
              .toList();
          return Form(
            key: _formKey,
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                20,
                8,
                20,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              children: [
                Text(
                  widget.area == null ? 'Create area' : 'Edit area',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                _sheetField(_nameController, 'Name', enabled: !_isSubmitting),
                DropdownButtonFormField<String>(
                  initialValue: _level,
                  decoration: const InputDecoration(labelText: 'Level'),
                  items: const [
                    DropdownMenuItem(value: 'region', child: Text('region')),
                    DropdownMenuItem(
                      value: 'district',
                      child: Text('district'),
                    ),
                    DropdownMenuItem(value: 'ward', child: Text('ward')),
                  ],
                  onChanged: _isSubmitting
                      ? null
                      : (value) => setState(() {
                          _level = value ?? _level;
                          if (_level == 'region') _parentId = null;
                        }),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _parentId,
                  decoration: const InputDecoration(labelText: 'Parent'),
                  items: [
                    const DropdownMenuItem(value: '', child: Text('None')),
                    ...parentOptions.map(
                      (area) => DropdownMenuItem(
                        value: area['area_id']?.toString(),
                        child: Text(
                          '${area['name'] ?? ''} (${area['level'] ?? ''})',
                        ),
                      ),
                    ),
                  ],
                  onChanged: _isSubmitting || _level == 'region'
                      ? null
                      : (value) => setState(() {
                          _parentId = value == null || value.isEmpty
                              ? null
                              : value;
                        }),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: _isSubmitting ? null : _submit,
                    child: Text(_isSubmitting ? 'Saving...' : 'Save'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    final body = <String, dynamic>{
      'name': _nameController.text.trim(),
      'level': _level,
      'parent_id': _level == 'region' ? null : _parentId,
    };
    try {
      await widget.onSubmit(body);
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }
}

class _AreaBulkImportSheet extends StatefulWidget {
  const _AreaBulkImportSheet({required this.onSubmit});

  final Future<Map<String, dynamic>> Function(Map<String, dynamic> body)
  onSubmit;

  @override
  State<_AreaBulkImportSheet> createState() => _AreaBulkImportSheetState();
}

class _AreaBulkImportSheetState extends State<_AreaBulkImportSheet> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _pathController = TextEditingController();
  String _level = 'region';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _pathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        8,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Bulk import area',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _level,
              decoration: const InputDecoration(labelText: 'Level'),
              items: const [
                DropdownMenuItem(value: 'region', child: Text('region')),
                DropdownMenuItem(value: 'district', child: Text('district')),
                DropdownMenuItem(value: 'ward', child: Text('ward')),
              ],
              onChanged: _isSubmitting
                  ? null
                  : (value) => setState(() => _level = value ?? _level),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _pathController,
              enabled: !_isSubmitting,
              decoration: const InputDecoration(
                labelText: 'Path',
                hintText: 'Region, District, Ward',
              ),
              validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: _isSubmitting ? null : _submit,
                child: Text(_isSubmitting ? 'Saving...' : 'Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      await widget.onSubmit({
        'level': _level,
        'path': _pathController.text
            .split(',')
            .map((part) => part.trim())
            .where((part) => part.isNotEmpty)
            .toList(),
      });
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }
}

class _MarketDetailScreen extends StatefulWidget {
  const _MarketDetailScreen({
    required this.token,
    required this.marketId,
    required this.permissions,
  });

  final String token;
  final String marketId;
  final Set<String> permissions;

  @override
  State<_MarketDetailScreen> createState() => _MarketDetailScreenState();
}

class _MarketDetailScreenState extends State<_MarketDetailScreen> {
  final ApiService _apiService = ApiService();
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Map<String, dynamic>> _load() {
    return _apiService.publicDetail('/markets/${widget.marketId}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Market')),
      body: FutureBuilder<Map<String, dynamic>>(
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
          final market = snapshot.data ?? const <String, dynamic>{};
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
            children: [
              _InfoTile(label: 'Name', value: _readValue(market, 'name')),
              _InfoTile(
                label: 'Code',
                value: _readValue(market, 'code', fallback: '-'),
              ),
              _InfoTile(
                label: 'Area',
                value: _readValue(market, 'admin_area.name', fallback: '-'),
              ),
              _InfoTile(
                label: 'Address',
                value: _readValue(market, 'address', fallback: '-'),
              ),
              _InfoTile(
                label: 'Status',
                value: _readValue(market, 'status', fallback: '-'),
              ),
              _InfoTile(
                label: 'Description',
                value: _readValue(market, 'description', fallback: '-'),
              ),
              const SizedBox(height: 20),
              _MarketPricesSection(
                token: widget.token,
                marketId: widget.marketId,
                permissions: widget.permissions,
                latest: false,
              ),
              const SizedBox(height: 16),
              _MarketPricesSection(
                token: widget.token,
                marketId: widget.marketId,
                permissions: widget.permissions,
                latest: true,
              ),
              const SizedBox(height: 20),
              if (widget.permissions.contains('markets.update'))
                FilledButton.icon(
                  onPressed: () => _edit(market),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit market'),
                ),
              if (widget.permissions.contains('markets.delete')) ...[
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _delete,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete market'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _edit(Map<String, dynamic> market) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _MarketFormSheet(
        token: widget.token,
        market: market,
        onSubmit: (body) => _apiService.protectedUpdate(
          token: widget.token,
          path: '/markets/${widget.marketId}',
          body: body,
        ),
      ),
    );
    if (changed == true && mounted) {
      setState(() => _future = _load());
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete market?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    try {
      await _apiService.protectedDelete(
        token: widget.token,
        path: '/markets/${widget.marketId}',
      );
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }
}

class _MarketFormSheet extends StatefulWidget {
  const _MarketFormSheet({
    required this.token,
    required this.onSubmit,
    this.market,
  });

  final String token;
  final Map<String, dynamic>? market;
  final Future<Map<String, dynamic>> Function(Map<String, dynamic> body)
  onSubmit;

  @override
  State<_MarketFormSheet> createState() => _MarketFormSheetState();
}

class _MarketFormSheetState extends State<_MarketFormSheet> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _codeController;
  late final TextEditingController _addressController;
  late final TextEditingController _latitudeController;
  late final TextEditingController _longitudeController;
  late final TextEditingController _descriptionController;
  late Future<List<Map<String, dynamic>>> _areasFuture;
  String? _selectedAreaId;
  String _status = 'active';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final market = widget.market ?? const <String, dynamic>{};
    _nameController = TextEditingController(text: _readValue(market, 'name'));
    _codeController = TextEditingController(text: _readValue(market, 'code'));
    _addressController = TextEditingController(
      text: _readValue(market, 'address'),
    );
    _latitudeController = TextEditingController(
      text: _readValue(market, 'latitude'),
    );
    _longitudeController = TextEditingController(
      text: _readValue(market, 'longitude'),
    );
    _descriptionController = TextEditingController(
      text: _readValue(market, 'description'),
    );
    _selectedAreaId = _readValue(market, 'admin_area.area_id');
    if (_selectedAreaId != null && _selectedAreaId!.isEmpty) {
      _selectedAreaId = null;
    }
    _status = _readValue(market, 'status', fallback: 'active');
    _areasFuture = _apiService.publicList('/areas');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _addressController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.9,
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _areasFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ErrorState(
              message: snapshot.error.toString(),
              onRetry: () => setState(() {
                _areasFuture = _apiService.publicList('/areas');
              }),
            );
          }
          final areas = snapshot.data ?? const <Map<String, dynamic>>[];
          if (_selectedAreaId == null && areas.isNotEmpty) {
            _selectedAreaId = areas.first['area_id']?.toString();
          }

          return Form(
            key: _formKey,
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                20,
                8,
                20,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              children: [
                Text(
                  widget.market == null ? 'Create market' : 'Edit market',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                _sheetField(_nameController, 'Name', enabled: !_isSubmitting),
                _sheetField(
                  _codeController,
                  'Code',
                  enabled: !_isSubmitting,
                  required: false,
                ),
                DropdownButtonFormField<String>(
                  initialValue: _selectedAreaId,
                  decoration: const InputDecoration(labelText: 'Area'),
                  items: areas
                      .map(
                        (area) => DropdownMenuItem(
                          value: area['area_id']?.toString(),
                          child: Text(
                            '${area['name'] ?? ''} (${area['level'] ?? ''})',
                          ),
                        ),
                      )
                      .toList(),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Required' : null,
                  onChanged: _isSubmitting
                      ? null
                      : (value) => setState(() => _selectedAreaId = value),
                ),
                const SizedBox(height: 12),
                _sheetField(
                  _addressController,
                  'Address',
                  enabled: !_isSubmitting,
                  required: false,
                ),
                _sheetField(
                  _latitudeController,
                  'Latitude',
                  enabled: !_isSubmitting,
                  required: false,
                ),
                _sheetField(
                  _longitudeController,
                  'Longitude',
                  enabled: !_isSubmitting,
                  required: false,
                ),
                _sheetField(
                  _descriptionController,
                  'Description',
                  enabled: !_isSubmitting,
                  required: false,
                ),
                DropdownButtonFormField<String>(
                  initialValue: _status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: const [
                    DropdownMenuItem(value: 'active', child: Text('active')),
                    DropdownMenuItem(
                      value: 'inactive',
                      child: Text('inactive'),
                    ),
                  ],
                  onChanged: _isSubmitting
                      ? null
                      : (value) => setState(() => _status = value ?? _status),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: _isSubmitting ? null : _submit,
                    child: Text(_isSubmitting ? 'Saving...' : 'Save'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isSubmitting = true);
    final body = <String, dynamic>{
      'name': _nameController.text.trim(),
      'admin_area_id': _selectedAreaId,
      'status': _status,
    };
    _addIfNotBlank(body, 'code', _codeController.text);
    _addIfNotBlank(body, 'address', _addressController.text);
    _addIfNotBlank(body, 'latitude', _latitudeController.text);
    _addIfNotBlank(body, 'longitude', _longitudeController.text);
    _addIfNotBlank(body, 'description', _descriptionController.text);
    try {
      await widget.onSubmit(body);
      if (mounted) {
        Navigator.pop(context, true);
      }
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }
}

class _MarketPricesSection extends StatefulWidget {
  const _MarketPricesSection({
    required this.token,
    required this.marketId,
    required this.permissions,
    required this.latest,
  });

  final String token;
  final String marketId;
  final Set<String> permissions;
  final bool latest;

  @override
  State<_MarketPricesSection> createState() => _MarketPricesSectionState();
}

class _MarketPricesSectionState extends State<_MarketPricesSection> {
  final ApiService _apiService = ApiService();
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() {
    return _apiService.publicList(
      widget.latest
          ? '/markets/${widget.marketId}/latest-prices'
          : '/markets/${widget.marketId}/prices',
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snapshot) {
        final title = widget.latest ? 'Latest prices' : 'Market prices';
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _InlineError(
            message: snapshot.error.toString(),
            onRetry: () => setState(() => _future = _load()),
          );
        }
        final prices = snapshot.data ?? const <Map<String, dynamic>>[];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (!widget.latest &&
                    widget.permissions.contains('market_prices.create'))
                  IconButton(
                    tooltip: 'Add price',
                    onPressed: _createPrice,
                    icon: const Icon(Icons.add_chart_outlined),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (prices.isEmpty)
              const Text('Hakuna taarifa kwa sasa.')
            else
              for (final price in prices) ...[
                _PriceAdminTile(
                  price: price,
                  onTap: widget.latest ? null : () => _openPriceDetail(price),
                ),
                const SizedBox(height: 8),
              ],
          ],
        );
      },
    );
  }

  Future<void> _createPrice() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _MarketPriceFormSheet(
        token: widget.token,
        onSubmit: (body) => _apiService.protectedCreate(
          token: widget.token,
          path: '/markets/${widget.marketId}/prices',
          body: body,
        ),
      ),
    );
    if (created == true && mounted) {
      setState(() => _future = _load());
    }
  }

  Future<void> _openPriceDetail(Map<String, dynamic> price) async {
    final priceId = price['price_id']?.toString();
    if (priceId == null || priceId.isEmpty) {
      return;
    }
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => _MarketPriceDetailScreen(
          token: widget.token,
          priceId: priceId,
          permissions: widget.permissions,
        ),
      ),
    );
    if (changed == true && mounted) {
      setState(() => _future = _load());
    }
  }
}

class _PriceAdminTile extends StatelessWidget {
  const _PriceAdminTile({required this.price, this.onTap});

  final Map<String, dynamic> price;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      tileColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      leading: const Icon(Icons.show_chart, color: Color(0xFF0E7A3B)),
      title: Text(
        _readValue(
          price,
          'commodity.name',
          fallback: _readValue(price, 'market.name', fallback: 'Price'),
        ),
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: Text(_readValue(price, 'price_date', fallback: '-')),
      trailing: Text(
        '${_readValue(price, 'currency', fallback: 'TZS')} ${_readValue(price, 'price', fallback: '-')}',
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _MarketPriceDetailScreen extends StatefulWidget {
  const _MarketPriceDetailScreen({
    required this.token,
    required this.priceId,
    required this.permissions,
  });

  final String token;
  final String priceId;
  final Set<String> permissions;

  @override
  State<_MarketPriceDetailScreen> createState() =>
      _MarketPriceDetailScreenState();
}

class _MarketPriceDetailScreenState extends State<_MarketPriceDetailScreen> {
  final ApiService _apiService = ApiService();
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Map<String, dynamic>> _load() {
    return _apiService.publicDetail('/market-prices/${widget.priceId}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Market price')),
      body: FutureBuilder<Map<String, dynamic>>(
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
          final price = snapshot.data ?? const <String, dynamic>{};
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
            children: [
              _InfoTile(
                label: 'Commodity',
                value: _readValue(price, 'commodity.name', fallback: '-'),
              ),
              _InfoTile(
                label: 'Market',
                value: _readValue(price, 'market.name', fallback: '-'),
              ),
              _InfoTile(label: 'Price', value: _readValue(price, 'price')),
              _InfoTile(
                label: 'Currency',
                value: _readValue(price, 'currency', fallback: 'TZS'),
              ),
              _InfoTile(
                label: 'Date',
                value: _readValue(price, 'price_date', fallback: '-'),
              ),
              const SizedBox(height: 20),
              if (widget.permissions.contains('market_prices.update'))
                FilledButton.icon(
                  onPressed: () => _edit(price),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit price'),
                ),
              if (widget.permissions.contains('market_prices.delete')) ...[
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _delete,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete price'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _edit(Map<String, dynamic> price) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _MarketPriceFormSheet(
        token: widget.token,
        price: price,
        onSubmit: (body) => _apiService.protectedUpdate(
          token: widget.token,
          path: '/market-prices/${widget.priceId}',
          body: body,
        ),
      ),
    );
    if (changed == true && mounted) {
      setState(() => _future = _load());
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete price?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _apiService.protectedDelete(
        token: widget.token,
        path: '/market-prices/${widget.priceId}',
      );
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }
}

class _MarketPriceFormSheet extends StatefulWidget {
  const _MarketPriceFormSheet({
    required this.token,
    required this.onSubmit,
    this.price,
  });

  final String token;
  final Map<String, dynamic>? price;
  final Future<Map<String, dynamic>> Function(Map<String, dynamic> body)
  onSubmit;

  @override
  State<_MarketPriceFormSheet> createState() => _MarketPriceFormSheetState();
}

class _MarketPriceFormSheetState extends State<_MarketPriceFormSheet> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _priceController;
  late final TextEditingController _currencyController;
  late final TextEditingController _dateController;
  late Future<List<Map<String, dynamic>>> _commoditiesFuture;
  String? _selectedCommodityId;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final price = widget.price ?? const <String, dynamic>{};
    _priceController = TextEditingController(text: _readValue(price, 'price'));
    _currencyController = TextEditingController(
      text: _readValue(price, 'currency', fallback: 'TZS'),
    );
    _dateController = TextEditingController(
      text: _readValue(
        price,
        'price_date',
        fallback: DateTime.now().toIso8601String().split('T').first,
      ),
    );
    _selectedCommodityId = _readValue(price, 'commodity.commodity_id');
    if (_selectedCommodityId != null && _selectedCommodityId!.isEmpty) {
      _selectedCommodityId = null;
    }
    _commoditiesFuture = _apiService.publicList('/commodities');
  }

  @override
  void dispose() {
    _priceController.dispose();
    _currencyController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.75,
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _commoditiesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ErrorState(
              message: snapshot.error.toString(),
              onRetry: () => setState(() {
                _commoditiesFuture = _apiService.publicList('/commodities');
              }),
            );
          }
          final commodities = snapshot.data ?? const <Map<String, dynamic>>[];
          if (_selectedCommodityId == null && commodities.isNotEmpty) {
            _selectedCommodityId = commodities.first['commodity_id']
                ?.toString();
          }
          return Form(
            key: _formKey,
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                20,
                8,
                20,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              children: [
                Text(
                  widget.price == null ? 'Create price' : 'Edit price',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _selectedCommodityId,
                  decoration: const InputDecoration(labelText: 'Commodity'),
                  items: commodities
                      .map(
                        (commodity) => DropdownMenuItem(
                          value: commodity['commodity_id']?.toString(),
                          child: Text(commodity['name']?.toString() ?? ''),
                        ),
                      )
                      .toList(),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Required' : null,
                  onChanged: _isSubmitting
                      ? null
                      : (value) => setState(() => _selectedCommodityId = value),
                ),
                const SizedBox(height: 12),
                _sheetField(_priceController, 'Price', enabled: !_isSubmitting),
                _sheetField(
                  _currencyController,
                  'Currency',
                  enabled: !_isSubmitting,
                ),
                _sheetField(
                  _dateController,
                  'Price date',
                  enabled: !_isSubmitting,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: _isSubmitting ? null : _submit,
                    child: Text(_isSubmitting ? 'Saving...' : 'Save'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      await widget.onSubmit({
        'commodity_id': _selectedCommodityId,
        'price': _priceController.text.trim(),
        'currency': _currencyController.text.trim(),
        'price_date': _dateController.text.trim(),
      });
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      tileColor: Colors.white,
      title: Text(message),
      trailing: IconButton(onPressed: onRetry, icon: const Icon(Icons.refresh)),
    );
  }
}

class _CommodityDetailScreen extends StatefulWidget {
  const _CommodityDetailScreen({
    required this.token,
    required this.commodityId,
    required this.permissions,
  });

  final String token;
  final String commodityId;
  final Set<String> permissions;

  @override
  State<_CommodityDetailScreen> createState() => _CommodityDetailScreenState();
}

class _CommodityDetailScreenState extends State<_CommodityDetailScreen> {
  final ApiService _apiService = ApiService();
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Map<String, dynamic>> _load() {
    return _apiService.publicDetail('/commodities/${widget.commodityId}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Commodity')),
      body: FutureBuilder<Map<String, dynamic>>(
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
          final commodity = snapshot.data ?? const <String, dynamic>{};
          final categories = commodity['categories'] is List
              ? commodity['categories'] as List
              : const [];
          final categoryNames = categories
              .whereType<Map<String, dynamic>>()
              .map((category) => category['name']?.toString() ?? '')
              .where((name) => name.isNotEmpty)
              .join(', ');

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
            children: [
              _InfoTile(label: 'Name', value: _readValue(commodity, 'name')),
              _InfoTile(label: 'Unit', value: _readValue(commodity, 'unit')),
              _InfoTile(
                label: 'Description',
                value: _readValue(commodity, 'description', fallback: '-'),
              ),
              _InfoTile(
                label: 'Categories',
                value: categoryNames.isEmpty ? '-' : categoryNames,
              ),
              const SizedBox(height: 20),
              _CommodityPricesSection(
                commodityId: widget.commodityId,
                mode: _CommodityPriceViewMode.prices,
              ),
              const SizedBox(height: 16),
              _CommodityPricesSection(
                commodityId: widget.commodityId,
                mode: _CommodityPriceViewMode.history,
              ),
              const SizedBox(height: 16),
              _CommodityPricesSection(
                commodityId: widget.commodityId,
                mode: _CommodityPriceViewMode.comparison,
              ),
              const SizedBox(height: 20),
              if (widget.permissions.contains('commodities.update'))
                FilledButton.icon(
                  onPressed: () => _edit(commodity),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit commodity'),
                ),
              if (widget.permissions.contains('commodities.delete')) ...[
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _delete,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete commodity'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _edit(Map<String, dynamic> commodity) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _CommodityFormSheet(
        token: widget.token,
        commodity: commodity,
        onSubmit: (body) => _apiService.protectedUpdate(
          token: widget.token,
          path: '/commodities/${widget.commodityId}',
          body: body,
        ),
      ),
    );
    if (changed == true && mounted) {
      setState(() => _future = _load());
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete commodity?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    try {
      await _apiService.protectedDelete(
        token: widget.token,
        path: '/commodities/${widget.commodityId}',
      );
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }
}

enum _CommodityPriceViewMode { prices, history, comparison }

class _CommodityPricesSection extends StatefulWidget {
  const _CommodityPricesSection({
    required this.commodityId,
    required this.mode,
  });

  final String commodityId;
  final _CommodityPriceViewMode mode;

  @override
  State<_CommodityPricesSection> createState() =>
      _CommodityPricesSectionState();
}

class _CommodityPricesSectionState extends State<_CommodityPricesSection> {
  final ApiService _apiService = ApiService();
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() {
    return _apiService.publicList(_endpoint);
  }

  String get _endpoint {
    return switch (widget.mode) {
      _CommodityPriceViewMode.prices =>
        '/commodities/${widget.commodityId}/prices',
      _CommodityPriceViewMode.history =>
        '/commodities/${widget.commodityId}/price-history',
      _CommodityPriceViewMode.comparison =>
        '/commodities/${widget.commodityId}/price-comparison',
    };
  }

  String get _title {
    return switch (widget.mode) {
      _CommodityPriceViewMode.prices => 'Commodity prices',
      _CommodityPriceViewMode.history => 'Price history',
      _CommodityPriceViewMode.comparison => 'Price comparison',
    };
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _InlineError(
            message: snapshot.error.toString(),
            onRetry: () => setState(() => _future = _load()),
          );
        }
        final prices = snapshot.data ?? const <Map<String, dynamic>>[];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _title,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 8),
            if (prices.isEmpty)
              const Text('Hakuna taarifa kwa sasa.')
            else
              for (final price in prices.take(8)) ...[
                _PriceAdminTile(price: price),
                const SizedBox(height: 8),
              ],
          ],
        );
      },
    );
  }
}

class _CommodityFormSheet extends StatefulWidget {
  const _CommodityFormSheet({
    required this.token,
    required this.onSubmit,
    this.commodity,
  });

  final String token;
  final Map<String, dynamic>? commodity;
  final Future<Map<String, dynamic>> Function(Map<String, dynamic> body)
  onSubmit;

  @override
  State<_CommodityFormSheet> createState() => _CommodityFormSheetState();
}

class _CommodityFormSheetState extends State<_CommodityFormSheet> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late Future<List<List<Map<String, dynamic>>>> _optionsFuture;
  String? _selectedUnitId;
  final Set<String> _selectedCategoryIds = <String>{};
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final commodity = widget.commodity ?? const <String, dynamic>{};
    _nameController = TextEditingController(
      text: _readValue(commodity, 'name'),
    );
    _descriptionController = TextEditingController(
      text: _readValue(commodity, 'description'),
    );
    final unitDetail = commodity['unit_detail'];
    if (unitDetail is Map<String, dynamic>) {
      _selectedUnitId = unitDetail['unit_id']?.toString();
    }
    final categories = commodity['categories'];
    if (categories is List) {
      _selectedCategoryIds.addAll(
        categories
            .whereType<Map<String, dynamic>>()
            .map((category) => category['category_id']?.toString() ?? '')
            .where((id) => id.isNotEmpty),
      );
    }
    _optionsFuture = Future.wait([
      _apiService.publicList('/commodities/units'),
      _apiService.publicList('/commodities/categories'),
    ]);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.9,
      child: FutureBuilder<List<List<Map<String, dynamic>>>>(
        future: _optionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ErrorState(
              message: snapshot.error.toString(),
              onRetry: () => setState(() {
                _optionsFuture = Future.wait([
                  _apiService.publicList('/commodities/units'),
                  _apiService.publicList('/commodities/categories'),
                ]);
              }),
            );
          }

          final units = snapshot.data?[0] ?? const <Map<String, dynamic>>[];
          final categories =
              snapshot.data?[1] ?? const <Map<String, dynamic>>[];
          if (_selectedUnitId == null && units.isNotEmpty) {
            _selectedUnitId = units.first['unit_id']?.toString();
          }

          return Form(
            key: _formKey,
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                20,
                8,
                20,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              children: [
                Text(
                  widget.commodity == null
                      ? 'Create commodity'
                      : 'Edit commodity',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                _sheetField(_nameController, 'Name', enabled: !_isSubmitting),
                DropdownButtonFormField<String>(
                  initialValue: _selectedUnitId,
                  decoration: const InputDecoration(labelText: 'Unit'),
                  items: units
                      .map(
                        (unit) => DropdownMenuItem(
                          value: unit['unit_id']?.toString(),
                          child: Text(
                            '${unit['name'] ?? ''} (${unit['symbol'] ?? ''})',
                          ),
                        ),
                      )
                      .toList(),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Required' : null,
                  onChanged: _isSubmitting
                      ? null
                      : (value) => setState(() => _selectedUnitId = value),
                ),
                const SizedBox(height: 12),
                _sheetField(
                  _descriptionController,
                  'Description',
                  enabled: !_isSubmitting,
                  required: false,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Categories',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                for (final category in categories)
                  CheckboxListTile(
                    value: _selectedCategoryIds.contains(
                      category['category_id']?.toString() ?? '',
                    ),
                    onChanged: _isSubmitting
                        ? null
                        : (value) {
                            final id = category['category_id']?.toString();
                            if (id == null || id.isEmpty) {
                              return;
                            }
                            setState(() {
                              if (value == true) {
                                _selectedCategoryIds.add(id);
                              } else {
                                _selectedCategoryIds.remove(id);
                              }
                            });
                          },
                    title: Text(category['name']?.toString() ?? ''),
                  ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: _isSubmitting ? null : _submit,
                    child: Text(_isSubmitting ? 'Saving...' : 'Save'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await widget.onSubmit({
        'name': _nameController.text.trim(),
        'unit_id': _selectedUnitId,
        'description': _descriptionController.text.trim(),
        'category_ids': _selectedCategoryIds.toList(),
      });
      if (mounted) {
        Navigator.pop(context, true);
      }
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }
}

class _ListingDetailScreen extends StatefulWidget {
  const _ListingDetailScreen({
    required this.token,
    required this.listingId,
    required this.permissions,
  });

  final String token;
  final String listingId;
  final Set<String> permissions;

  @override
  State<_ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends State<_ListingDetailScreen> {
  final ApiService _apiService = ApiService();
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Map<String, dynamic>> _load() {
    return _apiService.publicDetail('/listings/${widget.listingId}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Listing')),
      body: FutureBuilder<Map<String, dynamic>>(
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
          final listing = snapshot.data ?? const <String, dynamic>{};
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
            children: [
              _InfoTile(label: 'Title', value: _readValue(listing, 'title')),
              _InfoTile(
                label: 'Commodity',
                value: _readValue(listing, 'commodity.name', fallback: '-'),
              ),
              _InfoTile(
                label: 'Area',
                value: _readValue(listing, 'adm_area.name', fallback: '-'),
              ),
              _InfoTile(label: 'Price', value: _readValue(listing, 'price')),
              _InfoTile(
                label: 'Quantity',
                value: _readValue(listing, 'quantity', fallback: '-'),
              ),
              _InfoTile(
                label: 'Status',
                value: _readValue(listing, 'status', fallback: '-'),
              ),
              _InfoTile(
                label: 'Description',
                value: _readValue(listing, 'description', fallback: '-'),
              ),
              const SizedBox(height: 20),
              if (widget.permissions.contains('listings.update'))
                FilledButton.icon(
                  onPressed: () => _edit(listing),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit listing'),
                ),
              if (widget.permissions.contains('listings.delete')) ...[
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _delete,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete listing'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _edit(Map<String, dynamic> listing) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _ListingFormSheet(
        token: widget.token,
        listing: listing,
        onSubmit: (body) => _apiService.protectedUpdate(
          token: widget.token,
          path: '/listings/${widget.listingId}',
          body: body,
        ),
      ),
    );
    if (changed == true && mounted) {
      setState(() => _future = _load());
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete listing?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _apiService.protectedDelete(
        token: widget.token,
        path: '/listings/${widget.listingId}',
      );
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }
}

class _ListingFormSheet extends StatefulWidget {
  const _ListingFormSheet({
    required this.token,
    required this.onSubmit,
    this.listing,
  });

  final String token;
  final Map<String, dynamic>? listing;
  final Future<Map<String, dynamic>> Function(Map<String, dynamic> body)
  onSubmit;

  @override
  State<_ListingFormSheet> createState() => _ListingFormSheetState();
}

class _ListingFormSheetState extends State<_ListingFormSheet> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _quantityController;
  late final TextEditingController _imageUrlsController;
  late Future<List<List<Map<String, dynamic>>>> _optionsFuture;
  String? _selectedCommodityId;
  String? _selectedAreaId;
  String _status = 'active';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final listing = widget.listing ?? const <String, dynamic>{};
    _titleController = TextEditingController(
      text: _readValue(listing, 'title'),
    );
    _descriptionController = TextEditingController(
      text: _readValue(listing, 'description'),
    );
    _priceController = TextEditingController(
      text: _readValue(listing, 'price'),
    );
    _quantityController = TextEditingController(
      text: _readValue(listing, 'quantity'),
    );
    final images = listing['images'];
    _imageUrlsController = TextEditingController(
      text: images is List
          ? images
                .whereType<Map<String, dynamic>>()
                .map((image) => image['image_url']?.toString() ?? '')
                .where((url) => url.isNotEmpty)
                .join(', ')
          : '',
    );
    _selectedCommodityId = _readValue(listing, 'commodity.commodity_id');
    if (_selectedCommodityId != null && _selectedCommodityId!.isEmpty) {
      _selectedCommodityId = null;
    }
    _selectedAreaId = _readValue(listing, 'adm_area.area_id');
    if (_selectedAreaId != null && _selectedAreaId!.isEmpty) {
      _selectedAreaId = null;
    }
    _status = _readValue(listing, 'status', fallback: 'active');
    _optionsFuture = Future.wait([
      _apiService.publicList('/commodities'),
      _apiService.publicList('/areas'),
    ]);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _imageUrlsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.9,
      child: FutureBuilder<List<List<Map<String, dynamic>>>>(
        future: _optionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ErrorState(
              message: snapshot.error.toString(),
              onRetry: () => setState(() {
                _optionsFuture = Future.wait([
                  _apiService.publicList('/commodities'),
                  _apiService.publicList('/areas'),
                ]);
              }),
            );
          }
          final commodities =
              snapshot.data?[0] ?? const <Map<String, dynamic>>[];
          final areas = snapshot.data?[1] ?? const <Map<String, dynamic>>[];
          if (_selectedCommodityId == null && commodities.isNotEmpty) {
            _selectedCommodityId = commodities.first['commodity_id']
                ?.toString();
          }
          if (_selectedAreaId == null && areas.isNotEmpty) {
            _selectedAreaId = areas.first['area_id']?.toString();
          }
          return Form(
            key: _formKey,
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                20,
                8,
                20,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              children: [
                Text(
                  widget.listing == null ? 'Create listing' : 'Edit listing',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                _sheetField(_titleController, 'Title', enabled: !_isSubmitting),
                DropdownButtonFormField<String>(
                  initialValue: _selectedCommodityId,
                  decoration: const InputDecoration(labelText: 'Commodity'),
                  items: commodities
                      .map(
                        (commodity) => DropdownMenuItem(
                          value: commodity['commodity_id']?.toString(),
                          child: Text(commodity['name']?.toString() ?? ''),
                        ),
                      )
                      .toList(),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Required' : null,
                  onChanged: _isSubmitting
                      ? null
                      : (value) => setState(() => _selectedCommodityId = value),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _selectedAreaId,
                  decoration: const InputDecoration(labelText: 'Area'),
                  items: areas
                      .map(
                        (area) => DropdownMenuItem(
                          value: area['area_id']?.toString(),
                          child: Text(
                            '${area['name'] ?? ''} (${area['level'] ?? ''})',
                          ),
                        ),
                      )
                      .toList(),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Required' : null,
                  onChanged: _isSubmitting
                      ? null
                      : (value) => setState(() => _selectedAreaId = value),
                ),
                const SizedBox(height: 12),
                _sheetField(
                  _descriptionController,
                  'Description',
                  enabled: !_isSubmitting,
                  required: false,
                ),
                _sheetField(_priceController, 'Price', enabled: !_isSubmitting),
                _sheetField(
                  _quantityController,
                  'Quantity',
                  enabled: !_isSubmitting,
                  required: false,
                ),
                DropdownButtonFormField<String>(
                  initialValue: _status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: const [
                    DropdownMenuItem(value: 'active', child: Text('active')),
                    DropdownMenuItem(
                      value: 'inactive',
                      child: Text('inactive'),
                    ),
                    DropdownMenuItem(value: 'sold', child: Text('sold')),
                  ],
                  onChanged: _isSubmitting
                      ? null
                      : (value) => setState(() => _status = value ?? _status),
                ),
                const SizedBox(height: 12),
                _sheetField(
                  _imageUrlsController,
                  'Image URLs',
                  enabled: !_isSubmitting,
                  required: false,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: _isSubmitting ? null : _submit,
                    child: Text(_isSubmitting ? 'Saving...' : 'Save'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    final body = <String, dynamic>{
      'commodity_id': _selectedCommodityId,
      'adm_area_id': _selectedAreaId,
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'price': _priceController.text.trim(),
      'status': _status,
      'image_urls': _imageUrlsController.text
          .split(',')
          .map((url) => url.trim())
          .where((url) => url.isNotEmpty)
          .toList(),
    };
    _addIfNotBlank(body, 'quantity', _quantityController.text);
    try {
      await widget.onSubmit(body);
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }
}

Widget _sheetField(
  TextEditingController controller,
  String label, {
  bool enabled = true,
  bool required = true,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      enabled: enabled,
      decoration: InputDecoration(labelText: label),
      validator: required
          ? (value) => value == null || value.trim().isEmpty ? 'Required' : null
          : null,
    ),
  );
}

void _addIfNotBlank(Map<String, dynamic> body, String key, String value) {
  final trimmed = value.trim();
  if (trimmed.isNotEmpty) {
    body[key] = trimmed;
  }
}

class _UserFormSheet extends StatefulWidget {
  const _UserFormSheet({
    required this.token,
    required this.onSubmit,
    this.user,
  });

  final String token;
  final Map<String, dynamic>? user;
  final Future<Map<String, dynamic>> Function(Map<String, dynamic> body)
  onSubmit;

  @override
  State<_UserFormSheet> createState() => _UserFormSheetState();
}

class _UserFormSheetState extends State<_UserFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _usernameController;
  late final TextEditingController _emailController;
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _passwordController;
  String _role = 'farmer';
  bool _isActive = true;
  bool _isSubmitting = false;

  bool get _isEditing => widget.user != null;

  @override
  void initState() {
    super.initState();
    final user = widget.user;
    _usernameController = TextEditingController(
      text: _readValue(user ?? const {}, 'username'),
    );
    _emailController = TextEditingController(
      text: _readValue(user ?? const {}, 'email'),
    );
    _firstNameController = TextEditingController(
      text: _readValue(user ?? const {}, 'first_name'),
    );
    _lastNameController = TextEditingController(
      text: _readValue(user ?? const {}, 'last_name'),
    );
    _phoneController = TextEditingController(
      text: _readValue(user ?? const {}, 'profile.phone_number'),
    );
    _passwordController = TextEditingController();
    _role = _readValue(user ?? const {}, 'profile.role', fallback: 'farmer');
    _isActive = user?['is_active'] is bool ? user!['is_active'] as bool : true;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        8,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _isEditing ? 'Edit user' : 'Create user',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              _field(_usernameController, 'Username'),
              _field(_emailController, 'Email'),
              _field(_firstNameController, 'First name', required: false),
              _field(_lastNameController, 'Last name', required: false),
              _field(_phoneController, 'Phone', required: false),
              if (!_isEditing)
                _field(_passwordController, 'Password', obscure: true),
              DropdownButtonFormField<String>(
                initialValue: _role,
                decoration: const InputDecoration(labelText: 'Role'),
                items: const [
                  DropdownMenuItem(value: 'admin', child: Text('admin')),
                  DropdownMenuItem(value: 'farmer', child: Text('farmer')),
                  DropdownMenuItem(value: 'buyer', child: Text('buyer')),
                  DropdownMenuItem(value: 'seller', child: Text('seller')),
                  DropdownMenuItem(value: 'user', child: Text('user')),
                ],
                onChanged: _isSubmitting
                    ? null
                    : (value) => setState(() => _role = value ?? _role),
              ),
              SwitchListTile(
                value: _isActive,
                onChanged: _isSubmitting
                    ? null
                    : (value) => setState(() => _isActive = value),
                title: const Text('Active'),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: Text(_isSubmitting ? 'Saving...' : 'Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool required = true,
    bool obscure = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        enabled: !_isSubmitting,
        decoration: InputDecoration(labelText: label),
        validator: required
            ? (value) =>
                  value == null || value.trim().isEmpty ? 'Required' : null
            : null,
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isSubmitting = true);
    final body = <String, dynamic>{
      'username': _usernameController.text.trim(),
      'email': _emailController.text.trim(),
      'first_name': _firstNameController.text.trim(),
      'last_name': _lastNameController.text.trim(),
      'phone_number': _phoneController.text.trim(),
      'role': _role,
      'is_active': _isActive,
      'is_staff': _role == 'admin',
      'is_superuser': false,
    };
    if (!_isEditing) {
      body['password'] = _passwordController.text;
    }
    try {
      await widget.onSubmit(body);
      if (!mounted) {
        return;
      }
      Navigator.pop(context, true);
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
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
