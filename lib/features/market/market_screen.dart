import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/network/api_service.dart';
import '../../core/network/public_api_models.dart';
import '../../core/widgets/app_avatar.dart';
import '../../core/widgets/listing_card.dart';
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
  static const int _pageSize = 9;

  final ApiService _apiService = ApiService();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _listings = [];
  int _page = 0;
  bool _hasNext = true;
  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;

  bool get _canCreateListing => widget.permissions.contains('listings.create');
  bool get _canUpdateListing => widget.permissions.contains('listings.update');
  bool get _canDeleteListing => widget.permissions.contains('listings.delete');
  bool get _canCreateOrder => widget.permissions.contains('orders.create');

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    _loadInitial();
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
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

    try {
      final response = await _apiService.paginatedList(
        path: '/listings',
        page: page,
        pageSize: _pageSize,
        token: widget.token.isEmpty ? null : widget.token,
      );
      if (!mounted) return;
      setState(() {
        if (replace) {
          _listings
            ..clear()
            ..addAll(response.items);
        } else {
          _listings.addAll(response.items);
        }
        _page = response.page;
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
    }
  }

  void _handleScroll() {
    if (!_scrollController.hasClients || !_hasNext) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 320) {
      _loadMore();
    }
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
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isInitialLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null && _listings.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refresh,
        child: _ErrorState(message: _errorMessage!, onRetry: _refresh),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: _listings.isEmpty
          ? ListView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 96),
              children: [
                SizedBox(height: MediaQuery.sizeOf(context).height * 0.32),
                const Center(child: Text('Hakuna bidhaa kwa sasa.')),
              ],
            )
          : ListView.separated(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 96),
              itemCount: _listings.length + (_isLoadingMore ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                if (index >= _listings.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                return ListingCard(
                  listing: _listings[index],
                  onTap: () => _showListingDetails(_listings[index]),
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
            _InfoTile(label: 'Bidhaa', value: listingTitle(widget.listing)),
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

class _ImageStrip extends StatelessWidget {
  const _ImageStrip({required this.images});

  final List<String> images;

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return AppAvatar(
        width: double.infinity,
        height: 190,
        borderRadius: BorderRadius.circular(14),
        icon: Icons.eco_outlined,
      );
    }
    return SizedBox(
      height: 190,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) => AppAvatar(
          imageUrl: images[index],
          width: MediaQuery.sizeOf(context).width * 0.78,
          height: 190,
          borderRadius: BorderRadius.circular(14),
          icon: Icons.eco_outlined,
        ),
      ),
    );
  }
}

class _SellerHeader extends StatelessWidget {
  const _SellerHeader({required this.listing});

  final Map<String, dynamic> listing;

  @override
  Widget build(BuildContext context) {
    final sellerName = sellerDisplay(listing);
    final phone = _readNested(listing, 'seller.phone_number');
    final email = _readNested(listing, 'seller.email');

    return Row(
      children: [
        AppAvatar(
          imageUrl: _readNested(listing, 'seller.avatar_url'),
          initials: _sellerInitials(sellerName),
          icon: Icons.person_outline,
          size: 64,
          borderRadius: BorderRadius.circular(8),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.person_outline,
                    size: 16,
                    color: Color(0xFF17221B),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      sellerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
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

class _InfoLabel extends StatelessWidget {
  const _InfoLabel({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 24),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAF8),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE5EBE7)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xFF0E7A3B)),
          const SizedBox(width: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 180),
            child: Text(
              value.isEmpty ? '-' : value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF17221B),
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
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

String _sellerInitials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) {
    return '';
  }
  if (parts.length == 1) {
    return parts.first.characters.first;
  }
  return '${parts.first.characters.first}${parts.last.characters.first}';
}

String _relativeTime(String rawDate) {
  final date = DateTime.tryParse(rawDate);
  if (date == null) {
    return '-';
  }
  final postedAt = date.isUtc ? date.toLocal() : date;
  final difference = DateTime.now().difference(postedAt);
  if (difference.inSeconds < 60) {
    return 'now';
  }
  if (difference.inMinutes < 60) {
    return '${difference.inMinutes}m';
  }
  if (difference.inHours < 24) {
    return '${difference.inHours}h';
  }
  if (difference.inDays < 7) {
    return '${difference.inDays}d';
  }
  if (difference.inDays < 30) {
    return '${difference.inDays ~/ 7}w';
  }
  if (difference.inDays < 365) {
    return '${difference.inDays ~/ 30}mo';
  }
  return '${difference.inDays ~/ 365}y';
}

String _relativeTimeAgo(String rawDate) {
  final relative = _relativeTime(rawDate);
  if (relative == '-' || relative == 'now') {
    return relative;
  }
  return '$relative ago';
}

String _pricePerUnit(Map<String, dynamic> listing) {
  final price = _readNested(listing, 'price', fallback: '-');
  final unit = _readNested(listing, 'commodity.unit');
  if (unit.isEmpty) {
    return 'TSh $price';
  }
  return 'TSh $price / $unit';
}

String _commodityCategoryLabel(Map<String, dynamic> listing) {
  final commodity = listing['commodity'];
  if (commodity is Map<String, dynamic>) {
    final categories = commodity['categories'];
    if (categories is List) {
      final names = categories
          .whereType<Map<String, dynamic>>()
          .map((category) => category['name']?.toString().trim() ?? '')
          .where((name) => name.isNotEmpty)
          .toList();
      if (names.isNotEmpty) {
        return names.join(', ');
      }
    }
  }
  return _readNested(listing, 'commodity.name', fallback: '-');
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
