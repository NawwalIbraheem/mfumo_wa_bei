class PublicDashboardData {
  const PublicDashboardData({
    required this.markets,
    required this.prices,
    required this.commodities,
  });

  final List<MarketRecord> markets;
  final List<MarketPriceRecord> prices;
  final List<CommodityRecord> commodities;

  List<Map<String, dynamic>> get marketCards {
    return markets.map((market) {
      final marketPrices = prices
          .where((price) => price.market?.id == market.id)
          .toList();
      final rice = _priceFor(marketPrices, const ['rice', 'mchele']);
      final beans = _priceFor(marketPrices, const ['beans', 'maharage']);

      return {
        'id': market.id,
        'name': market.name,
        'location': market.locationLabel,
        'ricePrice': rice?.displayPrice.round() ?? 0,
        'ricePriceLabel': rice?.formattedPrice ?? '-',
        'riceTrend': 'stable',
        'riceChange': rice == null ? '-' : rice.formattedDate,
        'beanPrice': beans?.displayPrice.round() ?? 0,
        'beanPriceLabel': beans?.formattedPrice ?? '-',
        'beanTrend': 'stable',
        'beanChange': beans == null ? '-' : beans.formattedDate,
        'distance': market.status,
      };
    }).toList();
  }

  List<MarketPriceRecord> get latestCommodityPrices {
    final byCommodity = <String, MarketPriceRecord>{};
    for (final price in prices) {
      final id = price.commodity?.id ?? price.priceId;
      final previous = byCommodity[id];
      if (previous == null ||
          price.priceDate.compareTo(previous.priceDate) > 0) {
        byCommodity[id] = price;
      }
    }
    return byCommodity.values.toList()
      ..sort((a, b) => a.commodityName.compareTo(b.commodityName));
  }

  static MarketPriceRecord? _priceFor(
    List<MarketPriceRecord> prices,
    List<String> commodityNames,
  ) {
    final matches =
        prices
            .where(
              (price) {
                final name = price.commodityName.toLowerCase();
                return commodityNames.any(name.contains);
              },
            )
            .toList()
          ..sort((a, b) => b.priceDate.compareTo(a.priceDate));
    return matches.isEmpty ? null : matches.first;
  }
}

class MarketRecord {
  const MarketRecord({
    required this.id,
    required this.name,
    required this.status,
    this.adminArea,
    this.address,
  });

  final String id;
  final String name;
  final String status;
  final AreaRecord? adminArea;
  final String? address;

  String get locationLabel {
    final parts = [
      if (address != null && address!.trim().isNotEmpty) address!.trim(),
      if (adminArea != null) adminArea!.pathLabel,
    ];
    return parts.isEmpty ? 'Eneo halijawekwa' : parts.join(', ');
  }

  factory MarketRecord.fromJson(Map<String, dynamic> json) {
    final area = json['admin_area'];
    return MarketRecord(
      id: json['market_id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Soko',
      status: json['status']?.toString() ?? 'active',
      address: json['address']?.toString(),
      adminArea: area is Map<String, dynamic>
          ? AreaRecord.fromJson(area)
          : null,
    );
  }
}

class AreaRecord {
  const AreaRecord({
    required this.id,
    required this.name,
    required this.level,
    this.parent,
  });

  final String id;
  final String name;
  final String level;
  final AreaRecord? parent;

  String get pathLabel {
    if (parent == null) {
      return name;
    }
    return '$name, ${parent!.pathLabel}';
  }

  factory AreaRecord.fromJson(Map<String, dynamic> json) {
    final parentJson = json['parent'];
    return AreaRecord(
      id: json['area_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      level: json['level']?.toString() ?? '',
      parent: parentJson is Map<String, dynamic>
          ? AreaRecord.fromJson(parentJson)
          : null,
    );
  }
}

class CommodityRecord {
  const CommodityRecord({
    required this.id,
    required this.name,
    required this.unit,
  });

  final String id;
  final String name;
  final String unit;

  factory CommodityRecord.fromJson(Map<String, dynamic> json) {
    return CommodityRecord(
      id: json['commodity_id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Zao',
      unit: json['unit']?.toString() ?? '',
    );
  }
}

class MarketPriceRecord {
  const MarketPriceRecord({
    required this.priceId,
    required this.price,
    this.minPrice,
    this.maxPrice,
    required this.currency,
    required this.priceDate,
    this.market,
    this.commodity,
  });

  final String priceId;
  final double price;
  final double? minPrice;
  final double? maxPrice;
  final String currency;
  final String priceDate;
  final MarketRecord? market;
  final CommodityRecord? commodity;

  String get commodityName => commodity?.name ?? 'Zao';
  String get marketName => market?.name ?? 'Soko';
  double get displayPrice {
    if (minPrice != null && maxPrice != null) {
      return (minPrice! + maxPrice!) / 2;
    }
    return minPrice ?? maxPrice ?? price;
  }

  String get formattedPrice {
    final code = currency.isEmpty ? 'TSh' : currency;
    if (minPrice != null && maxPrice != null) {
      if (minPrice!.round() == maxPrice!.round()) {
        return '$code ${_formatNumber(minPrice!)}';
      }
      return '$code ${_formatNumber(minPrice!)} - ${_formatNumber(maxPrice!)}';
    }
    final fallback = minPrice ?? maxPrice ?? price;
    return '$code ${_formatNumber(fallback)}';
  }

  String get formattedDate => priceDate.isEmpty ? '-' : priceDate;

  factory MarketPriceRecord.fromJson(Map<String, dynamic> json) {
    final marketJson = json['market'];
    final commodityJson = json['commodity'];
    return MarketPriceRecord(
      priceId: json['price_id']?.toString() ?? '',
      price: double.tryParse(json['price']?.toString() ?? '') ?? 0,
      minPrice: _readDouble(json['min_price']),
      maxPrice: _readDouble(json['max_price']),
      currency: json['currency']?.toString() ?? 'TSh',
      priceDate: json['price_date']?.toString() ?? '',
      market: marketJson is Map<String, dynamic>
          ? MarketRecord.fromJson(marketJson)
          : null,
      commodity: commodityJson is Map<String, dynamic>
          ? CommodityRecord.fromJson(commodityJson)
          : null,
    );
  }
}

double? _readDouble(dynamic value) {
  if (value == null) {
    return null;
  }
  return double.tryParse(value.toString());
}

String _formatNumber(double value) {
  final text = value.round().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    final remaining = text.length - i;
    buffer.write(text[i]);
    if (remaining > 1 && remaining % 3 == 1) {
      buffer.write(',');
    }
  }
  return buffer.toString();
}
