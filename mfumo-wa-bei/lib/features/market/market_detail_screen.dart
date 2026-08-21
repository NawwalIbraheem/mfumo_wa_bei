part of 'market_screen.dart';

class MarketDetailScreen extends StatefulWidget {
  const MarketDetailScreen({
    super.key,
    required this.listing,
    required this.token,
    required this.canCreateOrder,
    required this.canUpdateListing,
    required this.canDeleteListing,
    this.dashboard,
  });

  final Map<String, dynamic> listing;
  final String token;
  final PublicDashboardData? dashboard;
  final bool canCreateOrder;
  final bool canUpdateListing;
  final bool canDeleteListing;

  @override
  State<MarketDetailScreen> createState() => MarketDetailScreenState();
}

class MarketDetailScreenState extends State<MarketDetailScreen> {
  final ApiService _apiService = ApiService();
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Maelezo ya bidhaa')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            _ImageStrip(images: listingImages(widget.listing)),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _InfoLabel(
                        icon: Icons.place_outlined,
                        value: areaDisplayFromListing(widget.listing),
                      ),
                      _InfoLabel(
                        icon: Icons.verified_outlined,
                        value: _readNested(
                          widget.listing,
                          'status',
                          fallback: '-',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(
                    _relativeTimeAgo(_readNested(widget.listing, 'created_at')),
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              listingTitle(widget.listing),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              _readNested(widget.listing, 'description', fallback: '-'),
              style: const TextStyle(color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 16),
            _DetailLine(
              icon: Icons.inventory_2_outlined,
              text: 'Category: ${_commodityCategoryLabel(widget.listing)}',
            ),
            _DetailLine(
              icon: Icons.scale_outlined,
              text:
                  'Stock available: ${_readNested(widget.listing, 'quantity', fallback: '-')}',
            ),
            const SizedBox(height: 14),
            Text(
              _pricePerUnit(widget.listing),
              style: const TextStyle(
                color: Color(0xFF0E7A3B),
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'About Seller',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            _SellerHeader(listing: widget.listing),
            const SizedBox(height: 20),
            if (widget.canCreateOrder || widget.token.isEmpty)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _busy ? null : _placeOrder,
                  icon: const Icon(Icons.add_shopping_cart_outlined),
                  label: const Text('Nunua / weka oda'),
                ),
              ),
            if (widget.canUpdateListing) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : _editListing,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Hariri bidhaa'),
                ),
              ),
            ],
            if (widget.canDeleteListing) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : _deleteListing,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Futa bidhaa'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _placeOrder() async {
    if (widget.token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingia kwanza ili kuweka oda.')),
      );
      return;
    }
    if (!widget.canCreateOrder) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Huna ruhusa ya kuweka oda.')),
      );
      return;
    }
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _OrderFromListingSheet(
        listing: widget.listing,
        onSubmit: (body) => _apiService.protectedCreate(
          token: widget.token,
          path: '/orders',
          body: body,
        ),
      ),
    );
    if (changed == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _editListing() async {
    final listingId = widget.listing['listing_id']?.toString();
    if (listingId == null || listingId.isEmpty) return;
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _ListingFormSheet(
        dashboard: widget.dashboard,
        listing: widget.listing,
        onSubmit: (body) => _apiService.protectedUpdate(
          token: widget.token,
          path: '/listings/$listingId',
          body: body,
        ),
      ),
    );
    if (changed == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _deleteListing() async {
    final listingId = widget.listing['listing_id']?.toString();
    if (listingId == null || listingId.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Futa bidhaa?'),
        content: const Text('Kitendo hiki hakiwezi kurudishwa.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Ghairi'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Futa'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _busy = true);
    try {
      await _apiService.protectedDelete(
        token: widget.token,
        path: '/listings/$listingId',
      );
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }
}
