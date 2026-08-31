import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/network/api_service.dart';
import '../../core/network/public_api_models.dart';
import '../../core/widgets/app_avatar.dart';
import '../../core/widgets/listing_card.dart';
import '../auth/login_screen.dart';
import '../orders/order_payment_sheet.dart';
import 'listing_form_screen.dart';

part 'market_detail_screen.dart';

enum _MarketTab { allMarket, myListings, systemListings }

class MarketScreen extends StatefulWidget {
  const MarketScreen({
    super.key,
    this.token = '',
    this.permissions = const <String>{},
    this.dashboard,
    this.currentUserId,
    this.userPhoneNumber,
  });

  final String token;
  final Set<String> permissions;
  final PublicDashboardData? dashboard;
  final String? currentUserId;
  final String? userPhoneNumber;

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  static const int _pageSize = 10;

  final ApiService _apiService = ApiService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _listings = [];
  int _page = 0;
  int _totalItems = 0;
  bool _hasNext = true;
  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;

  // Filter states
  _MarketTab _activeTab = _MarketTab.allMarket;
  String _searchQuery = '';
  String? _selectedCommodityId;
  String? _selectedAreaId;
  String? _selectedAreaName;
  String _priceRange = 'any'; // any, under-50k, 50k-150k, over-150k
  String _sortBy = 'recommended'; // recommended, price-asc, price-desc, newest

  List<Map<String, dynamic>> _commodities = [];
  List<Map<String, dynamic>> _areas = [];

  bool get _isLoggedIn => widget.token.isNotEmpty;
  bool get _isAdmin =>
      widget.permissions.contains('users.list') ||
      widget.permissions.contains('roles.list') ||
      widget.permissions.contains('listings.delete');
  bool get _canCreateListing =>
      widget.permissions.contains('listings.create') || _isLoggedIn;
  bool get _canUpdateListing => widget.permissions.contains('listings.update');
  bool get _canDeleteListing => widget.permissions.contains('listings.delete');
  bool get _canCreateOrder =>
      widget.permissions.contains('orders.create') || _isLoggedIn;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    _loadCatalogs();
    _loadInitial();
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCatalogs() async {
    try {
      final results = await Future.wait([
        _loadCommoditiesList(),
        _apiService.publicList('/areas'),
      ]);
      if (mounted) {
        setState(() {
          _commodities = results[0];
          _areas = results[1];
        });
      }
    } catch (_) {}
  }

  Future<List<Map<String, dynamic>>> _loadCommoditiesList() async {
    final dashboardCommodities = widget.dashboard?.commodities;
    if (dashboardCommodities != null && dashboardCommodities.isNotEmpty) {
      return dashboardCommodities
          .map(
            (c) => {
              'commodity_id': c.id,
              'name': c.name,
              'unit': c.unit,
            },
          )
          .toList();
    }
    return _apiService.publicList('/commodities');
  }

  Future<void> _refresh() async {
    await _loadInitial();
  }

  Future<void> _loadInitial() async {
    setState(() {
      _isInitialLoading = true;
      _isLoadingMore = false;
      _errorMessage = null;
      _page = 0;
      _totalItems = 0;
      _hasNext = true;
      _listings.clear();
    });

    await _loadPage(1, replace: true);
  }

  Future<void> _loadMore() async {
    if (_isInitialLoading || _isLoadingMore || !_hasNext) return;
    await _loadPage(_page + 1);
  }

  Future<void> _loadPage(int page, {bool replace = false}) async {
    setState(() {
      if (replace) {
        _isInitialLoading = true;
      } else {
        _isLoadingMore = true;
      }
      _errorMessage = null;
    });

    double? minPrice;
    double? maxPrice;
    if (_priceRange == 'under-50k') {
      maxPrice = 49999;
    } else if (_priceRange == '50k-150k') {
      minPrice = 50000;
      maxPrice = 150000;
    } else if (_priceRange == 'over-150k') {
      minPrice = 150001;
    }

    String? ordering;
    if (_sortBy == 'price-asc') {
      ordering = 'price';
    } else if (_sortBy == 'price-desc') {
      ordering = '-price';
    } else if (_sortBy == 'newest') {
      ordering = '-created_at';
    }

    String? statusFilter;
    if (_activeTab == _MarketTab.allMarket) {
      statusFilter = 'available';
    }

    try {
      final response = await _apiService.listCommodityListings(
        commodityId: _selectedCommodityId,
        areaId: _selectedAreaId,
        status: statusFilter,
        minPrice: minPrice,
        maxPrice: maxPrice,
        ordering: ordering,
        search: _searchQuery.trim().isEmpty ? null : _searchQuery.trim(),
        page: page,
        pageSize: _pageSize,
        token: widget.token.isEmpty ? null : widget.token,
      );

      if (!mounted) return;

      var items = response.items;
      // Client-side filter for "myListings" if API doesn't filter by seller
      if (_activeTab == _MarketTab.myListings && widget.currentUserId != null) {
        items = items.where((item) {
          final sellerId = readNested(item, 'seller_id');
          final sellerUserId = readNested(item, 'seller.user_id');
          return sellerId == widget.currentUserId ||
              sellerUserId == widget.currentUserId;
        }).toList();
      }

      setState(() {
        if (replace) {
          _listings
            ..clear()
            ..addAll(items);
        } else {
          _listings.addAll(items);
        }
        _page = response.page;
        _totalItems = response.totalItems > 0 ? response.totalItems : _listings.length;
        _hasNext = response.hasNext && response.page < response.totalPages;
        _isInitialLoading = false;
        _isLoadingMore = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message;
        _isInitialLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Imeshindikana kupakia orodha ya bidhaa.';
        _isInitialLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  void _handleScroll() {
    if (!_scrollController.hasClients || !_hasNext) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 320) {
      _loadMore();
    }
  }

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _selectedCommodityId = null;
      _selectedAreaId = null;
      _selectedAreaName = null;
      _priceRange = 'any';
      _sortBy = 'recommended';
    });
    _loadInitial();
  }

  bool get _hasActiveFilters =>
      _searchQuery.isNotEmpty ||
      _selectedCommodityId != null ||
      _selectedAreaId != null ||
      _priceRange != 'any' ||
      _sortBy != 'recommended';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: _canCreateListing
          ? FloatingActionButton.extended(
              onPressed: _createListing,
              backgroundColor: const Color(0xFF0E7A3B),
              icon: const Icon(Icons.add_business_outlined, color: Colors.white),
              label: const Text(
                'Weka Bidhaa',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          : null,
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Optional Tabs for authenticated users/admins
          if (_isLoggedIn)
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  children: [
                    _buildTabButton(
                      tab: _MarketTab.allMarket,
                      label: 'Soko (Marketplace)',
                      icon: Icons.storefront_outlined,
                    ),
                    const SizedBox(width: 8),
                    _buildTabButton(
                      tab: _MarketTab.myListings,
                      label: 'Bidhaa Zangu',
                      icon: Icons.inventory_outlined,
                    ),
                    if (_isAdmin) ...[
                      const SizedBox(width: 8),
                      _buildTabButton(
                        tab: _MarketTab.systemListings,
                        label: 'Zote (Admin)',
                        icon: Icons.admin_panel_settings_outlined,
                      ),
                    ],
                  ],
                ),
              ),
            ),

          // Search & Filter Header
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search Bar
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Tafuta bidhaa au zao...',
                            prefixIcon: const Icon(Icons.search, size: 20),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                      _loadInitial();
                                    },
                                  )
                                : null,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF7FAF8),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE5EBE7)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE5EBE7)),
                            ),
                          ),
                          onSubmitted: (value) {
                            setState(() => _searchQuery = value);
                            _loadInitial();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.outlined(
                        tooltip: 'Chuja / Filters',
                        icon: Icon(
                          Icons.tune,
                          color: _hasActiveFilters
                              ? const Color(0xFF0E7A3B)
                              : const Color(0xFF66736B),
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: _hasActiveFilters
                              ? const Color(0xFFE8F5E9)
                              : Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _showFilterModal,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Quick Area Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildQuickAreaChip(
                          label: 'Tanzania Zote',
                          areaId: null,
                          isSelected: _selectedAreaId == null,
                        ),
                        const SizedBox(width: 6),
                        _buildQuickAreaChip(
                          label: 'Morogoro',
                          areaId: _findAreaIdByName('Morogoro'),
                          isSelected: _selectedAreaName == 'Morogoro',
                        ),
                        const SizedBox(width: 6),
                        _buildQuickAreaChip(
                          label: 'Dar es Salaam',
                          areaId: _findAreaIdByName('Dar es Salaam'),
                          isSelected: _selectedAreaName == 'Dar es Salaam',
                        ),
                        const SizedBox(width: 6),
                        _buildQuickAreaChip(
                          label: 'Mbeya',
                          areaId: _findAreaIdByName('Mbeya'),
                          isSelected: _selectedAreaName == 'Mbeya',
                        ),
                        const SizedBox(width: 6),
                        _buildQuickAreaChip(
                          label: 'Arusha',
                          areaId: _findAreaIdByName('Arusha'),
                          isSelected: _selectedAreaName == 'Arusha',
                        ),
                        const SizedBox(width: 6),
                        _buildQuickAreaChip(
                          label: 'Dodoma',
                          areaId: _findAreaIdByName('Dodoma'),
                          isSelected: _selectedAreaName == 'Dodoma',
                        ),
                      ],
                    ),
                  ),

                  // Results count & reset
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Bidhaa $_totalItems zimepatikana',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF66736B),
                          ),
                        ),
                        if (_hasActiveFilters)
                          GestureDetector(
                            onTap: _resetFilters,
                            child: const Text(
                              'Safisha Vichujio',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0E7A3B),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Main Listings List
          if (_isInitialLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_errorMessage != null && _listings.isEmpty)
            SliverFillRemaining(
              child: _ErrorState(
                message: _errorMessage!,
                onRetry: _loadInitial,
              ),
            )
          else if (_listings.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.shopping_bag_outlined,
                        size: 64,
                        color: Color(0xFFB0BEC5),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Hakuna bidhaa zilizopatikana',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF17221B),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Jaribu kubadilisha vigezo vya utafutaji au eneo.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF66736B),
                        ),
                      ),
                      if (_hasActiveFilters) ...[
                        const SizedBox(height: 16),
                        OutlinedButton(
                          onPressed: _resetFilters,
                          child: const Text('Ondoa Vichujio'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index >= _listings.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final listing = _listings[index];
                    final isOwn = _checkIfOwnListing(listing);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ListingCard(
                        listing: listing,
                        isOwnListing: isOwn,
                        onTap: () => _showListingDetails(listing),
                        onBuyNow: isOwn
                            ? null
                            : () => _quickBuyListing(listing),
                      ),
                    );
                  },
                  childCount: _listings.length + (_isLoadingMore ? 1 : 0),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required _MarketTab tab,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _activeTab == tab;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_activeTab != tab) {
            setState(() => _activeTab = tab);
            _loadInitial();
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFE8F5E9) : const Color(0xFFF7FAF8),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? const Color(0xFF0E7A3B) : const Color(0xFFE5EBE7),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected ? const Color(0xFF0E7A3B) : const Color(0xFF66736B),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected ? const Color(0xFF0E7A3B) : const Color(0xFF66736B),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAreaChip({
    required String label,
    required String? areaId,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedAreaId = areaId;
          _selectedAreaName = areaId == null ? null : label;
        });
        _loadInitial();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0E7A3B) : const Color(0xFFF0F4F1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF17221B),
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  String? _findAreaIdByName(String name) {
    for (final a in _areas) {
      if (a['name']?.toString().toLowerCase() == name.toLowerCase()) {
        return a['area_id']?.toString();
      }
    }
    return null;
  }

  bool _checkIfOwnListing(Map<String, dynamic> listing) {
    if (widget.currentUserId == null || widget.currentUserId!.isEmpty) {
      return false;
    }
    final sellerId = readNested(listing, 'seller_id');
    final sellerUserId = readNested(listing, 'seller.user_id');
    return sellerId == widget.currentUserId ||
        sellerUserId == widget.currentUserId;
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            8,
            20,
            MediaQuery.of(context).viewInsets.bottom + 28,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Chuja Bidhaa (Filters)',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  TextButton(
                    onPressed: () {
                      setSheetState(() {
                        _selectedCommodityId = null;
                        _selectedAreaId = null;
                        _selectedAreaName = null;
                        _priceRange = 'any';
                        _sortBy = 'recommended';
                      });
                    },
                    child: const Text('Rudisha / Reset'),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Commodity filter
              const Text(
                'Zao (Commodity Type)',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _selectedCommodityId,
                decoration: InputDecoration(
                  hintText: 'Mazao yote',
                  prefixIcon: const Icon(Icons.inventory_2_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Mazao Yote')),
                  ..._commodities.map(
                    (c) => DropdownMenuItem(
                      value: c['commodity_id']?.toString(),
                      child: Text(c['name']?.toString() ?? ''),
                    ),
                  ),
                ],
                onChanged: (val) => setSheetState(() => _selectedCommodityId = val),
              ),
              const SizedBox(height: 14),

              // Price range filter
              const Text(
                'Kiwango cha Bei (TZS)',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _priceRange,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.payments_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'any', child: Text('Bei Yoyote')),
                  DropdownMenuItem(
                    value: 'under-50k',
                    child: Text('Chini ya TSh 50,000'),
                  ),
                  DropdownMenuItem(
                    value: '50k-150k',
                    child: Text('TSh 50,000 - 150,000'),
                  ),
                  DropdownMenuItem(
                    value: 'over-150k',
                    child: Text('Zaidi ya TSh 150,000'),
                  ),
                ],
                onChanged: (val) => setSheetState(
                  () => _priceRange = val ?? 'any',
                ),
              ),
              const SizedBox(height: 14),

              // Sort filter
              const Text(
                'Panga Kwa (Sort By)',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _sortBy,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.sort_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'recommended',
                    child: Text('Inayopendekezwa (Recommended)'),
                  ),
                  DropdownMenuItem(
                    value: 'newest',
                    child: Text('Mpya Zaidi (Newest)'),
                  ),
                  DropdownMenuItem(
                    value: 'price-asc',
                    child: Text('Bei: Chini kwenda Juu'),
                  ),
                  DropdownMenuItem(
                    value: 'price-desc',
                    child: Text('Bei: Juu kwenda Chini'),
                  ),
                ],
                onChanged: (val) => setSheetState(
                  () => _sortBy = val ?? 'recommended',
                ),
              ),
              const SizedBox(height: 20),

              // Apply button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    setState(() {});
                    _loadInitial();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0E7A3B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Tumia Vichujio',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createListing() async {
    final changed = await ListingFormScreen.show(
      context,
      token: widget.token,
      dashboard: widget.dashboard,
    );
    if (changed == true && mounted) {
      _loadInitial();
    }
  }

  Future<void> _showListingDetails(Map<String, dynamic> listing) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => MarketDetailScreen(
          listing: listing,
          token: widget.token,
          dashboard: widget.dashboard,
          currentUserId: widget.currentUserId,
          userPhoneNumber: widget.userPhoneNumber,
          canCreateOrder: _canCreateOrder,
          canUpdateListing: _canUpdateListing,
          canDeleteListing: _canDeleteListing,
        ),
      ),
    );
    if (changed == true && mounted) {
      _loadInitial();
    }
  }

  Future<void> _quickBuyListing(Map<String, dynamic> listing) async {
    if (!_isLoggedIn) {
      Navigator.pushNamed(context, LoginScreen.routeName);
      return;
    }

    final listingId = listing['listing_id']?.toString();
    if (listingId == null || listingId.isEmpty) return;

    final unit = readNested(listing, 'commodity.unit', fallback: 'unit');
    final priceStr = readNested(listing, 'price');
    final unitPrice = double.tryParse(priceStr.replaceAll(',', '')) ?? 0;
    final stockStr = readNested(listing, 'quantity');
    final stock = double.tryParse(stockStr.replaceAll(',', '')) ?? 0;

    final quantityController = TextEditingController(text: '1');

    final placed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          final qty = double.tryParse(quantityController.text.trim()) ?? 0;
          final total = qty * unitPrice;

          return Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              8,
              20,
              MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Nunua Sasa (Weka Oda)',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                Text(
                  listingTitle(listing),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'Bei: TSh ${_formatPrice(unitPrice.toString())} / $unit • Upeo: $stock $unit',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF66736B)),
                ),
                const SizedBox(height: 16),

                // Quantity Input
                TextFormField(
                  controller: quantityController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Kiasi cha kuagiza ($unit)',
                    prefixIcon: const Icon(Icons.scale_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (_) => setSheetState(() {}),
                ),
                const SizedBox(height: 12),

                // Total display
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Jumla ya Malipo:',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'TSh ${_formatPrice(total.toString())}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0E7A3B),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                FilledButton.icon(
                  onPressed: qty <= 0 || qty > stock
                      ? null
                      : () async {
                          try {
                            final response = await _apiService.createOrder(
                              token: widget.token,
                              listingId: listingId,
                              quantity: quantityController.text.trim(),
                            );
                            final orderId = response['order_id']?.toString() ??
                                (response['order'] is Map<String, dynamic>
                                    ? response['order']['order_id']?.toString()
                                    : null);
                            if (orderId == null || orderId.isEmpty) {
                              throw ApiException('Oda imewekwa lakini taarifa hazijapatikana.');
                            }

                            if (!sheetContext.mounted) return;
                            Navigator.pop(sheetContext, true);

                            // Open payment sheet
                            await OrderPaymentSheet.show(
                              context,
                              token: widget.token,
                              orderId: orderId,
                              totalAmount: total.toString(),
                              initialPhoneNumber: widget.userPhoneNumber,
                              listingTitle: listingTitle(listing),
                            );
                          } on ApiException catch (error) {
                            if (!sheetContext.mounted) return;
                            ScaffoldMessenger.of(sheetContext).showSnackBar(
                              SnackBar(
                                content: Text(error.message),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          }
                        },
                  icon: const Icon(Icons.shopping_cart_checkout_outlined),
                  label: const Text(
                    'Endelea na Malipo',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0E7A3B),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    if (placed == true && mounted) {
      _loadInitial();
    }
  }
}

class _SellerHeader extends StatelessWidget {
  const _SellerHeader({required this.listing});

  final Map<String, dynamic> listing;

  @override
  Widget build(BuildContext context) {
    final sellerName = sellerDisplay(listing);
    final phone = readNested(listing, 'seller.phone_number');
    final email = readNested(listing, 'seller.email');

    return Row(
      children: [
        AppAvatar(
          imageUrl: readNested(listing, 'seller.avatar_url'),
          initials: _sellerInitials(sellerName),
          icon: Icons.person_outline,
          size: 56,
          borderRadius: BorderRadius.circular(10),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                sellerName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: Color(0xFF17221B),
                ),
              ),
              if (phone.isNotEmpty) ...[
                const SizedBox(height: 4),
                _SellerContactLine(
                  icon: Icons.phone_outlined,
                  text: phone,
                  uri: Uri(scheme: 'tel', path: phone),
                ),
              ],
              if (email.isNotEmpty) ...[
                const SizedBox(height: 3),
                _SellerContactLine(
                  icon: Icons.email_outlined,
                  text: email,
                  uri: Uri(scheme: 'mailto', path: email),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SellerContactLine extends StatelessWidget {
  const _SellerContactLine({
    required this.icon,
    required this.text,
    required this.uri,
  });

  final IconData icon;
  final String text;
  final Uri uri;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _launchContactUri(context),
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Icon(icon, size: 13, color: const Color(0xFF0E7A3B)),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF0E7A3B),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchContactUri(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Imeshindikana kufungua programu husika.'),
        ),
      );
    }
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        SizedBox(height: MediaQuery.sizeOf(context).height * 0.25),
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        Center(
          child: FilledButton.icon(
            onPressed: () => onRetry(),
            icon: const Icon(Icons.refresh),
            label: const Text('Jaribu tena'),
          ),
        ),
      ],
    );
  }
}

String _sellerInitials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '';
  if (parts.length == 1) return parts.first.characters.first;
  return '${parts.first.characters.first}${parts.last.characters.first}';
}

String _relativeTime(String rawDate) {
  final date = DateTime.tryParse(rawDate);
  if (date == null) return '-';
  final postedAt = date.isUtc ? date.toLocal() : date;
  final difference = DateTime.now().difference(postedAt);
  if (difference.inSeconds < 60) return 'sasa hivi';
  if (difference.inMinutes < 60) return 'dakika ${difference.inMinutes} zilizopita';
  if (difference.inHours < 24) return 'masaa ${difference.inHours} yaliyopita';
  if (difference.inDays < 7) return 'siku ${difference.inDays} zilizopita';
  if (difference.inDays < 30) return 'wiki ${difference.inDays ~/ 7} zilizopita';
  if (difference.inDays < 365) return 'miezi ${difference.inDays ~/ 30} iliyopita';
  return 'mwaka ${difference.inDays ~/ 365} uliopita';
}

String _relativeTimeAgo(String rawDate) {
  return _relativeTime(rawDate);
}
