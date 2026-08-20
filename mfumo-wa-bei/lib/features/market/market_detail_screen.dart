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
              text: _readNested(
                widget.listing,
                'commodity.name',
                fallback: '-',
              ),
            ),
            _DetailLine(
              icon: Icons.place_outlined,
              text: _readNested(widget.listing, 'adm_area.name', fallback: '-'),
            ),
            _DetailLine(
              icon: Icons.scale_outlined,
              text:
                  'Kiasi: ${_readNested(widget.listing, 'quantity', fallback: '-')}',
            ),
            _DetailLine(
              icon: Icons.verified_outlined,
              text:
                  'Hali: ${_readNested(widget.listing, 'status', fallback: '-')}',
            ),
            const SizedBox(height: 14),
            Text(
              'TSh ${_readNested(widget.listing, 'price', fallback: '-')}',
              style: const TextStyle(
                color: Color(0xFF0E7A3B),
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 20),
            _InfoSection(
              title: 'Taarifa za bidhaa',
              children: [
                _InfoTile(
                  label: 'Listing ID',
                  value: _readNested(
                    widget.listing,
                    'listing_id',
                    fallback: '-',
                  ),
                ),
                _InfoTile(label: 'Title', value: listingTitle(widget.listing)),
                _InfoTile(
                  label: 'Description',
                  value: _readNested(
                    widget.listing,
                    'description',
                    fallback: '-',
                  ),
                ),
                _InfoTile(
                  label: 'Commodity',
                  value: _readNested(
                    widget.listing,
                    'commodity.name',
                    fallback: '-',
                  ),
                ),
                _InfoTile(
                  label: 'Commodity ID',
                  value: _readNested(
                    widget.listing,
                    'commodity.commodity_id',
                    fallback: '-',
                  ),
                ),
                _InfoTile(
                  label: 'Unit',
                  value: _readNested(
                    widget.listing,
                    'commodity.unit',
                    fallback: '-',
                  ),
                ),
                _InfoTile(
                  label: 'Area',
                  value: areaDisplayFromListing(widget.listing),
                ),
                _InfoTile(
                  label: 'Area ID',
                  value: _readNested(
                    widget.listing,
                    'adm_area.area_id',
                    fallback: '-',
                  ),
                ),
                _InfoTile(
                  label: 'Price',
                  value:
                      'TSh ${_readNested(widget.listing, 'price', fallback: '-')}',
                ),
                _InfoTile(
                  label: 'Quantity',
                  value: _readNested(widget.listing, 'quantity', fallback: '-'),
                ),
                _InfoTile(
                  label: 'Status',
                  value: _readNested(widget.listing, 'status', fallback: '-'),
                ),
                _InfoTile(
                  label: 'Created',
                  value: _readNested(
                    widget.listing,
                    'created_at',
                    fallback: '-',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _InfoSection(
              title: 'Muuzaji',
              children: [
                _SellerHeader(listing: widget.listing),
                const SizedBox(height: 8),
                _InfoTile(
                  label: 'Seller',
                  value: sellerDisplay(widget.listing),
                ),
                _InfoTile(
                  label: 'Seller ID',
                  value: _readNested(
                    widget.listing,
                    'seller_id',
                    fallback: '-',
                  ),
                ),
                _InfoTile(
                  label: 'Phone',
                  value: _readNested(
                    widget.listing,
                    'seller.phone_number',
                    fallback: '-',
                  ),
                ),
                _InfoTile(
                  label: 'Email',
                  value: _readNested(
                    widget.listing,
                    'seller.email',
                    fallback: '-',
                  ),
                ),
                _InfoTile(
                  label: 'Organization',
                  value: _readNested(
                    widget.listing,
                    'seller.organization',
                    fallback: '-',
                  ),
                ),
                _InfoTile(
                  label: 'Role',
                  value: _readNested(
                    widget.listing,
                    'seller.role.name',
                    fallback: _readNested(
                      widget.listing,
                      'seller.role.code',
                      fallback: '-',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (widget.canCreateOrder)
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
