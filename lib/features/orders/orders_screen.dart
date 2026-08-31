import 'package:flutter/material.dart';

import '../../core/network/api_service.dart';
import '../../core/widgets/app_avatar.dart';
import '../../core/widgets/listing_card.dart';
import 'order_payment_sheet.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({
    super.key,
    required this.token,
    required this.permissions,
    this.userPhoneNumber,
  });

  final String token;
  final Set<String> permissions;
  final String? userPhoneNumber;

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  String _scope = 'placed'; // 'placed' (buyer purchases) or 'received' (seller sales)
  String? _statusFilter;
  String _searchQuery = '';

  int _page = 1;
  int _totalPages = 1;
  int _totalItems = 0;
  bool _hasNext = false;
  bool _isLoading = true;
  String? _errorMessage;
  String? _noticeMessage;

  int _placedCount = 0;
  int _receivedCount = 0;

  final List<Map<String, dynamic>> _orders = [];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders({bool resetPage = false}) async {
    if (resetPage) {
      _page = 1;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _apiService.listOrders(
        token: widget.token,
        scope: _scope,
        status: _statusFilter,
        search: _searchQuery.trim().isEmpty ? null : _searchQuery.trim(),
        page: _page,
        pageSize: 10,
      );

      if (!mounted) return;

      setState(() {
        _orders
          ..clear()
          ..addAll(response.items);
        _page = response.page;
        _totalPages = response.totalPages;
        _totalItems = response.totalItems;
        _hasNext = response.hasNext;
        _placedCount = response.counts['placed'] ?? _placedCount;
        _receivedCount = response.counts['received'] ?? _receivedCount;
        _isLoading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Imeshindikana kupakia oda.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF8),
      body: SafeArea(
        child: Column(
          children: [
            // Tabs Bar: Purchases (Placed) vs Sales (Received)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  _buildScopeTab(
                    scope: 'placed',
                    label: 'Ununuzi (Placed)',
                    count: _placedCount,
                    icon: Icons.shopping_bag_outlined,
                  ),
                  const SizedBox(width: 8),
                  _buildScopeTab(
                    scope: 'received',
                    label: 'Mauzo (Received)',
                    count: _receivedCount,
                    icon: Icons.storefront_outlined,
                  ),
                ],
              ),
            ),

            // Notice / Error Banner
            if (_noticeMessage != null)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFC8E6C9)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Color(0xFF0E7A3B), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _noticeMessage!,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0E7A3B),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => setState(() => _noticeMessage = null),
                    ),
                  ],
                ),
              ),

            // Search and Status Filters
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Tafuta kwa namba au zao...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                  _loadOrders(resetPage: true);
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF7FAF8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFFE5EBE7)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFFE5EBE7)),
                        ),
                      ),
                      onSubmitted: (val) {
                        setState(() => _searchQuery = val);
                        _loadOrders(resetPage: true);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  DropdownButtonHideUnderline(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7FAF8),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE5EBE7)),
                      ),
                      child: DropdownButton<String?>(
                        value: _statusFilter,
                        hint: const Text('Hali Zote', style: TextStyle(fontSize: 12)),
                        icon: const Icon(Icons.arrow_drop_down, size: 20),
                        items: const [
                          DropdownMenuItem(value: null, child: Text('Hali Zote', style: TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: 'awaiting_payment', child: Text('Inasubiri Malipo', style: TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: 'payment_processing', child: Text('Inachakatwa', style: TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: 'paid', child: Text('Imelipwa', style: TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: 'payment_review', child: Text('Inakaguliwa', style: TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: 'confirmed', child: Text('Imethibitishwa', style: TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: 'completed', child: Text('Imekamilika', style: TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: 'cancelled', child: Text('Imeghairiwa', style: TextStyle(fontSize: 12))),
                        ],
                        onChanged: (val) {
                          setState(() => _statusFilter = val);
                          _loadOrders(resetPage: true);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Orders list or state views
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => _loadOrders(resetPage: true),
                child: _buildOrdersList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScopeTab({
    required String scope,
    required String label,
    required int count,
    required IconData icon,
  }) {
    final isSelected = _scope == scope;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_scope != scope) {
            setState(() {
              _scope = scope;
              _statusFilter = null;
            });
            _loadOrders(resetPage: true);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFE8F5E9) : const Color(0xFFF7FAF8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? const Color(0xFF0E7A3B) : const Color(0xFFE5EBE7),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? const Color(0xFF0E7A3B) : const Color(0xFF66736B),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected ? const Color(0xFF0E7A3B) : const Color(0xFF66736B),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF0E7A3B) : const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? Colors.white : const Color(0xFF66736B),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrdersList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => _loadOrders(resetPage: true),
                icon: const Icon(Icons.refresh),
                label: const Text('Jaribu Tena'),
              ),
            ],
          ),
        ),
      );
    }

    if (_orders.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          SizedBox(height: MediaQuery.sizeOf(context).height * 0.2),
          const Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: Color(0xFFB0BEC5),
          ),
          const SizedBox(height: 12),
          Text(
            _scope == 'placed' ? 'Huna oda ulizoweka' : 'Huna oda zilizopokelewa',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF17221B),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _scope == 'placed'
                ? 'Nenda kwenye ukurasa wa Bidhaa ili kuchagua na kuagiza bidhaa.'
                : 'Oda zitakazotumwa na wanunuzi zitaonekana hapa.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Color(0xFF66736B)),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
      itemCount: _orders.length + (_totalPages > 1 ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        if (index >= _orders.length) {
          return _buildPaginationBar();
        }
        final order = _orders[index];
        return _OrderCard(
          order: order,
          isPlacedTab: _scope == 'placed',
          onTap: () => _openOrderDetail(order),
        );
      },
    );
  }

  Widget _buildPaginationBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Ukurasa $_page wa $_totalPages ($_totalItems oda)',
            style: const TextStyle(fontSize: 12, color: Color(0xFF66736B), fontWeight: FontWeight.w600),
          ),
          Row(
            children: [
              IconButton.outlined(
                onPressed: _page > 1
                    ? () {
                        setState(() => _page--);
                        _loadOrders();
                      }
                    : null,
                icon: const Icon(Icons.chevron_left, size: 18),
              ),
              const SizedBox(width: 8),
              IconButton.outlined(
                onPressed: _hasNext
                    ? () {
                        setState(() => _page++);
                        _loadOrders();
                      }
                    : null,
                icon: const Icon(Icons.chevron_right, size: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openOrderDetail(Map<String, dynamic> order) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _OrderDetailSheet(
        order: order,
        token: widget.token,
        isPlacedTab: _scope == 'placed',
        userPhoneNumber: widget.userPhoneNumber,
      ),
    );

    if (changed == true && mounted) {
      _loadOrders();
    }
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.isPlacedTab,
    required this.onTap,
  });

  final Map<String, dynamic> order;
  final bool isPlacedTab;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final orderId = order['order_id']?.toString() ?? '-';
    final listingTitle = readNested(order, 'listing.title', fallback: readNested(order, 'listing.commodity.name', fallback: 'Bidhaa'));
    final commodityName = readNested(order, 'listing.commodity.name', fallback: 'Zao');
    final unit = readNested(order, 'listing.commodity.unit', fallback: 'unit');
    final quantity = order['quantity']?.toString() ?? '-';
    final totalPrice = order['total_price']?.toString() ?? '-';
    final status = order['status']?.toString() ?? 'pending';
    final listing = order['listing'];
    final otherUser = isPlacedTab
        ? (listing is Map<String, dynamic> ? listing['seller'] : null)
        : order['buyer'];
    final otherName = otherUser is Map<String, dynamic>
        ? (otherUser['full_name'] ?? otherUser['username'] ?? 'Mtumiaji')
        : 'Mtumiaji';
    final otherAvatar = otherUser is Map<String, dynamic> ? otherUser['avatar_url']?.toString() : null;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5EBE7)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x06000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: Order ID & Status Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.receipt_outlined, size: 14, color: Color(0xFF66736B)),
                      const SizedBox(width: 4),
                      Text(
                        '#$orderId',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF17221B),
                        ),
                      ),
                    ],
                  ),
                  _OrderStatusBadge(status: status),
                ],
              ),
              const SizedBox(height: 8),

              // Title and Commodity badge
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      commodityName,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0E7A3B),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      listingTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF17221B),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Divider
              const Divider(height: 1, color: Color(0xFFF0F4F1)),
              const SizedBox(height: 10),

              // Bottom details row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Other party info
                  Row(
                    children: [
                      AppAvatar(
                        imageUrl: otherAvatar,
                        initials: _initials(otherName.toString()),
                        size: 28,
                        icon: Icons.person_outline,
                      ),
                      const SizedBox(width: 6),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isPlacedTab ? 'Muuzaji:' : 'Mnunuzi:',
                            style: const TextStyle(fontSize: 10, color: Color(0xFF66736B)),
                          ),
                          Text(
                            otherName.toString(),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Quantity & Total Price
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$quantity $unit',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF66736B)),
                      ),
                      Text(
                        'TSh ${_formatPrice(totalPrice)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0E7A3B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderDetailSheet extends StatefulWidget {
  const _OrderDetailSheet({
    required this.order,
    required this.token,
    required this.isPlacedTab,
    this.userPhoneNumber,
  });

  final Map<String, dynamic> order;
  final String token;
  final bool isPlacedTab;
  final String? userPhoneNumber;

  @override
  State<_OrderDetailSheet> createState() => _OrderDetailSheetState();
}

class _OrderDetailSheetState extends State<_OrderDetailSheet> {
  final ApiService _apiService = ApiService();
  bool _busy = false;

  Future<void> _updateStatus(String newStatus) async {
    final orderId = widget.order['order_id']?.toString();
    if (orderId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Thibitisha $newStatus?'),
        content: Text('Je, una uhakika unataka kubadilisha hali ya oda kuwa "$newStatus"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Ghairi')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0E7A3B)),
            child: const Text('Thibitisha'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _busy = true);
    try {
      await _apiService.updateOrderStatus(
        token: widget.token,
        orderId: orderId,
        status: newStatus,
      );
      if (mounted) {
        Navigator.pop(context, true);
      }
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message), backgroundColor: Colors.redAccent),
      );
    }
  }

  Future<void> _proceedToPay() async {
    final orderId = widget.order['order_id']?.toString();
    final totalPrice = widget.order['total_price']?.toString() ?? '0';
    final listingTitle = readNested(widget.order, 'listing.title', fallback: 'Bidhaa');
    if (orderId == null) return;

    final paid = await OrderPaymentSheet.show(
      context,
      token: widget.token,
      orderId: orderId,
      totalAmount: totalPrice,
      initialPhoneNumber: widget.userPhoneNumber,
      listingTitle: listingTitle,
    );

    if (paid == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final orderId = order['order_id']?.toString() ?? '-';
    final listingTitle = readNested(order, 'listing.title', fallback: readNested(order, 'listing.commodity.name', fallback: 'Bidhaa'));
    final commodity = readNested(order, 'listing.commodity.name', fallback: '-');
    final unit = readNested(order, 'listing.commodity.unit', fallback: 'unit');
    final price = readNested(order, 'listing.price', fallback: '0');
    final quantity = order['quantity']?.toString() ?? '-';
    final totalPrice = order['total_price']?.toString() ?? '-';
    final status = order['status']?.toString() ?? 'pending';
    final createdAt = order['created_at']?.toString() ?? '';

    final buyer = order['buyer'];
    final seller = order['listing']?['seller'];

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        8,
        20,
        MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Maelezo ya Oda',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              _OrderStatusBadge(status: status),
            ],
          ),
          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF7FAF8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5EBE7)),
            ),
            child: Column(
              children: [
                _buildDetailRow('Namba ya Oda:', '#$orderId'),
                const Divider(height: 16, color: Color(0xFFE5EBE7)),
                _buildDetailRow('Bidhaa:', listingTitle),
                const Divider(height: 16, color: Color(0xFFE5EBE7)),
                _buildDetailRow('Zao:', commodity),
                const Divider(height: 16, color: Color(0xFFE5EBE7)),
                _buildDetailRow('Bei kwa Kipimo:', 'TSh ${_formatPrice(price)} / $unit'),
                const Divider(height: 16, color: Color(0xFFE5EBE7)),
                _buildDetailRow('Kiasi Kilichoagizwa:', '$quantity $unit'),
                const Divider(height: 16, color: Color(0xFFE5EBE7)),
                _buildDetailRow(
                  'Jumla ya Malipo:',
                  'TSh ${_formatPrice(totalPrice)}',
                  isHighlighted: true,
                ),
                if (createdAt.isNotEmpty) ...[
                  const Divider(height: 16, color: Color(0xFFE5EBE7)),
                  _buildDetailRow('Tarehe ya Oda:', _formatDate(createdAt)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Buyer/Seller Contact info
          if (widget.isPlacedTab && seller is Map<String, dynamic>) ...[
            const Text(
              'MUUZAJI (SELLER)',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF66736B)),
            ),
            const SizedBox(height: 6),
            _buildPartyTile(seller),
          ] else if (!widget.isPlacedTab && buyer is Map<String, dynamic>) ...[
            const Text(
              'MNUNUZI (BUYER)',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF66736B)),
            ),
            const SizedBox(height: 6),
            _buildPartyTile(buyer),
          ],
          const SizedBox(height: 20),

          // Action Buttons based on status and role
          if (widget.isPlacedTab) ...[
            // Buyer view
            if (status == 'awaiting_payment' || status == 'pending') ...[
              FilledButton.icon(
                onPressed: _busy ? null : _proceedToPay,
                icon: const Icon(Icons.payment_outlined),
                label: const Text('Lipa Sasa kwa Simu (Pay Now)'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0E7A3B),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: _busy ? null : () => _updateStatus('cancelled'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Ghairi Oda (Cancel)'),
              ),
            ],
          ] else ...[
            // Seller view
            if (status == 'pending') ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _busy ? null : () => _updateStatus('cancelled'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Kataa (Reject)'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: _busy ? null : () => _updateStatus('accepted'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF0E7A3B),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Kubali (Accept)'),
                    ),
                  ),
                ],
              ),
            ] else if (status == 'accepted' || status == 'paid' || status == 'confirmed') ...[
              FilledButton(
                onPressed: _busy ? null : () => _updateStatus('completed'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0E7A3B),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Kamilisha Oda (Mark Completed)'),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isHighlighted = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: const Color(0xFF66736B),
            fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: isHighlighted ? 15 : 13,
              fontWeight: isHighlighted ? FontWeight.w900 : FontWeight.w700,
              color: isHighlighted ? const Color(0xFF0E7A3B) : const Color(0xFF17221B),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPartyTile(Map<String, dynamic> party) {
    final name = party['full_name'] ?? party['username'] ?? 'Mtumiaji';
    final email = party['email']?.toString();
    final phone = party['phone_number']?.toString();

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAF8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5EBE7)),
      ),
      child: Row(
        children: [
          AppAvatar(
            imageUrl: party['avatar_url']?.toString(),
            initials: _initials(name.toString()),
            size: 36,
            icon: Icons.person_outline,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.toString(),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                if (phone != null && phone.isNotEmpty)
                  Text(phone, style: const TextStyle(fontSize: 11, color: Color(0xFF66736B))),
                if (email != null && email.isNotEmpty)
                  Text(email, style: const TextStyle(fontSize: 11, color: Color(0xFF66736B))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String isoString) {
    final d = DateTime.tryParse(isoString);
    if (d == null) return isoString;
    final local = d.toLocal();
    return '${local.day}/${local.month}/${local.year} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}

class _OrderStatusBadge extends StatelessWidget {
  const _OrderStatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();
    Color bg;
    Color fg;
    String label;

    switch (normalized) {
      case 'awaiting_payment':
      case 'pending':
        bg = const Color(0xFFFFF4D6);
        fg = const Color(0xFF9A6700);
        label = 'Inasubiri Malipo';
        break;
      case 'payment_processing':
        bg = const Color(0xFFE1F5FE);
        fg = const Color(0xFF0288D1);
        label = 'Inachakatwa';
        break;
      case 'paid':
        bg = const Color(0xFFE8F5E9);
        fg = const Color(0xFF0E7A3B);
        label = 'Imelipwa';
        break;
      case 'payment_review':
        bg = const Color(0xFFEDE7F6);
        fg = const Color(0xFF5E35B1);
        label = 'Inakaguliwa';
        break;
      case 'confirmed':
      case 'accepted':
        bg = const Color(0xFFE8F5E9);
        fg = const Color(0xFF1B5E20);
        label = 'Imethibitishwa';
        break;
      case 'completed':
        bg = const Color(0xFFE8F5E9);
        fg = const Color(0xFF0E7A3B);
        label = 'Imekamilika';
        break;
      case 'cancelled':
      case 'rejected':
      case 'failed':
        bg = const Color(0xFFFFEBEE);
        fg = Colors.redAccent;
        label = 'Imeghairiwa';
        break;
      default:
        bg = const Color(0xFFF0F4F1);
        fg = const Color(0xFF66736B);
        label = status.replaceAll('_', ' ').toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '';
  if (parts.length == 1) return parts.first.characters.first;
  return '${parts.first.characters.first}${parts.last.characters.first}';
}

String _formatPrice(String value) {
  final parsed = double.tryParse(value.replaceAll(',', ''));
  if (parsed == null) return value;
  final integer = parsed.round().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < integer.length; i++) {
    final remaining = integer.length - i;
    buffer.write(integer[i]);
    if (remaining > 1 && remaining % 3 == 1) {
      buffer.write(',');
    }
  }
  return buffer.toString();
}
