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

enum _AdminModuleType { generic, users, roles, permissions }

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
