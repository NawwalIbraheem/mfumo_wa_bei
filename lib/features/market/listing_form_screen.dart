import 'package:flutter/material.dart';

import '../../core/network/api_service.dart';
import '../../core/network/public_api_models.dart';
import '../../core/widgets/searchable_select.dart';
import '../../core/widgets/listing_card.dart';

class ListingFormScreen extends StatefulWidget {
  const ListingFormScreen({
    super.key,
    required this.token,
    this.listing,
    this.dashboard,
  });

  final String token;
  final Map<String, dynamic>? listing;
  final PublicDashboardData? dashboard;

  static Future<bool?> show(
    BuildContext context, {
    required String token,
    Map<String, dynamic>? listing,
    PublicDashboardData? dashboard,
  }) {
    return Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ListingFormScreen(
          token: token,
          listing: listing,
          dashboard: dashboard,
        ),
      ),
    );
  }

  @override
  State<ListingFormScreen> createState() => _ListingFormScreenState();
}

class _ListingFormScreenState extends State<ListingFormScreen> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _quantityController;
  final TextEditingController _imageUrlInputController = TextEditingController();

  List<String> _imageUrls = [];
  String? _selectedCommodityId;
  String? _selectedAreaId;
  String _status = 'available';
  bool _isSubmitting = false;

  late Future<List<List<Map<String, dynamic>>>> _catalogsFuture;

  bool get _isEditing => widget.listing != null;

  @override
  void initState() {
    super.initState();
    final listing = widget.listing ?? const <String, dynamic>{};

    _titleController = TextEditingController(
      text: readNested(listing, 'title'),
    );
    _descriptionController = TextEditingController(
      text: readNested(listing, 'description'),
    );
    _priceController = TextEditingController(
      text: readNested(listing, 'price'),
    );
    _quantityController = TextEditingController(
      text: readNested(listing, 'quantity'),
    );

    final rawStatus = readNested(listing, 'status', fallback: 'available').toLowerCase();
    if (['available', 'sold_out', 'draft', 'archived', 'active', 'inactive', 'sold'].contains(rawStatus)) {
      if (rawStatus == 'active') {
        _status = 'available';
      } else if (rawStatus == 'sold') {
        _status = 'sold_out';
      } else if (rawStatus == 'inactive') {
        _status = 'draft';
      } else {
        _status = rawStatus;
      }
    } else {
      _status = 'available';
    }

    _selectedCommodityId = _blankToNull(
      readNested(listing, 'commodity.commodity_id'),
    );
    _selectedAreaId = _blankToNull(readNested(listing, 'adm_area.area_id'));

    _imageUrls = listingImages(listing);

    _catalogsFuture = Future.wait([
      _loadCommodities(),
      _apiService.publicList('/areas'),
    ]);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _imageUrlInputController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _loadCommodities() async {
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

  void _addImageUrl() {
    final url = _imageUrlInputController.text.trim();
    if (url.isNotEmpty && !_imageUrls.contains(url)) {
      setState(() {
        _imageUrls.add(url);
        _imageUrlInputController.clear();
      });
    }
  }

  void _removeImageUrl(int index) {
    setState(() {
      _imageUrls.removeAt(index);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCommodityId == null || _selectedCommodityId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tafadhali chagua zao/commodity.')),
      );
      return;
    }
    if (_selectedAreaId == null || _selectedAreaId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tafadhali chagua eneo/location.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final body = <String, dynamic>{
      'commodity_id': _selectedCommodityId,
      'adm_area_id': _selectedAreaId,
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'price': double.tryParse(_priceController.text.trim()) ?? 0,
      'quantity': double.tryParse(_quantityController.text.trim()) ?? 0,
      'status': _status,
      'image_urls': _imageUrls,
    };

    try {
      if (_isEditing) {
        final listingId = widget.listing!['listing_id'].toString();
        await _apiService.updateCommodityListing(
          token: widget.token,
          listingId: listingId,
          body: body,
        );
      } else {
        await _apiService.createCommodityListing(
          token: widget.token,
          body: body,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Bidhaa imesasishwa kwa mafanikio.'
                : 'Bidhaa imewekwa sokoni kwa mafanikio.',
          ),
          backgroundColor: const Color(0xFF0E7A3B),
        ),
      );
      Navigator.pop(context, true);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message), backgroundColor: Colors.redAccent),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Imeshindikana kuhifadhi bidhaa. Jaribu tena.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Hariri Bidhaa' : 'Weka Bidhaa Mpya'),
      ),
      body: FutureBuilder<List<List<Map<String, dynamic>>>>(
        future: _catalogsFuture,
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
                    Text(
                      'Hitilafu: ${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () {
                        setState(() {
                          _catalogsFuture = Future.wait([
                            _loadCommodities(),
                            _apiService.publicList('/areas'),
                          ]);
                        });
                      },
                      child: const Text('Jaribu Tena'),
                    ),
                  ],
                ),
              ),
            );
          }

          final commodities = snapshot.data?[0] ?? const <Map<String, dynamic>>[];
          final areas = snapshot.data?[1] ?? const <Map<String, dynamic>>[];

          if (_selectedCommodityId == null && commodities.isNotEmpty) {
            _selectedCommodityId = commodities.first['commodity_id']?.toString();
          }

          final selectedArea = _selectedAreaId == null
              ? null
              : areas
                  .where((a) => a['area_id']?.toString() == _selectedAreaId)
                  .firstOrNull;

          final selectedCommodity = commodities
              .where((c) => c['commodity_id']?.toString() == _selectedCommodityId)
              .firstOrNull;
          final unit = selectedCommodity?['unit']?.toString() ?? 'kg';

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 36),
              children: [
                // Title
                TextFormField(
                  controller: _titleController,
                  enabled: !_isSubmitting,
                  decoration: InputDecoration(
                    labelText: 'Kichwa cha Tangazo / Title *',
                    hintText: 'Mfano: Mchele Bora wa Kyela',
                    prefixIcon: const Icon(Icons.title_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (val) =>
                      val == null || val.trim().isEmpty ? 'Kichwa kinahitajika' : null,
                ),
                const SizedBox(height: 16),

                // Commodity Selector
                DropdownButtonFormField<String>(
                  initialValue: _selectedCommodityId,
                  decoration: InputDecoration(
                    labelText: 'Zao (Commodity) *',
                    prefixIcon: const Icon(Icons.inventory_2_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: commodities
                      .map(
                        (c) => DropdownMenuItem(
                          value: c['commodity_id']?.toString(),
                          child: Text('${c['name']} (${c['unit'] ?? 'unit'})'),
                        ),
                      )
                      .toList(),
                  onChanged: _isSubmitting
                      ? null
                      : (val) => setState(() => _selectedCommodityId = val),
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Tafadhali chagua zao' : null,
                ),
                const SizedBox(height: 16),

                // Area Selector
                SearchableSelectFormField<Map<String, dynamic>>(
                  labelText: 'Eneo / Mahali (Location) *',
                  value: selectedArea,
                  items: areas,
                  itemLabel: (a) {
                    final path = a['path']?.toString();
                    if (path != null && path.trim().isNotEmpty) return path;
                    return a['name']?.toString() ?? 'Eneo';
                  },
                  itemSubtitle: (a) => a['level']?.toString() ?? '',
                  leadingIcon: Icons.location_on_outlined,
                  enabled: !_isSubmitting,
                  searchHintText: 'Tafuta mkoa, wilaya au kata...',
                  emptyText: 'Hakuna eneo lililopatikana.',
                  validator: (val) => val == null ? 'Eneo linahitajika' : null,
                  onChanged: (val) => setState(
                    () => _selectedAreaId = val?['area_id']?.toString(),
                  ),
                ),
                const SizedBox(height: 16),

                // Quantity and Price in Row
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _quantityController,
                        enabled: !_isSubmitting,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Kiasi ($unit) *',
                          hintText: '100',
                          prefixIcon: const Icon(Icons.scale_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Weka kiasi';
                          }
                          final parsed = double.tryParse(val.trim());
                          if (parsed == null || parsed <= 0) {
                            return 'Kiasi si sahihi';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _priceController,
                        enabled: !_isSubmitting,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Bei (TSh/$unit) *',
                          hintText: '2500',
                          prefixIcon: const Icon(Icons.payments_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Weka bei';
                          }
                          final parsed = double.tryParse(val.trim());
                          if (parsed == null || parsed <= 0) {
                            return 'Bei si sahihi';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Status dropdown
                DropdownButtonFormField<String>(
                  initialValue: _status,
                  decoration: InputDecoration(
                    labelText: 'Hali ya Tangazo (Status)',
                    prefixIcon: const Icon(Icons.verified_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'available',
                      child: Text('Inapatikana (Available)'),
                    ),
                    DropdownMenuItem(
                      value: 'sold_out',
                      child: Text('Imeuzwa (Sold Out)'),
                    ),
                    DropdownMenuItem(
                      value: 'draft',
                      child: Text('Rasimu (Draft)'),
                    ),
                    DropdownMenuItem(
                      value: 'archived',
                      child: Text('Kumbukumbu (Archived)'),
                    ),
                  ],
                  onChanged: _isSubmitting
                      ? null
                      : (val) => setState(() => _status = val ?? _status),
                ),
                const SizedBox(height: 16),

                // Description
                TextFormField(
                  controller: _descriptionController,
                  enabled: !_isSubmitting,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Maelezo ya Ziada (Description)',
                    hintText: 'Eleza ubora, ufungashaji, usafirishaji n.k.',
                    alignLabelWithHint: true,
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(bottom: 50),
                      child: Icon(Icons.notes_outlined),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Images section
                const Text(
                  'Picha za Bidhaa (Picha URLs)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF17221B),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _imageUrlInputController,
                        enabled: !_isSubmitting,
                        decoration: InputDecoration(
                          hintText: 'Weka URL ya picha (https://...)',
                          prefixIcon: const Icon(Icons.link_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: _isSubmitting ? null : _addImageUrl,
                      icon: const Icon(Icons.add),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFF0E7A3B),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Images previews
                if (_imageUrls.isNotEmpty)
                  SizedBox(
                    height: 90,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _imageUrls.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final url = _imageUrls[index];
                        return Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                url,
                                width: 90,
                                height: 90,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 90,
                                  height: 90,
                                  color: const Color(0xFFE5EBE7),
                                  child: const Icon(
                                    Icons.broken_image_outlined,
                                    color: Color(0xFF66736B),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => _removeImageUrl(index),
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7FAF8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5EBE7)),
                    ),
                    child: const Text(
                      'Bado hujaongeza picha. Weka link ya picha juu na ubonyeze "+"',
                      style: TextStyle(fontSize: 12, color: Color(0xFF66736B)),
                    ),
                  ),

                const SizedBox(height: 28),

                // Submit button
                SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: _isSubmitting ? null : _submit,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check),
                    label: Text(
                      _isSubmitting
                          ? 'Inahifadhi...'
                          : (_isEditing ? 'Sasisha Bidhaa' : 'Weka Bidhaa Sokoni'),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0E7A3B),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String? _blankToNull(String value) {
    return value.trim().isEmpty ? null : value.trim();
  }
}
