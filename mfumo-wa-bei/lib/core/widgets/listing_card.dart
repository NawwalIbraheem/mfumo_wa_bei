import 'package:flutter/material.dart';

import '../config/api_config.dart';
import 'app_avatar.dart';

class ListingCard extends StatelessWidget {
  const ListingCard({super.key, required this.listing, required this.onTap});

  final Map<String, dynamic> listing;
  final VoidCallback onTap;

  static const _green = Color(0xFF16803C);
  static const _darkGreen = Color(0xFF0D5C2A);
  static const _textPrimary = Color(0xFF17221B);
  static const _textSecondary = Color(0xFF66736B);
  static const _border = Color(0xFFE5EBE7);
  static const _surface = Color(0xFFF7FAF8);

  @override
  Widget build(BuildContext context) {
    final commodity = readNested(listing, 'commodity.name', fallback: 'Bidhaa');

    final quantity = readNested(listing, 'quantity', fallback: '-');

    final unit = readNested(listing, 'commodity.unit');

    final price = readNested(listing, 'price', fallback: '-');

    final status = readNested(listing, 'status', fallback: '-');

    final images = listingImages(listing);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 14,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product image
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    children: [
                      AppAvatar(
                        imageUrl: primaryListingImageUrl(listing),
                        width: 118,
                        height: 142,
                        borderRadius: BorderRadius.zero,
                        icon: Icons.eco_outlined,
                      ),

                      // Optional image count
                      if (images.length > 1)
                        Positioned(
                          right: 7,
                          bottom: 7,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.photo_library_outlined,
                                  size: 12,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  '${images.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(width: 13),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Commodity + status
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              commodity.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _green,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          _StatusBadge(status: status),
                        ],
                      ),

                      const SizedBox(height: 5),

                      // Listing title
                      Text(
                        listingTitle(listing),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _textPrimary,
                          fontSize: 15,
                          height: 1.2,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 7),

                      // Location
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 15,
                            color: _textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              areaDisplayFromListing(listing),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Quantity
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: _surface,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.scale_outlined,
                                  size: 14,
                                  color: _green,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  '$quantity $unit'.trim(),
                                  style: const TextStyle(
                                    color: _textPrimary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 7),

                      // Price + seller
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Text(
                              'TSh ${_formatPrice(price)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _darkGreen,
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.person_outline,
                                  size: 13,
                                  color: _textSecondary,
                                ),
                                const SizedBox(width: 3),
                                Flexible(
                                  child: Text(
                                    sellerDisplay(listing),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: _textSecondary,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatPrice(String value) {
    final parsed = double.tryParse(value.replaceAll(',', ''));

    if (parsed == null) {
      return value;
    }

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
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();

    Color foreground;
    Color background;

    switch (normalized) {
      case 'available':
      case 'active':
      case 'approved':
        foreground = const Color(0xFF137333);
        background = const Color(0xFFE9F7ED);
        break;

      case 'pending':
        foreground = const Color(0xFF9A6700);
        background = const Color(0xFFFFF4D6);
        break;

      case 'sold':
      case 'closed':
      case 'inactive':
        foreground = const Color(0xFF737A76);
        background = const Color(0xFFF0F2F1);
        break;

      default:
        foreground = const Color(0xFF137333);
        background = const Color(0xFFE9F7ED);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: foreground,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Existing helpers
// ---------------------------------------------------------------------------

String listingTitle(Map<String, dynamic> listing) {
  final commodityName = readNested(listing, 'commodity.name');

  return listing['title']?.toString().trim().isNotEmpty == true
      ? listing['title'].toString()
      : commodityName.isEmpty
      ? 'Bidhaa'
      : commodityName;
}

String areaDisplayFromListing(Map<String, dynamic> listing) {
  final path = readNested(listing, 'adm_area.path');

  if (path.isNotEmpty) {
    return path;
  }

  return readNested(listing, 'adm_area.name', fallback: '-');
}

String sellerDisplay(Map<String, dynamic> listing) {
  final fullName = readNested(listing, 'seller.full_name');

  if (fullName.isNotEmpty) {
    return fullName;
  }

  final firstName = readNested(listing, 'seller.first_name');

  final lastName = readNested(listing, 'seller.last_name');

  final name = '$firstName $lastName'.trim();

  if (name.isNotEmpty) {
    return name;
  }

  final username = readNested(listing, 'seller.username');

  if (username.isNotEmpty) {
    return username;
  }

  return readNested(listing, 'seller_id', fallback: 'Muuzaji');
}

String? primaryListingImageUrl(Map<String, dynamic> listing) {
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

  return normalizeImageUrl(selected['image_url']?.toString());
}

List<String> listingImages(Map<String, dynamic> listing) {
  final images = listing['images'];

  if (images is! List) {
    return const <String>[];
  }

  return images
      .whereType<Map<String, dynamic>>()
      .map((image) => normalizeImageUrl(image['image_url']?.toString()))
      .whereType<String>()
      .where((url) => url.isNotEmpty)
      .toList();
}

String? normalizeImageUrl(String? rawUrl) {
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

String readNested(
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
