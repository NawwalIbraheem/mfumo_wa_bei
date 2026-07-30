import 'package:flutter/material.dart';

import '../../core/network/api_service.dart';

class ListingsScreen extends StatefulWidget {
  const ListingsScreen({super.key});

  @override
  State<ListingsScreen> createState() => _ListingsScreenState();
}

class _ListingsScreenState extends State<ListingsScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() {
    return _apiService.publicList('/listings');
  }

  Future<void> _refresh() async {
    final future = _load();
    setState(() => _future = future);
    await future;
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
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              children: [
                SizedBox(height: MediaQuery.sizeOf(context).height * 0.28),
                Text(snapshot.error.toString(), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                Center(
                  child: FilledButton.icon(
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Jaribu tena'),
                  ),
                ),
              ],
            ),
          );
        }

        final listings = snapshot.data ?? const <Map<String, dynamic>>[];

        return RefreshIndicator(
          onRefresh: _refresh,
          child: listings.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 96),
                  children: [
                    SizedBox(height: MediaQuery.sizeOf(context).height * 0.32),
                    const Center(child: Text('Hakuna bidhaa kwa sasa.')),
                  ],
                )
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 96),
                  itemCount: listings.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) => _ListingTile(
                    listing: listings[index],
                    onTap: () => _showListingDetails(listings[index]),
                  ),
                ),
        );
      },
    );
  }

  void _showListingDetails(Map<String, dynamic> listing) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _listingTitle(listing),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              _readNested(listing, 'description', fallback: '-'),
              style: const TextStyle(color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 16),
            _DetailLine(
              icon: Icons.inventory_2_outlined,
              text: _readNested(listing, 'commodity.name', fallback: '-'),
            ),
            _DetailLine(
              icon: Icons.place_outlined,
              text: _readNested(listing, 'adm_area.name', fallback: '-'),
            ),
            _DetailLine(
              icon: Icons.scale_outlined,
              text: 'Kiasi: ${_readNested(listing, 'quantity', fallback: '-')}',
            ),
            const SizedBox(height: 14),
            Text(
              'TSh ${_readNested(listing, 'price', fallback: '-')}',
              style: const TextStyle(
                color: Color(0xFF0E7A3B),
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListingTile extends StatelessWidget {
  const _ListingTile({required this.listing, required this.onTap});

  final Map<String, dynamic> listing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      tileColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      leading: const CircleAvatar(
        backgroundColor: Color(0xFFE8F5E9),
        child: Icon(Icons.shopping_bag_outlined, color: Color(0xFF0E7A3B)),
      ),
      title: Text(
        _listingTitle(listing),
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: Text(
        '${_readNested(listing, 'commodity.name', fallback: '-')} • ${_readNested(listing, 'adm_area.name', fallback: '-')}',
      ),
      trailing: Text(
        'TSh ${_readNested(listing, 'price', fallback: '-')}',
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF0E7A3B)),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

String _listingTitle(Map<String, dynamic> listing) {
  final commodityName = _readNested(listing, 'commodity.name', fallback: '');
  return listing['title']?.toString().trim().isNotEmpty == true
      ? listing['title'].toString()
      : commodityName.isEmpty
      ? 'Bidhaa'
      : commodityName;
}

String _readNested(
  Map<String, dynamic> source,
  String path, {
  String fallback = '',
}) {
  dynamic value = source;
  for (final segment in path.split('.')) {
    if (value is Map<String, dynamic>) {
      value = value[segment];
    } else {
      return fallback;
    }
  }
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}
