import 'package:flutter/material.dart';

class MarketPricesScreen extends StatelessWidget {
  const MarketPricesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
          sliver: SliverToBoxAdapter(
            child: Text(
              'Mwenendo wa Bei',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList.list(
            children: const [
              _PriceTrendCard(
                commodity: 'Mchele',
                currentPrice: 'TSh 2,400',
                change: '+1.5%',
                icon: Icons.rice_bowl_outlined,
              ),
              SizedBox(height: 12),
              _PriceTrendCard(
                commodity: 'Maharage',
                currentPrice: 'TSh 3,100',
                change: '0.0%',
                icon: Icons.grain_outlined,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PriceTrendCard extends StatelessWidget {
  const _PriceTrendCard({
    required this.commodity,
    required this.currentPrice,
    required this.change,
    required this.icon,
  });

  final String commodity;
  final String currentPrice;
  final String change;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF0E7A3B)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  commodity,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                change,
                style: const TextStyle(
                  color: Color(0xFF0E7A3B),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            currentPrice,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              _Bar(label: 'W1', height: 56),
              _Bar(label: 'W2', height: 72),
              _Bar(label: 'W3', height: 64),
              _Bar(label: 'Leo', height: 92),
            ],
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.label, required this.height});

  final String label;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 46,
          height: height,
          decoration: BoxDecoration(
            color: const Color(0xFF0E7A3B),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
        ),
      ],
    );
  }
}
