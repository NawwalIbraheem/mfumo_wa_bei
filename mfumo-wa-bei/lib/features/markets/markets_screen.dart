import 'package:flutter/material.dart';

class MarketsScreen extends StatelessWidget {
  const MarketsScreen({
    super.key,
    required this.markets,
    required this.selectedCropFilter,
    required this.searchController,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onFilterChanged,
    required this.onMarketTap,
  });

  final List<Map<String, dynamic>> markets;
  final String selectedCropFilter;
  final TextEditingController searchController;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final ValueChanged<String> onFilterChanged;
  final ValueChanged<Map<String, dynamic>> onMarketTap;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Masoko ya Morogoro',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Linganishia bei za mchele na maharage kwenye masoko yaliyo karibu.',
                  style: TextStyle(color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: searchController,
                  onChanged: onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Tafuta soko au eneo...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: searchQuery.isEmpty
                        ? null
                        : IconButton(
                            onPressed: onClearSearch,
                            icon: const Icon(Icons.close),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: ['Zote', 'Mchele', 'Maharage'].map((filter) {
                    return ChoiceChip(
                      label: Text(filter),
                      selected: selectedCropFilter == filter,
                      onSelected: (_) => onFilterChanged(filter),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
          sliver: SliverList.separated(
            itemCount: markets.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final market = markets[index];
              return MarketCard(
                market: market,
                selectedCropFilter: selectedCropFilter,
                onTap: () => onMarketTap(market),
              );
            },
          ),
        ),
      ],
    );
  }
}

class MarketCard extends StatelessWidget {
  const MarketCard({
    super.key,
    required this.market,
    required this.selectedCropFilter,
    required this.onTap,
  });

  final Map<String, dynamic> market;
  final String selectedCropFilter;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      market['name'].toString(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    market['distance'].toString(),
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                market['location'].toString(),
                style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  if (selectedCropFilter == 'Zote' ||
                      selectedCropFilter == 'Mchele')
                    Expanded(
                      child: CropPrice(
                        label: 'Mchele',
                        price: market['ricePrice'] as int,
                        trend: market['riceTrend'].toString(),
                      ),
                    ),
                  if (selectedCropFilter == 'Zote') const SizedBox(width: 12),
                  if (selectedCropFilter == 'Zote' ||
                      selectedCropFilter == 'Maharage')
                    Expanded(
                      child: CropPrice(
                        label: 'Maharage',
                        price: market['beanPrice'] as int,
                        trend: market['beanTrend'].toString(),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CropPrice extends StatelessWidget {
  const CropPrice({
    super.key,
    required this.label,
    required this.price,
    required this.trend,
  });

  final String label;
  final int price;
  final String trend;

  @override
  Widget build(BuildContext context) {
    final icon = trend == 'up'
        ? Icons.arrow_upward
        : trend == 'down'
        ? Icons.arrow_downward
        : Icons.trending_flat;
    final color = trend == 'down' ? Colors.red : const Color(0xFF0E7A3B);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            label == 'Mchele' ? Icons.rice_bowl_outlined : Icons.grain_outlined,
            size: 20,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6B7280),
                  ),
                ),
                Text(
                  'TSh $price',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          Icon(icon, size: 16, color: color),
        ],
      ),
    );
  }
}
