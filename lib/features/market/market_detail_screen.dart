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
    this.currentUserId,
    this.userPhoneNumber,
  });

  final Map<String, dynamic> listing;
  final String token;
  final PublicDashboardData? dashboard;
  final bool canCreateOrder;
  final bool canUpdateListing;
  final bool canDeleteListing;
  final String? currentUserId;
  final String? userPhoneNumber;

  @override
  State<MarketDetailScreen> createState() => MarketDetailScreenState();
}

class MarketDetailScreenState extends State<MarketDetailScreen> {
  final ApiService _apiService = ApiService();
  late Map<String, dynamic> _listing;
  int _selectedImageIndex = 0;
  final TextEditingController _quantityController = TextEditingController(text: '1');
  bool _busy = false;

  bool get _isLoggedIn => widget.token.isNotEmpty;
  bool get _isOwnListing {
    final sellerId = readNested(_listing, 'seller_id');
    final sellerUserId = readNested(_listing, 'seller.user_id');
    if (widget.currentUserId == null || widget.currentUserId!.isEmpty) {
      return false;
    }
    return sellerId == widget.currentUserId || sellerUserId == widget.currentUserId;
  }

  @override
  void initState() {
    super.initState();
    _listing = widget.listing;
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  double get _unitPrice {
    final priceStr = readNested(_listing, 'price');
    return double.tryParse(priceStr.replaceAll(',', '')) ?? 0;
  }

  double get _availableStock {
    final quantityStr = readNested(_listing, 'quantity');
    return double.tryParse(quantityStr.replaceAll(',', '')) ?? 0;
  }

  double get _orderQuantity {
    return double.tryParse(_quantityController.text.trim()) ?? 0;
  }

  double get _estimatedTotal {
    return _unitPrice * _orderQuantity;
  }

  @override
  Widget build(BuildContext context) {
    final images = listingImages(_listing);
    final commodity = readNested(_listing, 'commodity.name', fallback: 'Zao');
    final unit = readNested(_listing, 'commodity.unit', fallback: 'unit');
    final status = readNested(_listing, 'status', fallback: 'available');
    final title = listingTitle(_listing);
    final description = readNested(_listing, 'description', fallback: 'Hakuna maelezo ya ziada yaliyowekwa.');

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (_isOwnListing || widget.canUpdateListing)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Hariri Bidhaa',
              onPressed: _busy ? null : _editListing,
            ),
          if (_isOwnListing || widget.canDeleteListing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Futa Bidhaa',
              onPressed: _busy ? null : _deleteListing,
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 36),
          children: [
            // Image Gallery
            _buildImageGallery(images),
            const SizedBox(height: 16),

            // Badges row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    commodity.toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFF0E7A3B),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ListingStatusBadge(status: status),
                const Spacer(),
                Text(
                  _relativeTimeAgo(readNested(_listing, 'created_at')),
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Title
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xFF17221B),
              ),
            ),
            const SizedBox(height: 6),

            // Location
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color: Color(0xFF0E7A3B),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    areaDisplayFromListing(_listing),
                    style: const TextStyle(
                      color: Color(0xFF66736B),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Price & Stock Cards in Row
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7FAF8),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE5EBE7)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'BEI KWA KIPIMO',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF66736B),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'TSh ${_formatPrice(_unitPrice.toString())}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0E7A3B),
                          ),
                        ),
                        Text(
                          'kwa $unit',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF66736B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7FAF8),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE5EBE7)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'KIASI KINACHOPATIKANA',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF66736B),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_formatPrice(_availableStock.toString())} $unit',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF17221B),
                          ),
                        ),
                        Text(
                          'stoo ya muuzaji',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF66736B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Description
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF7FAF8),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5EBE7)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'MAELEZO YA BIDHAA',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF66736B),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(
                      color: Color(0xFF17221B),
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Seller Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF7FAF8),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5EBE7)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TAARIFA ZA MUUZAJI',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF66736B),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SellerHeader(listing: _listing),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Buy Now / Order Section
            if (!_isOwnListing) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF0E7A3B).withValues(alpha: 0.3)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0C000000),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Weka Oda / Nunua Sasa',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF17221B),
                          ),
                        ),
                        Text(
                          'Upeo: $_availableStock $unit',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF66736B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Quantity Stepper
                    Row(
                      children: [
                        IconButton.outlined(
                          onPressed: () {
                            final current = double.tryParse(_quantityController.text) ?? 1;
                            if (current > 1) {
                              setState(() {
                                _quantityController.text = (current - 1).toString();
                              });
                            }
                          },
                          icon: const Icon(Icons.remove),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _quantityController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(
                              labelText: 'Kiasi ($unit)',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.outlined(
                          onPressed: () {
                            final current = double.tryParse(_quantityController.text) ?? 0;
                            if (current < _availableStock) {
                              setState(() {
                                _quantityController.text = (current + 1).toString();
                              });
                            }
                          },
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Total Calculation
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Kadirio la Jumla:',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF17221B),
                            ),
                          ),
                          Text(
                            'TSh ${_formatPrice(_estimatedTotal.toString())}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0E7A3B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Supported payment badges
                    Row(
                      children: const [
                        Text(
                          'Malipo:',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF66736B)),
                        ),
                        SizedBox(width: 6),
                        _PaymentPill('HaloPesa'),
                        SizedBox(width: 6),
                        _PaymentPill('Mixx by Yas'),
                        SizedBox(width: 6),
                        _PaymentPill('Airtel Money'),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Buy Now button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton.icon(
                        onPressed: _busy || _orderQuantity <= 0 || _orderQuantity > _availableStock
                            ? null
                            : _handlePlaceOrderAndPay,
                        icon: _busy
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.shopping_cart_checkout_outlined),
                        label: Text(
                          _isLoggedIn ? 'Nunua Sasa / Lipa' : 'Ingia ili Kununua',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF0E7A3B),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFC8E6C9)),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.info_outline, color: Color(0xFF0E7A3B)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Hili ni tangazo lako. Unaweza kulihariri au kulifuta kwa kutumia vitufe vilivyo juu.',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0E7A3B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildImageGallery(List<String> images) {
    if (images.isEmpty) {
      return AppAvatar(
        width: double.infinity,
        height: 220,
        borderRadius: BorderRadius.circular(16),
        icon: Icons.eco_outlined,
      );
    }

    final safeIndex = _selectedImageIndex.clamp(0, images.length - 1);
    final activeImageUrl = images[safeIndex];

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.network(
            activeImageUrl,
            width: double.infinity,
            height: 220,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              height: 220,
              color: const Color(0xFFE5EBE7),
              child: const Center(
                child: Icon(Icons.broken_image_outlined, size: 48, color: Color(0xFF66736B)),
              ),
            ),
          ),
        ),
        if (images.length > 1) ...[
          const SizedBox(height: 10),
          SizedBox(
            height: 60,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final isSelected = index == safeIndex;
                return GestureDetector(
                  onTap: () => setState(() => _selectedImageIndex = index),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF0E7A3B) : Colors.transparent,
                        width: 2.5,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(
                        images[index],
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 60,
                          height: 60,
                          color: const Color(0xFFE5EBE7),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _handlePlaceOrderAndPay() async {
    if (!_isLoggedIn) {
      Navigator.pushNamed(context, LoginScreen.routeName);
      return;
    }

    final listingId = _listing['listing_id']?.toString();
    if (listingId == null || listingId.isEmpty) return;

    final quantity = _quantityController.text.trim();
    if (double.tryParse(quantity) == null || double.parse(quantity) <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tafadhali weka kiasi sahihi cha kuagiza.')),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      final response = await _apiService.createOrder(
        token: widget.token,
        listingId: listingId,
        quantity: quantity,
      );

      final orderId = response['order_id']?.toString() ??
          (response['order'] is Map<String, dynamic> ? response['order']['order_id']?.toString() : null);

      if (orderId == null || orderId.isEmpty) {
        throw ApiException('Oda imewekwa lakini taarifa za oda hazijapatikana.');
      }

      setState(() => _busy = false);
      if (!mounted) return;

      // Open mobile payment sheet
      final paid = await OrderPaymentSheet.show(
        context,
        token: widget.token,
        orderId: orderId,
        totalAmount: _estimatedTotal.toString(),
        initialPhoneNumber: widget.userPhoneNumber,
        listingTitle: listingTitle(_listing),
      );

      if (paid == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Oda na malipo yamethibitishwa kikamilifu!'),
            backgroundColor: Color(0xFF0E7A3B),
          ),
        );
        Navigator.pop(context, true);
      }
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message), backgroundColor: Colors.redAccent),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent),
      );
    }
  }

  Future<void> _editListing() async {
    final changed = await ListingFormScreen.show(
      context,
      token: widget.token,
      listing: _listing,
      dashboard: widget.dashboard,
    );
    if (changed == true && mounted) {
      final listingId = _listing['listing_id']?.toString();
      if (listingId != null) {
        try {
          final updated = await _apiService.getCommodityListing(
            listingId,
            token: widget.token.isEmpty ? null : widget.token,
          );
          if (mounted) setState(() => _listing = updated);
        } catch (_) {}
      }
    }
  }

  Future<void> _deleteListing() async {
    final listingId = _listing['listing_id']?.toString();
    if (listingId == null || listingId.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Futa bidhaa?'),
        content: const Text('Kitendo hiki hakiwezi kurudishwa. Je, una uhakika?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Ghairi'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Futa'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    setState(() => _busy = true);
    try {
      await _apiService.deleteCommodityListing(
        token: widget.token,
        listingId: listingId,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bidhaa imefutwa kwa mafanikio.'),
            backgroundColor: Color(0xFF0E7A3B),
          ),
        );
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
}

class _PaymentPill extends StatelessWidget {
  const _PaymentPill(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF17221B)),
      ),
    );
  }
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
