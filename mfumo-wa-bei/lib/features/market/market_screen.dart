import 'package:flutter/material.dart';

import '../../core/config/api_config.dart';
import '../../core/network/api_service.dart';
import '../../core/network/public_api_models.dart';
import '../../core/widgets/searchable_select.dart';

part 'market_detail_screen.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({
    super.key,
    this.token = '',
    this.permissions = const <String>{},
    this.dashboard,
  });

  final String token;
  final Set<String> permissions;
  final PublicDashboardData? dashboard;

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<Map<String, dynamic>>> _future;

  bool get _canCreateListing => widget.permissions.contains('listings.create');
  bool get _canUpdateListing => widget.permissions.contains('listings.update');
  bool get _canDeleteListing => widget.permissions.contains('listings.delete');
  bool get _canCreateOrder => widget.permissions.contains('orders.create');

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
    return Scaffold(
      floatingActionButton: _canCreateListing
          ? FloatingActionButton.extended(
              onPressed: _createListing,
              icon: const Icon(Icons.add_business_outlined),
              label: const Text('Weka bidhaa'),
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

          final listings = snapshot.data ?? const <Map<String, dynamic>>[];
          return RefreshIndicator(
            onRefresh: _refresh,
            child: listings.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 96),
                    children: [
                      SizedBox(
                        height: MediaQuery.sizeOf(context).height * 0.32,
                      ),
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
      ),
    );
  }

  Future<void> _createListing() async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _ListingFormSheet(
        dashboard: widget.dashboard,
        onSubmit: (body) => _apiService.protectedCreate(
          token: widget.token,
          path: '/listings',
          body: body,
        ),
      ),
    );
    if (changed == true && mounted) {
      setState(() => _future = _load());
    }
  }

  Future<void> _showListingDetails(Map<String, dynamic> listing) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => MarketDetailScreen(
          listing: listing,
          token: widget.token,
          dashboard: widget.dashboard,
          canCreateOrder: _canCreateOrder,
          canUpdateListing: _canUpdateListing,
          canDeleteListing: _canDeleteListing,
        ),
      ),
    );
    if (changed == true && mounted) {
      setState(() => _future = _load());
    }
  }
}

class _ListingFormSheet extends StatefulWidget {
  const _ListingFormSheet({
    required this.onSubmit,
    this.dashboard,
    this.listing,
  });

  final PublicDashboardData? dashboard;
  final Map<String, dynamic>? listing;
  final Future<Map<String, dynamic>> Function(Map<String, dynamic> body)
  onSubmit;

  @override
  State<_ListingFormSheet> createState() => _ListingFormSheetState();
}

class _ListingFormSheetState extends State<_ListingFormSheet> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _quantityController;
  late final TextEditingController _imageUrlsController;
  late Future<List<List<Map<String, dynamic>>>> _optionsFuture;
  String? _selectedCommodityId;
  String? _selectedAreaId;
  String _status = 'active';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final listing = widget.listing ?? const <String, dynamic>{};
    _titleController = TextEditingController(
      text: _readNested(listing, 'title'),
    );
    _descriptionController = TextEditingController(
      text: _readNested(listing, 'description'),
    );
    _priceController = TextEditingController(
      text: _readNested(listing, 'price'),
    );
    _quantityController = TextEditingController(
      text: _readNested(listing, 'quantity'),
    );
    final images = listing['images'];
    _imageUrlsController = TextEditingController(
      text: images is List
          ? images
                .whereType<Map<String, dynamic>>()
                .map((image) => image['image_url']?.toString() ?? '')
                .where((url) => url.isNotEmpty)
                .join(', ')
          : '',
    );
    _selectedCommodityId = _blankToNull(
      _readNested(listing, 'commodity.commodity_id'),
    );
    _selectedAreaId = _blankToNull(_readNested(listing, 'adm_area.area_id'));
    _status = _readNested(listing, 'status', fallback: 'active');
    _optionsFuture = Future.wait([
      _dashboardCommodities(),
      _apiService.publicList('/areas'),
    ]);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _imageUrlsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.9,
      child: FutureBuilder<List<List<Map<String, dynamic>>>>(
        future: _optionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ErrorState(
              message: snapshot.error.toString(),
              onRetry: () async {
                final future = Future.wait([
                  _dashboardCommodities(),
                  _apiService.publicList('/areas'),
                ]);
                setState(() => _optionsFuture = future);
                await future;
              },
            );
          }
          final commodities =
              snapshot.data?[0] ?? const <Map<String, dynamic>>[];
          final areas = snapshot.data?[1] ?? const <Map<String, dynamic>>[];
          if (_selectedCommodityId == null && commodities.isNotEmpty) {
            _selectedCommodityId = commodities.first['commodity_id']
                ?.toString();
          }
          if (_selectedAreaId == null && areas.isNotEmpty) {
            _selectedAreaId = areas.first['area_id']?.toString();
          }
          final selectedArea = _selectedAreaId == null
              ? null
              : areas
                    .where(
                      (area) => area['area_id']?.toString() == _selectedAreaId,
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
                  widget.listing == null ? 'Weka bidhaa' : 'Hariri bidhaa',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                _sheetField(_titleController, 'Jina / kichwa'),
                DropdownButtonFormField<String>(
                  initialValue: _selectedCommodityId,
                  decoration: const InputDecoration(labelText: 'Zao'),
                  items: commodities
                      .map(
                        (commodity) => DropdownMenuItem(
                          value: commodity['commodity_id']?.toString(),
                          child: Text(commodity['name']?.toString() ?? ''),
                        ),
                      )
                      .toList(),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Required' : null,
                  onChanged: _isSubmitting
                      ? null
                      : (value) => setState(() => _selectedCommodityId = value),
                ),
                const SizedBox(height: 12),
                SearchableSelectFormField<Map<String, dynamic>>(
                  labelText: 'Eneo',
                  value: selectedArea,
                  items: areas,
                  itemLabel: _areaLabel,
                  itemSubtitle: _areaSubtitle,
                  leadingIcon: Icons.map_outlined,
                  enabled: !_isSubmitting,
                  searchHintText: 'Tafuta eneo...',
                  emptyText: 'Hakuna maeneo.',
                  validator: (value) => value == null ? 'Required' : null,
                  onChanged: (value) => setState(
                    () => _selectedAreaId = value?['area_id']?.toString(),
                  ),
                ),
                const SizedBox(height: 12),
                _sheetField(
                  _descriptionController,
                  'Maelezo',
                  required: false,
                  maxLines: 3,
                ),
                _sheetField(
                  _priceController,
                  'Bei',
                  keyboardType: TextInputType.number,
                ),
                _sheetField(
                  _quantityController,
                  'Kiasi',
                  required: false,
                  keyboardType: TextInputType.number,
                ),
                DropdownButtonFormField<String>(
                  initialValue: _status,
                  decoration: const InputDecoration(labelText: 'Hali'),
                  items: const [
                    DropdownMenuItem(value: 'active', child: Text('active')),
                    DropdownMenuItem(
                      value: 'inactive',
                      child: Text('inactive'),
                    ),
                    DropdownMenuItem(value: 'sold', child: Text('sold')),
                  ],
                  onChanged: _isSubmitting
                      ? null
                      : (value) => setState(() => _status = value ?? _status),
                ),
                const SizedBox(height: 12),
                _sheetField(
                  _imageUrlsController,
                  'Image URLs',
                  required: false,
                ),
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

  Future<List<Map<String, dynamic>>> _dashboardCommodities() async {
    final dashboardCommodities = widget.dashboard?.commodities;
    if (dashboardCommodities != null && dashboardCommodities.isNotEmpty) {
      return dashboardCommodities
          .map(
            (commodity) => {
              'commodity_id': commodity.id,
              'name': commodity.name,
              'unit': commodity.unit,
            },
          )
          .toList();
    }
    return _apiService.publicList('/commodities');
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    final body = <String, dynamic>{
      'commodity_id': _selectedCommodityId,
      'adm_area_id': _selectedAreaId,
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'price': _priceController.text.trim(),
      'status': _status,
      'image_urls': _imageUrlsController.text
          .split(',')
          .map((url) => url.trim())
          .where((url) => url.isNotEmpty)
          .toList(),
    };
    _addIfNotBlank(body, 'quantity', _quantityController.text);
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

class _OrderFromListingSheet extends StatefulWidget {
  const _OrderFromListingSheet({required this.listing, required this.onSubmit});

  final Map<String, dynamic> listing;
  final Future<Map<String, dynamic>> Function(Map<String, dynamic> body)
  onSubmit;

  @override
  State<_OrderFromListingSheet> createState() => _OrderFromListingSheetState();
}

class _OrderFromListingSheetState extends State<_OrderFromListingSheet> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _quantityController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Form(
        key: _formKey,
        child: ListView(
          shrinkWrap: true,
          padding: EdgeInsets.fromLTRB(
            20,
            8,
            20,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          children: [
            const Text(
              'Weka oda',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            _InfoTile(label: 'Bidhaa', value: _listingTitle(widget.listing)),
            _InfoTile(
              label: 'Bei',
              value:
                  'TSh ${_readNested(widget.listing, 'price', fallback: '-')}',
            ),
            const SizedBox(height: 12),
            _sheetField(
              _quantityController,
              'Kiasi cha kununua',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 50,
              child: FilledButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                icon: const Icon(Icons.add_shopping_cart_outlined),
                label: Text(_isSubmitting ? 'Saving...' : 'Place order'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final listingId = widget.listing['listing_id']?.toString();
    if (listingId == null || listingId.isEmpty) return;
    setState(() => _isSubmitting = true);
    try {
      await widget.onSubmit({
        'listing_id': listingId,
        'quantity': _quantityController.text.trim(),
      });
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

class _ListingTile extends StatelessWidget {
  const _ListingTile({required this.listing, required this.onTap});

  final Map<String, dynamic> listing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final imageUrl = _primaryImageUrl(listing);
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ListingImage(url: imageUrl, width: 112, height: 132),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _listingTitle(listing),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_readNested(listing, 'commodity.name', fallback: '-')} • ${_areaDisplayFromListing(listing)}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Color(0xFF6B7280)),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _Pill(
                          icon: Icons.scale_outlined,
                          text:
                              '${_readNested(listing, 'quantity', fallback: '-')} ${_readNested(listing, 'commodity.unit')}',
                        ),
                        _Pill(
                          icon: Icons.verified_outlined,
                          text: _readNested(listing, 'status', fallback: '-'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'TSh ${_readNested(listing, 'price', fallback: '-')}',
                      style: const TextStyle(
                        color: Color(0xFF0E7A3B),
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _sellerDisplay(listing),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListingImage extends StatelessWidget {
  const _ListingImage({
    required this.url,
    required this.width,
    required this.height,
  });

  final String? url;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return Container(
        width: width,
        height: height,
        color: const Color(0xFFE8F5E9),
        child: const Icon(
          Icons.shopping_bag_outlined,
          color: Color(0xFF0E7A3B),
          size: 34,
        ),
      );
    }
    return Image.network(
      url!,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        width: width,
        height: height,
        color: const Color(0xFFE8F5E9),
        child: const Icon(
          Icons.broken_image_outlined,
          color: Color(0xFF0E7A3B),
        ),
      ),
    );
  }
}

class _ImageStrip extends StatelessWidget {
  const _ImageStrip({required this.images});

  final List<String> images;

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: const _ListingImage(
          url: null,
          width: double.infinity,
          height: 190,
        ),
      );
    }
    return SizedBox(
      height: 190,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) => ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: _ListingImage(
            url: images[index],
            width: MediaQuery.sizeOf(context).width * 0.78,
            height: 190,
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF0E7A3B)),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 12)),
        ],
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

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(value.isEmpty ? '-' : value),
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
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
        SizedBox(height: MediaQuery.sizeOf(context).height * 0.28),
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

Widget _sheetField(
  TextEditingController controller,
  String label, {
  bool enabled = true,
  bool required = true,
  int maxLines = 1,
  TextInputType? keyboardType,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      enabled: enabled,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(labelText: label),
      validator: required
          ? (value) => value == null || value.trim().isEmpty ? 'Required' : null
          : null,
    ),
  );
}

String _listingTitle(Map<String, dynamic> listing) {
  final commodityName = _readNested(listing, 'commodity.name', fallback: '');
  return listing['title']?.toString().trim().isNotEmpty == true
      ? listing['title'].toString()
      : commodityName.isEmpty
      ? 'Bidhaa'
      : commodityName;
}

String _areaLabel(Map<String, dynamic> area) {
  final path = area['path']?.toString();
  if (path != null && path.trim().isNotEmpty) {
    return path;
  }
  return area['name']?.toString() ?? 'Eneo';
}

String _areaSubtitle(Map<String, dynamic> area) {
  return area['level']?.toString() ?? '';
}

String _areaDisplayFromListing(Map<String, dynamic> listing) {
  final path = _readNested(listing, 'adm_area.path');
  if (path.isNotEmpty) {
    return path;
  }
  return _readNested(listing, 'adm_area.name', fallback: '-');
}

String _sellerDisplay(Map<String, dynamic> listing) {
  final fullName = _readNested(listing, 'seller.full_name');
  if (fullName.isNotEmpty) {
    return fullName;
  }
  final firstName = _readNested(listing, 'seller.first_name');
  final lastName = _readNested(listing, 'seller.last_name');
  final name = '$firstName $lastName'.trim();
  if (name.isNotEmpty) {
    return name;
  }
  final username = _readNested(listing, 'seller.username');
  if (username.isNotEmpty) {
    return username;
  }
  return _readNested(listing, 'seller_id', fallback: 'Muuzaji');
}

String? _primaryImageUrl(Map<String, dynamic> listing) {
  final images = listing['images'];
  if (images is! List) {
    return null;
  }
  final imageMaps = images.whereType<Map<String, dynamic>>().toList();
  if (imageMaps.isEmpty) {
    return null;
  }
  final primary = imageMaps.where((image) => image['is_primary'] == true);
  final selected = primary.isNotEmpty ? primary.first : imageMaps.first;
  return _normalizeImageUrl(selected['image_url']?.toString());
}

List<String> _listingImages(Map<String, dynamic> listing) {
  final images = listing['images'];
  if (images is! List) {
    return const <String>[];
  }
  return images
      .whereType<Map<String, dynamic>>()
      .map((image) => _normalizeImageUrl(image['image_url']?.toString()))
      .whereType<String>()
      .where((url) => url.isNotEmpty)
      .toList();
}

String? _normalizeImageUrl(String? rawUrl) {
  final url = rawUrl?.trim();
  if (url == null || url.isEmpty) {
    return null;
  }
  final parsed = Uri.tryParse(url);
  if (parsed != null && parsed.hasScheme) {
    return url;
  }
  final apiBase = Uri.parse(ApiConfig.baseUrl);
  final origin = apiBase.replace(path: '', query: '', fragment: '');
  if (url.startsWith('/')) {
    return origin.resolve(url).toString();
  }
  return origin.resolve('/$url').toString();
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

String? _blankToNull(String value) {
  return value.trim().isEmpty ? null : value;
}

void _addIfNotBlank(Map<String, dynamic> body, String key, String value) {
  final trimmed = value.trim();
  if (trimmed.isNotEmpty) {
    body[key] = trimmed;
  }
}
