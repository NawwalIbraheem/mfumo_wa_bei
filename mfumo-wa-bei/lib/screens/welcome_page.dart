import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'login_page.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  static const routeName = '/welcome';

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  final TextEditingController _searchController = TextEditingController();
  final ApiService _apiService = ApiService();

  String selectedCropFilter = 'Zote';
  String searchQuery = '';
  int selectedTab = 0;
  Future<Map<String, dynamic>>? _meFuture;
  Map<String, dynamic>? _routeUser;
  String? _token;
  bool _loadedRouteArgs = false;

  final List<Map<String, dynamic>> markets = const [
    {
      'name': 'Soko Kuu la Morogoro',
      'location': 'Katikati ya Mji, Morogoro',
      'ricePrice': 2400,
      'riceTrend': 'up',
      'riceChange': '+2.5%',
      'beanPrice': 3100,
      'beanTrend': 'stable',
      'beanChange': '0.0%',
      'distance': '0.5 km',
    },
    {
      'name': 'Soko la Sabasaba',
      'location': 'Sabasaba, Morogoro',
      'ricePrice': 2500,
      'riceTrend': 'stable',
      'riceChange': '0.0%',
      'beanPrice': 3200,
      'beanTrend': 'up',
      'beanChange': '+4.1%',
      'distance': '2.1 km',
    },
    {
      'name': 'Soko la Kiwanja cha Ndege',
      'location': 'Kiwanja cha Ndege, Morogoro',
      'ricePrice': 2300,
      'riceTrend': 'down',
      'riceChange': '-1.2%',
      'beanPrice': 3000,
      'beanTrend': 'down',
      'beanChange': '-2.0%',
      'distance': '3.5 km',
    },
    {
      'name': 'Soko la Mazimbu',
      'location': 'Mazimbu Rd, Morogoro',
      'ricePrice': 2450,
      'riceTrend': 'up',
      'riceChange': '+1.0%',
      'beanPrice': 3150,
      'beanTrend': 'up',
      'beanChange': '+1.8%',
      'distance': '4.2 km',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _loadRouteArgs();

    final filteredMarkets = markets.where((market) {
      final query = searchQuery.toLowerCase();
      return market['name'].toString().toLowerCase().contains(query) ||
          market['location'].toString().toLowerCase().contains(query);
    }).toList();

    if (_meFuture != null) {
      return FutureBuilder<Map<String, dynamic>>(
        future: _meFuture,
        builder: (context, snapshot) {
          final user = _readUser(snapshot.data) ?? _routeUser;
          final permissions = _readPermissions(snapshot.data ?? user);
          final role = _readRole(user);

          if (snapshot.connectionState == ConnectionState.waiting && user == null) {
            return const Scaffold(
              backgroundColor: Color(0xFFF6F7F2),
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasError && _routeUser == null) {
            return Scaffold(
              backgroundColor: const Color(0xFFF6F7F2),
              body: SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            );
          }

          return _buildScaffold(
            user: user,
            permissions: permissions,
            role: role,
            filteredMarkets: filteredMarkets,
          );
        },
      );
    }

    final permissions = _readPermissions(_routeUser);
    return _buildScaffold(
      user: _routeUser,
      permissions: permissions,
      role: _readRole(_routeUser),
      filteredMarkets: filteredMarkets,
    );
  }

  Widget _buildScaffold({
    required Map<String, dynamic>? user,
    required Set<String> permissions,
    required String role,
    required List<Map<String, dynamic>> filteredMarkets,
  }) {
    final fullName = _displayName(user);
    final canCreateMarketPrice = permissions.isEmpty ||
        permissions.contains('market_prices.create') ||
        permissions.contains('commodity_prices.create');
    final canSeePriceTools = permissions.isEmpty ||
        permissions.contains('market_prices.list') ||
        permissions.contains('commodity_prices.list') ||
        permissions.contains('commodity_prices.history');
    final canSeeNotifications = permissions.isEmpty || permissions.contains('auth.me');
    final canSeeAdmin = permissions.contains('users.list') ||
        permissions.contains('roles.list') ||
        permissions.contains('permissions.list');

    final destinations = <NavigationDestination>[
      const NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Nyumbani'),
      if (canSeePriceTools) const NavigationDestination(icon: Icon(Icons.show_chart), label: 'Bei'),
      if (canSeeNotifications) const NavigationDestination(icon: Icon(Icons.notifications_outlined), label: 'Arifa'),
      if (canSeeAdmin) const NavigationDestination(icon: Icon(Icons.admin_panel_settings_outlined), label: 'Admin'),
      const NavigationDestination(icon: Icon(Icons.person_outline), label: 'Akaunti'),
    ];

    final tabs = <Widget>[
      _HomeTab(
        fullName: fullName,
        role: role,
        filteredMarkets: filteredMarkets,
        selectedCropFilter: selectedCropFilter,
        searchController: _searchController,
        searchQuery: searchQuery,
        permissions: permissions,
        onSearchChanged: (value) => setState(() => searchQuery = value),
        onClearSearch: () {
          setState(() {
            _searchController.clear();
            searchQuery = '';
          });
        },
        onFilterChanged: (value) => setState(() => selectedCropFilter = value),
        onMarketTap: _showMarketDetails,
        onProfileTap: () => _showProfileDialog(user),
      ),
      if (canSeePriceTools)
        const _SimpleTab(
          icon: Icons.show_chart,
          title: 'Mwenendo',
          subtitle: 'Grafu za bei zitaonekana hapa baada ya kuunganisha API.',
        ),
      if (canSeeNotifications)
        const _SimpleTab(
          icon: Icons.notifications_outlined,
          title: 'Taarifa',
          subtitle: 'Arifa za mabadiliko ya bei na masoko mapya.',
        ),
      if (canSeeAdmin)
        _AdminTab(permissions: permissions),
      const _SimpleTab(
        icon: Icons.person_outline,
        title: 'Akaunti',
        subtitle: 'Wasifu, mipangilio na kutoka kwenye akaunti.',
      ),
    ];

    final safeSelectedTab = selectedTab.clamp(0, tabs.length - 1);
    if (safeSelectedTab != selectedTab) {
      selectedTab = safeSelectedTab;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F2),
      body: SafeArea(
        child: IndexedStack(
          index: safeSelectedTab,
          children: tabs,
        ),
      ),
      floatingActionButton: safeSelectedTab == 0 && canCreateMarketPrice
          ? FloatingActionButton.extended(
              onPressed: _showReportPriceBottomSheet,
              backgroundColor: const Color(0xFF0E7A3B),
              icon: const Icon(Icons.add_chart_outlined, color: Colors.white),
              label: const Text(
                'Ripoti Bei',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: safeSelectedTab,
        onDestinationSelected: (index) => setState(() => selectedTab = index),
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFE8F5E9),
        destinations: destinations,
      ),
    );
  }

  void _loadRouteArgs() {
    if (_loadedRouteArgs) {
      return;
    }
    _loadedRouteArgs = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic> && (args.containsKey('user') || args.containsKey('token'))) {
      final user = args['user'];
      _routeUser = user is Map<String, dynamic> ? user : null;
      _token = args['token']?.toString();
    } else if (args is Map<String, dynamic>) {
      _routeUser = args;
    }

    if (_token != null && _token!.isNotEmpty) {
      _meFuture = _apiService.me(token: _token!);
    }
  }

  Map<String, dynamic>? _readUser(Map<String, dynamic>? data) {
    if (data == null) {
      return null;
    }
    final user = data['user'];
    if (user is Map<String, dynamic>) {
      return user;
    }
    if (data.containsKey('user_id') || data.containsKey('email')) {
      return data;
    }
    return null;
  }

  Set<String> _readPermissions(Map<String, dynamic>? data) {
    final user = _readUser(data) ?? data;
    final permissions = user?['permissions'];
    if (permissions is List) {
      return permissions.map((permission) => permission.toString()).toSet();
    }
    return <String>{};
  }

  String _readRole(Map<String, dynamic>? user) {
    final profile = user?['profile'];
    if (profile is Map<String, dynamic>) {
      return profile['role']?.toString() ?? 'user';
    }
    return user?['role']?.toString() ?? 'user';
  }

  String _displayName(Map<String, dynamic>? user) {
    final fullName = user?['full_name']?.toString();
    if (fullName != null && fullName.trim().isNotEmpty) {
      return fullName;
    }
    final firstName = user?['first_name']?.toString() ?? '';
    final lastName = user?['last_name']?.toString() ?? '';
    final name = '$firstName $lastName'.trim();
    return name.isEmpty ? 'Mtumiaji' : name;
  }

  void _showProfileDialog(Map<String, dynamic>? user) {
    final name = _displayName(user);
    final profile = user?['profile'];
    final phoneNumber = profile is Map<String, dynamic>
        ? profile['phone_number']?.toString()
        : user?['phone_number']?.toString();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFF0E7A3B),
              child: Text(_initials(name), style: const TextStyle(color: Colors.white)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(name, style: const TextStyle(fontSize: 18))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ProfileLine(icon: Icons.email_outlined, text: user?['email']?.toString() ?? 'Hakuna barua pepe'),
            const SizedBox(height: 12),
            _ProfileLine(icon: Icons.phone_outlined, text: phoneNumber ?? 'Hakuna namba ya simu'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Funga')),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, LoginPage.routeName);
            },
            icon: const Icon(Icons.logout),
            label: const Text('Ondoka'),
          ),
        ],
      ),
    );
  }

  void _showMarketDetails(Map<String, dynamic> market) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(market['name'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 18, color: Color(0xFF0E7A3B)),
                const SizedBox(width: 6),
                Expanded(child: Text(market['location'], style: const TextStyle(color: Color(0xFF6B7280)))),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: _PricePanel(label: 'Mchele', price: market['ricePrice'], change: market['riceChange'], icon: Icons.rice_bowl_outlined, color: const Color(0xFF0E7A3B))),
                const SizedBox(width: 12),
                Expanded(child: _PricePanel(label: 'Maharage', price: market['beanPrice'], change: market['beanChange'], icon: Icons.grain_outlined, color: const Color(0xFFB45309))),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Mwenendo wa wiki 4', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                _Bar(label: 'W1', height: 56),
                _Bar(label: 'W2', height: 72),
                _Bar(label: 'W3', height: 64),
                _Bar(label: 'Leo', height: 92),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showReportPriceBottomSheet() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ripoti Bei Mpya', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            const Text('Weka bei uliyoiona sokoni leo.', style: TextStyle(color: Color(0xFF6B7280))),
            const SizedBox(height: 18),
            DropdownButtonFormField<String>(
              initialValue: 'Mchele',
              decoration: const InputDecoration(labelText: 'Zao'),
              items: const [
                DropdownMenuItem(value: 'Mchele', child: Text('Mchele')),
                DropdownMenuItem(value: 'Maharage', child: Text('Maharage')),
              ],
              onChanged: (_) {},
            ),
            const SizedBox(height: 12),
            TextFormField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Bei kwa kilo', prefixText: 'TSh '),
            ),
            const SizedBox(height: 12),
            TextFormField(decoration: const InputDecoration(labelText: 'Jina la soko')),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tuma Ripoti'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.take(2).map((part) => part.isEmpty ? '' : part[0]).join().toUpperCase();
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab({
    required this.fullName,
    required this.role,
    required this.filteredMarkets,
    required this.selectedCropFilter,
    required this.searchController,
    required this.searchQuery,
    required this.permissions,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onFilterChanged,
    required this.onMarketTap,
    required this.onProfileTap,
  });

  final String fullName;
  final String role;
  final List<Map<String, dynamic>> filteredMarkets;
  final String selectedCropFilter;
  final TextEditingController searchController;
  final String searchQuery;
  final Set<String> permissions;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final ValueChanged<String> onFilterChanged;
  final ValueChanged<Map<String, dynamic>> onMarketTap;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _DashboardHeader(fullName: fullName, role: role, onProfileTap: onProfileTap),
        ),
        if (permissions.contains('users.list') || permissions.contains('markets.create') || permissions.contains('commodities.create'))
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            sliver: SliverToBoxAdapter(child: _PermissionActions(permissions: permissions)),
          ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: const [
                Expanded(child: _SummaryCard(icon: Icons.rice_bowl_outlined, label: 'Mchele', value: 'TSh 2,400', trend: '+1.5%')),
                SizedBox(width: 12),
                Expanded(child: _SummaryCard(icon: Icons.grain_outlined, label: 'Maharage', value: 'TSh 3,100', trend: '0.0%')),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 22, 16, 10),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Masoko ya Morogoro', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                TextField(
                  controller: searchController,
                  onChanged: onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Tafuta soko au eneo...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: searchQuery.isEmpty ? null : IconButton(onPressed: onClearSearch, icon: const Icon(Icons.close)),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: ['Zote', 'Mchele', 'Maharage'].map((filter) {
                    return ChoiceChip(
                      label: Text(filter),
                      selected: selectedCropFilter == filter,
                      onSelected: (_) => onFilterChanged(filter),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
          sliver: SliverList.separated(
            itemCount: filteredMarkets.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final market = filteredMarkets[index];
              return _MarketCard(
                market: market,
                selectedCropFilter: selectedCropFilter,
                onTap: () => onMarketTap(market),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({required this.fullName, required this.role, required this.onProfileTap});

  final String fullName;
  final String role;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      decoration: const BoxDecoration(
        color: Color(0xFF0E7A3B),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset('lib/assets/images/logo.png', width: 44, height: 44),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Mfumo wa Bei', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
              ),
              IconButton(
                onPressed: onProfileTap,
                icon: const Icon(Icons.account_circle_outlined, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Karibu, $fullName', style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 6),
          const Text(
            'Bei za mchele na maharage karibu nawe',
            style: TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w800, height: 1.18),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const _HeaderPill(icon: Icons.place_outlined, text: 'Morogoro'),
              const SizedBox(width: 10),
              const _HeaderPill(icon: Icons.update, text: 'Leo'),
              const SizedBox(width: 10),
              _HeaderPill(icon: Icons.verified_user_outlined, text: role.toUpperCase()),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderPill extends StatelessWidget {
  const _HeaderPill({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(36),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.icon, required this.label, required this.value, required this.trend});

  final IconData icon;
  final String label;
  final String value;
  final String trend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF0E7A3B)),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(trend, style: const TextStyle(color: Color(0xFF0E7A3B), fontWeight: FontWeight.w700, fontSize: 12)),
        ],
      ),
    );
  }
}

class _PermissionActions extends StatelessWidget {
  const _PermissionActions({required this.permissions});

  final Set<String> permissions;

  @override
  Widget build(BuildContext context) {
    final actions = <_ActionItem>[
      if (permissions.contains('users.list'))
        const _ActionItem(icon: Icons.group_outlined, label: 'Watumiaji'),
      if (permissions.contains('markets.create'))
        const _ActionItem(icon: Icons.storefront_outlined, label: 'Soko Jipya'),
      if (permissions.contains('commodities.create'))
        const _ActionItem(icon: Icons.inventory_2_outlined, label: 'Zao Jipya'),
      if (permissions.contains('market_prices.create'))
        const _ActionItem(icon: Icons.add_chart_outlined, label: 'Bei Mpya'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Vitendo vya haraka', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        SizedBox(
          height: 86,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: actions.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) => actions[index],
          ),
        ),
      ],
    );
  }
}

class _ActionItem extends StatelessWidget {
  const _ActionItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 112,
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
          Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
        ],
      ),
    );
  }
}

class _MarketCard extends StatelessWidget {
  const _MarketCard({required this.market, required this.selectedCropFilter, required this.onTap});

  final Map<String, dynamic> market;
  final String selectedCropFilter;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(market['name'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  ),
                  Text(market['distance'], style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
                ],
              ),
              const SizedBox(height: 5),
              Text(market['location'], style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
              const SizedBox(height: 14),
              Row(
                children: [
                  if (selectedCropFilter == 'Zote' || selectedCropFilter == 'Mchele')
                    Expanded(child: _CropPrice(label: 'Mchele', price: market['ricePrice'], trend: market['riceTrend'])),
                  if (selectedCropFilter == 'Zote') const SizedBox(width: 12),
                  if (selectedCropFilter == 'Zote' || selectedCropFilter == 'Maharage')
                    Expanded(child: _CropPrice(label: 'Maharage', price: market['beanPrice'], trend: market['beanTrend'])),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CropPrice extends StatelessWidget {
  const _CropPrice({required this.label, required this.price, required this.trend});

  final String label;
  final int price;
  final String trend;

  @override
  Widget build(BuildContext context) {
    final icon = trend == 'up'
        ? Icons.arrow_upward
        : trend == 'down'
            ? Icons.arrow_downward
            : Icons.trending_flat;
    final color = trend == 'down' ? Colors.red : const Color(0xFF0E7A3B);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(label == 'Mchele' ? Icons.rice_bowl_outlined : Icons.grain_outlined, size: 20, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                Text('TSh $price', style: const TextStyle(fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          Icon(icon, size: 16, color: color),
        ],
      ),
    );
  }
}

class _PricePanel extends StatelessWidget {
  const _PricePanel({required this.label, required this.price, required this.change, required this.icon, required this.color});

  final String label;
  final int price;
  final String change;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 10),
          Text(label, style: const TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w600)),
          Text('TSh $price', style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w800)),
          Text(change, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.label, required this.height});

  final String label;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 46,
          height: height,
          decoration: BoxDecoration(
            color: const Color(0xFF0E7A3B),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
      ],
    );
  }
}

class _SimpleTab extends StatelessWidget {
  const _SimpleTab({required this.icon, required this.title, required this.subtitle});

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: const Color(0xFF0E7A3B)),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF6B7280))),
          ],
        ),
      ),
    );
  }
}

class _AdminTab extends StatelessWidget {
  const _AdminTab({required this.permissions});

  final Set<String> permissions;

  @override
  Widget build(BuildContext context) {
    final items = <_ActionItem>[
      if (permissions.contains('users.list'))
        const _ActionItem(icon: Icons.group_outlined, label: 'Users'),
      if (permissions.contains('roles.list'))
        const _ActionItem(icon: Icons.badge_outlined, label: 'Roles'),
      if (permissions.contains('permissions.list'))
        const _ActionItem(icon: Icons.key_outlined, label: 'Permissions'),
      if (permissions.contains('areas.list'))
        const _ActionItem(icon: Icons.map_outlined, label: 'Areas'),
      if (permissions.contains('markets.list'))
        const _ActionItem(icon: Icons.storefront_outlined, label: 'Markets'),
      if (permissions.contains('commodities.list'))
        const _ActionItem(icon: Icons.inventory_2_outlined, label: 'Commodities'),
    ];

    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
            child: Text('Admin', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
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

class _ProfileLine extends StatelessWidget {
  const _ProfileLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF6B7280)),
        const SizedBox(width: 10),
        Expanded(child: Text(text)),
      ],
    );
  }
}
