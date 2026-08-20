import 'package:flutter/material.dart';

import '../../core/network/api_service.dart';
import '../../core/widgets/searchable_select.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({
    super.key,
    required this.token,
    required this.permissions,
  });

  final String token;
  final Set<String> permissions;

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() {
    return _apiService.protectedList(token: widget.token, path: '/orders');
  }

  Future<void> _refresh() async {
    final future = _load();
    setState(() => _future = future);
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: widget.permissions.contains('orders.create')
          ? FloatingActionButton.extended(
              onPressed: _createOrder,
              icon: const Icon(Icons.add_shopping_cart_outlined),
              label: const Text('Oda'),
            )
          : null,
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: _ErrorState(
                message: snapshot.error.toString(),
                onRetry: _refresh,
              ),
            );
          }

          final orders = snapshot.data ?? const <Map<String, dynamic>>[];
          return RefreshIndicator(
            onRefresh: _refresh,
            child: orders.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 96),
                    children: [
                      SizedBox(
                        height: MediaQuery.sizeOf(context).height * 0.32,
                      ),
                      const Center(child: Text('Hakuna oda kwa sasa.')),
                    ],
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 96),
                    itemCount: orders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) => _OrderTile(
                      order: orders[index],
                      onTap: widget.permissions.contains('orders.read')
                          ? () => _openOrder(orders[index])
                          : null,
                    ),
                  ),
          );
        },
      ),
    );
  }

  Future<void> _createOrder() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _OrderFormSheet(
        token: widget.token,
        onSubmit: (body) => _apiService.protectedCreate(
          token: widget.token,
          path: '/orders',
          body: body,
        ),
      ),
    );
    if (created == true && mounted) {
      setState(() => _future = _load());
    }
  }

  Future<void> _openOrder(Map<String, dynamic> order) async {
    final orderId = order['order_id']?.toString();
    if (orderId == null || orderId.isEmpty) {
      return;
    }
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => _OrderDetailScreen(
          token: widget.token,
          orderId: orderId,
          permissions: widget.permissions,
        ),
      ),
    );
    if (changed == true && mounted) {
      setState(() => _future = _load());
    }
  }
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({required this.order, this.onTap});

  final Map<String, dynamic> order;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final title = _orderTitle(order);
    final quantity = order['quantity']?.toString() ?? '-';
    final total = order['total_price']?.toString() ?? '-';
    final status = order['status']?.toString() ?? '-';

    return ListTile(
      onTap: onTap,
      tileColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      leading: const CircleAvatar(
        backgroundColor: Color(0xFFE8F5E9),
        child: Icon(Icons.receipt_long_outlined, color: Color(0xFF0E7A3B)),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text('Kiasi: $quantity • Jumla: TSh $total'),
      trailing: Text(
        status.toUpperCase(),
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
      ),
    );
  }
}

class _OrderDetailScreen extends StatefulWidget {
  const _OrderDetailScreen({
    required this.token,
    required this.orderId,
    required this.permissions,
  });

  final String token;
  final String orderId;
  final Set<String> permissions;

  @override
  State<_OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<_OrderDetailScreen> {
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
      path: '/orders/${widget.orderId}',
    );
  }

  Future<void> _refresh() async {
    final future = _load();
    setState(() => _future = future);
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Oda')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: _ErrorState(
                message: snapshot.error.toString(),
                onRetry: _refresh,
              ),
            );
          }
          final order = snapshot.data ?? const <String, dynamic>{};
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
              children: [
                _InfoTile(label: 'Listing', value: _orderTitle(order)),
                _InfoTile(
                  label: 'Quantity',
                  value: order['quantity']?.toString() ?? '-',
                ),
                _InfoTile(
                  label: 'Total',
                  value: order['total_price']?.toString() ?? '-',
                ),
                _InfoTile(
                  label: 'Status',
                  value: order['status']?.toString() ?? '-',
                ),
                const SizedBox(height: 20),
                if (widget.permissions.contains('orders.update'))
                  FilledButton.icon(
                    onPressed: () => _edit(order),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Update order'),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _edit(Map<String, dynamic> order) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _OrderFormSheet(
        token: widget.token,
        order: order,
        onSubmit: (body) => _apiService.protectedUpdate(
          token: widget.token,
          path: '/orders/${widget.orderId}',
          body: body,
        ),
      ),
    );
    if (changed == true && mounted) {
      await _refresh();
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    }
  }
}

class _OrderFormSheet extends StatefulWidget {
  const _OrderFormSheet({
    required this.token,
    required this.onSubmit,
    this.order,
  });

  final String token;
  final Map<String, dynamic>? order;
  final Future<Map<String, dynamic>> Function(Map<String, dynamic> body)
  onSubmit;

  @override
  State<_OrderFormSheet> createState() => _OrderFormSheetState();
}

class _OrderFormSheetState extends State<_OrderFormSheet> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _quantityController;
  late Future<List<Map<String, dynamic>>> _listingsFuture;
  String? _selectedListingId;
  String _status = 'pending';
  bool _isSubmitting = false;

  bool get _isEditing => widget.order != null;

  @override
  void initState() {
    super.initState();
    final order = widget.order ?? const <String, dynamic>{};
    _quantityController = TextEditingController(
      text: order['quantity']?.toString() ?? '',
    );
    _selectedListingId = _readNested(order, 'listing.listing_id');
    _status = order['status']?.toString() ?? 'pending';
    _listingsFuture = _apiService.publicList('/listings');
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.75,
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _listingsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ErrorState(
              message: snapshot.error.toString(),
              onRetry: () async {
                final future = _apiService.publicList('/listings');
                setState(() => _listingsFuture = future);
                await future;
              },
            );
          }
          final listings = snapshot.data ?? const <Map<String, dynamic>>[];
          if (_selectedListingId == null && listings.isNotEmpty) {
            _selectedListingId = listings.first['listing_id']?.toString();
          }
          final selectedListing = _selectedListingId == null
              ? null
              : listings
                    .where(
                      (listing) =>
                          listing['listing_id']?.toString() ==
                          _selectedListingId,
                    )
                    .firstOrNull;
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
                  _isEditing ? 'Update order' : 'Place order',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                SearchableSelectFormField<Map<String, dynamic>>(
                  labelText: 'Listing',
                  value: selectedListing,
                  items: listings,
                  itemLabel: _listingTitle,
                  itemSubtitle: (listing) =>
                      '${_readNested(listing, 'commodity.name') ?? '-'} • ${_readNested(listing, 'adm_area.name') ?? '-'}',
                  leadingIcon: Icons.shopping_bag_outlined,
                  enabled: !_isSubmitting,
                  searchHintText: 'Search listings...',
                  emptyText: 'No listings found.',
                  validator: (value) => value == null ? 'Required' : null,
                  onChanged: (value) => setState(
                    () => _selectedListingId = value?['listing_id']?.toString(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _quantityController,
                  enabled: !_isSubmitting,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Quantity'),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Required' : null,
                ),
                if (_isEditing) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _status,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: const [
                      DropdownMenuItem(
                        value: 'pending',
                        child: Text('pending'),
                      ),
                      DropdownMenuItem(
                        value: 'accepted',
                        child: Text('accepted'),
                      ),
                      DropdownMenuItem(
                        value: 'cancelled',
                        child: Text('cancelled'),
                      ),
                      DropdownMenuItem(
                        value: 'completed',
                        child: Text('completed'),
                      ),
                    ],
                    onChanged: _isSubmitting
                        ? null
                        : (value) => setState(() => _status = value ?? _status),
                  ),
                ],
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
      'listing_id': _selectedListingId,
      'quantity': _quantityController.text.trim(),
      if (_isEditing) 'status': _status,
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

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      children: [
        SizedBox(height: MediaQuery.sizeOf(context).height * 0.28),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => onRetry(),
                icon: const Icon(Icons.refresh),
                label: const Text('Jaribu tena'),
              ),
            ],
          ),
        ),
      ],
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

String _orderTitle(Map<String, dynamic> order) {
  final listing = order['listing'];
  return listing is Map<String, dynamic> ? _listingTitle(listing) : 'Oda';
}

String _listingTitle(Map<String, dynamic> listing) {
  final commodity = listing['commodity'];
  final commodityMap = commodity is Map<String, dynamic> ? commodity : null;
  return listing['title']?.toString() ??
      commodityMap?['name']?.toString() ??
      'Listing';
}

String? _readNested(Map<String, dynamic> source, String path) {
  dynamic value = source;
  for (final segment in path.split('.')) {
    if (value is Map<String, dynamic>) {
      value = value[segment];
    } else {
      return null;
    }
  }
  return value?.toString();
}
