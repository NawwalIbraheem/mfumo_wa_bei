import 'package:flutter/material.dart';

import '../../core/layouts/app_shell.dart';
import '../../core/network/api_service.dart';
import '../../core/network/public_api_models.dart';
import '../../core/widgets/searchable_select.dart';
import '../../core/widgets/mfumo_app_bar.dart';
import '../../features/auth/login_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/listings/listings_screen.dart';
import '../../features/main/more_screen.dart';
import '../../features/market_prices/market_prices_screen.dart';
import '../../features/markets/markets_screen.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../features/orders/orders_screen.dart';
import '../../features/users/admin_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  static const routeName = '/main';

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ApiService _apiService = ApiService();

  String selectedCropFilter = 'Zote';
  String searchQuery = '';
  int selectedTab = 0;
  Future<Map<String, dynamic>>? _meFuture;
  late Future<PublicDashboardData> _dashboardFuture;
  Map<String, dynamic>? _routeUser;
  String? _token;
  bool _loadedRouteArgs = false;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _apiService.publicDashboard();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _loadRouteArgs();

    return FutureBuilder<PublicDashboardData>(
      future: _dashboardFuture,
      builder: (context, dashboardSnapshot) {
        final dashboard = dashboardSnapshot.data;
        final marketCards =
            dashboard?.marketCards ?? const <Map<String, dynamic>>[];
        final filteredMarkets = marketCards.where((market) {
          final query = searchQuery.toLowerCase();
          return market['name'].toString().toLowerCase().contains(query) ||
              market['location'].toString().toLowerCase().contains(query);
        }).toList();

        if (dashboardSnapshot.connectionState == ConnectionState.waiting &&
            dashboard == null) {
          return const Scaffold(
            backgroundColor: Color(0xFFF6F7F2),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (dashboardSnapshot.hasError && dashboard == null) {
          return _buildDataError(dashboardSnapshot.error.toString());
        }

        if (_meFuture != null) {
          return FutureBuilder<Map<String, dynamic>>(
            future: _meFuture,
            builder: (context, snapshot) {
              final user = _readUser(snapshot.data) ?? _routeUser;
              final permissions = _readPermissions(snapshot.data ?? user);
              final role = _readRole(user);

              if (snapshot.connectionState == ConnectionState.waiting &&
                  user == null) {
                return const Scaffold(
                  backgroundColor: Color(0xFFF6F7F2),
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError && _routeUser == null) {
                return _buildDataError(snapshot.error.toString());
              }

              return _buildScaffold(
                user: user,
                permissions: permissions,
                role: role,
                filteredMarkets: filteredMarkets,
                dashboard: dashboard!,
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
          dashboard: dashboard!,
        );
      },
    );
  }

  Widget _buildScaffold({
    required Map<String, dynamic>? user,
    required Set<String> permissions,
    required String role,
    required List<Map<String, dynamic>> filteredMarkets,
    required PublicDashboardData dashboard,
  }) {
    final fullName = _displayName(user);
    final isAuthenticated = user != null;
    final canCreateMarketPrice =
        permissions.contains('market_prices.create') ||
        permissions.contains('commodity_prices.create');
    const canSeePriceTools = true;
    final canSeeNotifications = permissions.contains('auth.me');
    final canSeeOrders = permissions.contains('orders.list');
    final canSeeAdmin =
        permissions.contains('users.list') ||
        permissions.contains('roles.list') ||
        permissions.contains('permissions.list');

    final primaryItems = <_MainNavigationItem>[
      _MainNavigationItem(
        destination: const NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Nyumbani',
        ),
        screen: HomeScreen(
          role: role,
          filteredMarkets: filteredMarkets,
          permissions: permissions,
          onMarketTap: _showMarketDetails,
          onRefresh: _refreshData,
        ),
        moreItem: MoreNavigationItem(
          icon: Icons.home_outlined,
          title: 'Nyumbani',
          subtitle: 'Muhtasari wa bei na masoko karibu nawe',
          builder: (_) => HomeScreen(
            role: role,
            filteredMarkets: filteredMarkets,
            permissions: permissions,
            onMarketTap: _showMarketDetails,
            onRefresh: _refreshData,
          ),
        ),
      ),
      _MainNavigationItem(
        destination: const NavigationDestination(
          icon: Icon(Icons.storefront_outlined),
          selectedIcon: Icon(Icons.storefront),
          label: 'Masoko',
        ),
        screen: MarketsScreen(
          markets: filteredMarkets,
          selectedCropFilter: selectedCropFilter,
          searchController: _searchController,
          searchQuery: searchQuery,
          onSearchChanged: (value) => setState(() => searchQuery = value),
          onClearSearch: () {
            setState(() {
              _searchController.clear();
              searchQuery = '';
            });
          },
          onFilterChanged: (value) =>
              setState(() => selectedCropFilter = value),
          onMarketTap: _showMarketDetails,
          onRefresh: _refreshData,
        ),
        moreItem: MoreNavigationItem(
          icon: Icons.storefront_outlined,
          title: 'Masoko',
          subtitle: 'Tafuta na linganisha masoko',
          builder: (_) => MarketsScreen(
            markets: filteredMarkets,
            selectedCropFilter: selectedCropFilter,
            searchController: _searchController,
            searchQuery: searchQuery,
            onSearchChanged: (value) => setState(() => searchQuery = value),
            onClearSearch: () {
              setState(() {
                _searchController.clear();
                searchQuery = '';
              });
            },
            onFilterChanged: (value) =>
                setState(() => selectedCropFilter = value),
            onMarketTap: _showMarketDetails,
            onRefresh: _refreshData,
          ),
        ),
      ),
      if (canSeePriceTools)
        _MainNavigationItem(
          destination: const NavigationDestination(
            icon: Icon(Icons.show_chart),
            label: 'Bei',
          ),
          screen: MarketPricesScreen(
            prices: dashboard.latestCommodityPrices,
            onRefresh: _refreshData,
          ),
          moreItem: MoreNavigationItem(
            icon: Icons.show_chart,
            title: 'Bei',
            subtitle: 'Mwenendo wa bei za mchele na maharage',
            builder: (_) => MarketPricesScreen(
              prices: dashboard.latestCommodityPrices,
              onRefresh: _refreshData,
            ),
          ),
        ),
      const _MainNavigationItem(
        destination: NavigationDestination(
          icon: Icon(Icons.shopping_bag_outlined),
          label: 'Bidhaa',
        ),
        screen: ListingsScreen(),
        moreItem: MoreNavigationItem(
          icon: Icons.shopping_bag_outlined,
          title: 'Bidhaa',
          subtitle: 'Bidhaa zinazopatikana sokoni',
          builder: _buildListingsScreen,
        ),
      ),
      if (canSeeNotifications)
        const _MainNavigationItem(
          destination: NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            label: 'Arifa',
          ),
          screen: NotificationsScreen(),
          moreItem: MoreNavigationItem(
            icon: Icons.notifications_outlined,
            title: 'Arifa',
            subtitle: 'Taarifa za mabadiliko ya bei',
            builder: _buildNotificationsScreen,
          ),
          primary: false,
        ),
      if (canSeeOrders)
        _MainNavigationItem(
          destination: NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            label: 'Oda',
          ),
          screen: OrdersScreen(token: _token ?? '', permissions: permissions),
          moreItem: MoreNavigationItem(
            icon: Icons.receipt_long_outlined,
            title: 'Oda',
            subtitle: 'Oda zinazoonekana kwa akaunti yako',
            builder: (_) =>
                OrdersScreen(token: _token ?? '', permissions: permissions),
          ),
        ),
      if (canSeeAdmin)
        _MainNavigationItem(
          destination: const NavigationDestination(
            icon: Icon(Icons.admin_panel_settings_outlined),
            label: 'Admin',
          ),
          screen: AdminScreen(permissions: permissions, token: _token ?? ''),
          moreItem: MoreNavigationItem(
            icon: Icons.admin_panel_settings_outlined,
            title: 'Admin',
            subtitle: 'Watumiaji, roles na ruhusa',
            builder: (_) =>
                AdminScreen(permissions: permissions, token: _token ?? ''),
          ),
        ),
    ];

    final visibleItems = primaryItems
        .where((item) => item.primary)
        .take(4)
        .toList();
    final overflowItems = [
      ...primaryItems.where((item) => !item.primary),
      ...primaryItems.where((item) => item.primary).skip(4),
    ];
    final destinations = <NavigationDestination>[
      ...visibleItems.map((item) => item.destination),
      const NavigationDestination(
        icon: Icon(Icons.more_horiz),
        selectedIcon: Icon(Icons.more),
        label: 'Zaidi',
      ),
    ];

    final tabs = <Widget>[
      ...visibleItems.map((item) => item.screen),
      MoreScreen(
        extraItems: overflowItems.map((item) => item.moreItem).toList(),
        name: fullName,
        email: user?['email']?.toString() ?? 'Hakuna barua pepe',
        phoneNumber: _readPhoneNumber(user),
        role: role,
        isAuthenticated: isAuthenticated,
        onLogout: () =>
            Navigator.pushReplacementNamed(context, LoginScreen.routeName),
        onLogin: () =>
            Navigator.pushReplacementNamed(context, LoginScreen.routeName),
      ),
    ];

    final safeSelectedTab = selectedTab.clamp(0, tabs.length - 1);
    if (safeSelectedTab != selectedTab) {
      selectedTab = safeSelectedTab;
    }

    return AppShell(
      appBar: MfumoAppBar(
        title: 'Mfumo wa Bei',
        subtitle: 'Karibu, $fullName',
        showLogo: true,
        actions: [
          IconButton(
            tooltip: isAuthenticated ? 'Akaunti' : 'Ingia',
            onPressed: isAuthenticated
                ? () => _showProfileDialog(user)
                : () => Navigator.pushNamed(context, LoginScreen.routeName),
            icon: Icon(
              isAuthenticated
                  ? Icons.account_circle_outlined
                  : Icons.login_outlined,
            ),
          ),
        ],
      ),
      body: IndexedStack(index: safeSelectedTab, children: tabs),
      floatingActionButton: safeSelectedTab == 0 && canCreateMarketPrice
          ? FloatingActionButton.extended(
              onPressed: () => _showReportPriceBottomSheet(dashboard),
              backgroundColor: const Color(0xFF0E7A3B),
              icon: const Icon(Icons.add_chart_outlined, color: Colors.white),
              label: const Text(
                'Ripoti Bei',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
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
    if (args is Map<String, dynamic> &&
        (args.containsKey('user') || args.containsKey('token'))) {
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

  Widget _buildDataError(String message) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F2),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(message, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () {
                    setState(() {
                      _dashboardFuture = _apiService.publicDashboard();
                    });
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Jaribu tena'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _refreshData() async {
    final dashboardFuture = _apiService.publicDashboard();
    final meFuture = _token != null && _token!.isNotEmpty
        ? _apiService.me(token: _token!)
        : null;

    setState(() {
      _dashboardFuture = dashboardFuture;
      if (meFuture != null) {
        _meFuture = meFuture;
      }
    });

    await Future.wait<dynamic>([
      dashboardFuture,
      if (meFuture != null) meFuture,
    ]);
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

  String _readPhoneNumber(Map<String, dynamic>? user) {
    final profile = user?['profile'];
    final phoneNumber = profile is Map<String, dynamic>
        ? profile['phone_number']?.toString()
        : user?['phone_number']?.toString();
    return phoneNumber ?? 'Hakuna namba ya simu';
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
              child: Text(
                _initials(name),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(name, style: const TextStyle(fontSize: 18))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ProfileLine(
              icon: Icons.email_outlined,
              text: user?['email']?.toString() ?? 'Hakuna barua pepe',
            ),
            const SizedBox(height: 12),
            _ProfileLine(
              icon: Icons.phone_outlined,
              text: phoneNumber ?? 'Hakuna namba ya simu',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Funga'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, LoginScreen.routeName);
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
            Text(
              market['name'],
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 18,
                  color: Color(0xFF0E7A3B),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    market['location'],
                    style: const TextStyle(color: Color(0xFF6B7280)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _PricePanel(
                    label: 'Mchele',
                    price: market['ricePrice'],
                    priceLabel: market['ricePriceLabel']?.toString() ?? '-',
                    change: market['riceChange'],
                    icon: Icons.rice_bowl_outlined,
                    color: const Color(0xFF0E7A3B),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PricePanel(
                    label: 'Maharage',
                    price: market['beanPrice'],
                    priceLabel: market['beanPriceLabel']?.toString() ?? '-',
                    change: market['beanChange'],
                    icon: Icons.grain_outlined,
                    color: const Color(0xFFB45309),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Mwenendo wa wiki 4',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
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

  void _showReportPriceBottomSheet(PublicDashboardData dashboard) {
    final token = _token;
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingia kwanza ili kuripoti bei.')),
      );
      return;
    }
    if (dashboard.markets.isEmpty || dashboard.commodities.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masoko au mazao hayajapatikana.')),
      );
      return;
    }

    final minPriceController = TextEditingController();
    final maxPriceController = TextEditingController();
    var selectedMarket = dashboard.markets.first;
    var selectedCommodity = dashboard.commodities.first;
    var isSubmitting = false;

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            8,
            20,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ripoti Bei Mpya',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              const Text(
                'Weka kiwango cha chini na cha juu cha bei uliyoiona sokoni leo.',
                style: TextStyle(color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 18),
              SearchableSelectFormField<CommodityRecord>(
                labelText: 'Zao',
                value: selectedCommodity,
                items: dashboard.commodities,
                itemLabel: (commodity) => commodity.name,
                leadingIcon: Icons.inventory_2_outlined,
                enabled: !isSubmitting,
                searchHintText: 'Tafuta zao...',
                emptyText: 'Hakuna zao lililopatikana.',
                onChanged: (value) => setSheetState(
                  () => selectedCommodity = value ?? selectedCommodity,
                ),
              ),
              const SizedBox(height: 12),
              SearchableSelectFormField<MarketRecord>(
                labelText: 'Soko',
                value: selectedMarket,
                items: dashboard.markets,
                itemLabel: (market) => market.name,
                itemSubtitle: (market) => market.locationLabel,
                leadingIcon: Icons.storefront_outlined,
                enabled: !isSubmitting,
                searchHintText: 'Tafuta soko...',
                emptyText: 'Hakuna soko lililopatikana.',
                onChanged: (value) => setSheetState(
                  () => selectedMarket = value ?? selectedMarket,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: minPriceController,
                enabled: !isSubmitting,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Bei ya chini',
                  prefixText: 'TSh ',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: maxPriceController,
                enabled: !isSubmitting,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Bei ya juu',
                  prefixText: 'TSh ',
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final minPrice = minPriceController.text.trim();
                          final maxPrice = maxPriceController.text.trim();
                          final price = _representativePrice(
                            minPrice,
                            maxPrice,
                          );
                          if (price.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Weka bei ya chini au bei ya juu kabla ya kutuma.',
                                ),
                              ),
                            );
                            return;
                          }
                          setSheetState(() => isSubmitting = true);
                          try {
                            await _apiService.createMarketPrice(
                              token: token,
                              marketId: selectedMarket.id,
                              commodityId: selectedCommodity.id,
                              price: price,
                              minPrice: minPrice,
                              maxPrice: maxPrice,
                              priceDate: DateTime.now()
                                  .toIso8601String()
                                  .split('T')
                                  .first,
                            );
                            if (!mounted ||
                                !context.mounted ||
                                !sheetContext.mounted) {
                              return;
                            }
                            Navigator.pop(sheetContext);
                            setState(() {
                              _dashboardFuture = _apiService.publicDashboard();
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Bei imetumwa kwa mafanikio.'),
                              ),
                            );
                          } on ApiException catch (error) {
                            if (!context.mounted) {
                              return;
                            }
                            setSheetState(() => isSubmitting = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(error.message)),
                            );
                          }
                        },
                  child: Text(isSubmitting ? 'INATUMA...' : 'Tuma Ripoti'),
                ),
              ),
            ],
          ),
        ),
      ),
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

class _PricePanel extends StatelessWidget {
  const _PricePanel({
    required this.label,
    required this.price,
    required this.priceLabel,
    required this.change,
    required this.icon,
    required this.color,
  });

  final String label;
  final int price;
  final String priceLabel;
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
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            priceLabel == '-' ? 'TSh $price' : priceLabel,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            change,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _MainNavigationItem {
  const _MainNavigationItem({
    required this.destination,
    required this.screen,
    required this.moreItem,
    this.primary = true,
  });

  final NavigationDestination destination;
  final Widget screen;
  final MoreNavigationItem moreItem;
  final bool primary;
}

Widget _buildListingsScreen(BuildContext context) {
  return const Scaffold(body: ListingsScreen());
}

Widget _buildNotificationsScreen(BuildContext context) {
  return const Scaffold(body: NotificationsScreen());
}

String _representativePrice(String minPrice, String maxPrice) {
  final minValue = double.tryParse(minPrice.replaceAll(',', '').trim());
  final maxValue = double.tryParse(maxPrice.replaceAll(',', '').trim());
  if (minValue != null && maxValue != null) {
    return ((minValue + maxValue) / 2).round().toString();
  }
  return (minValue ?? maxValue)?.round().toString() ?? '';
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
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
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
