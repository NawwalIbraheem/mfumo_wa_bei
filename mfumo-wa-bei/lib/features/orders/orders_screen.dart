import 'package:flutter/material.dart';

import '../../core/network/api_service.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key, required this.token});

  final String token;

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

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(snapshot.error.toString(), textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => setState(() => _future = _load()),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Jaribu tena'),
                  ),
                ],
              ),
            ),
          );
        }

        final orders = snapshot.data ?? const <Map<String, dynamic>>[];
        if (orders.isEmpty) {
          return const Center(child: Text('Hakuna oda kwa sasa.'));
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() => _future = _load());
            await _future;
          },
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 96),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) => _OrderTile(order: orders[index]),
          ),
        );
      },
    );
  }
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({required this.order});

  final Map<String, dynamic> order;

  @override
  Widget build(BuildContext context) {
    final listing = order['listing'];
    final listingMap = listing is Map<String, dynamic> ? listing : null;
    final commodity = listingMap?['commodity'];
    final commodityMap = commodity is Map<String, dynamic> ? commodity : null;
    final title =
        listingMap?['title']?.toString() ??
        commodityMap?['name']?.toString() ??
        'Oda';
    final quantity = order['quantity']?.toString() ?? '-';
    final total = order['total_price']?.toString() ?? '-';
    final status = order['status']?.toString() ?? '-';

    return ListTile(
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
