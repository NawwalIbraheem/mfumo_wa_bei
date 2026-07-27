import 'package:flutter/material.dart';

import '../../../../features/markets/presentation/screens/markets_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.role,
    required this.filteredMarkets,
    required this.permissions,
    required this.onMarketTap,
  });

  final String role;
  final List<Map<String, dynamic>> filteredMarkets;
  final Set<String> permissions;
  final ValueChanged<Map<String, dynamic>> onMarketTap;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _DashboardIntro(role: role)),
        if (permissions.contains('users.list') ||
            permissions.contains('markets.create') ||
            permissions.contains('commodities.create'))
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            sliver: SliverToBoxAdapter(
              child: _PermissionActions(permissions: permissions),
            ),
          ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: const [
                Expanded(
                  child: _SummaryCard(
                    icon: Icons.rice_bowl_outlined,
                    label: 'Mchele',
                    value: 'TSh 2,400',
                    trend: '+1.5%',
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _SummaryCard(
                    icon: Icons.grain_outlined,
                    label: 'Maharage',
                    value: 'TSh 3,100',
                    trend: '0.0%',
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 22, 16, 10),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Masoko karibu nawe',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 6),
                Text(
                  'Muhtasari wa masoko yenye taarifa mpya za bei.',
                  style: TextStyle(color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
          sliver: SliverList.separated(
            itemCount: filteredMarkets.take(3).length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final market = filteredMarkets[index];
              return MarketCard(
                market: market,
                selectedCropFilter: 'Zote',
                onTap: () => onMarketTap(market),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DashboardIntro extends StatelessWidget {
  const _DashboardIntro({required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
      decoration: const BoxDecoration(
        color: Color(0xFF0E7A3B),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bei za mchele na maharage karibu nawe',
            style: TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.w800,
              height: 1.18,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const _HeaderPill(icon: Icons.place_outlined, text: 'Morogoro'),
              const SizedBox(width: 10),
              const _HeaderPill(icon: Icons.update, text: 'Leo'),
              const SizedBox(width: 10),
              _HeaderPill(
                icon: Icons.verified_user_outlined,
                text: role.toUpperCase(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderPill extends StatelessWidget {
  const _HeaderPill({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(36),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.trend,
  });

  final IconData icon;
  final String label;
  final String value;
  final String trend;

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
          Icon(icon, color: const Color(0xFF0E7A3B)),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            trend,
            style: const TextStyle(
              color: Color(0xFF0E7A3B),
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _PermissionActions extends StatelessWidget {
  const _PermissionActions({required this.permissions});

  final Set<String> permissions;

  @override
  Widget build(BuildContext context) {
    final actions = <_ActionItem>[
      if (permissions.contains('users.list'))
        const _ActionItem(icon: Icons.group_outlined, label: 'Watumiaji'),
      if (permissions.contains('markets.create'))
        const _ActionItem(icon: Icons.storefront_outlined, label: 'Soko Jipya'),
      if (permissions.contains('commodities.create'))
        const _ActionItem(icon: Icons.inventory_2_outlined, label: 'Zao Jipya'),
      if (permissions.contains('market_prices.create'))
        const _ActionItem(icon: Icons.add_chart_outlined, label: 'Bei Mpya'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Vitendo vya haraka',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 86,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: actions.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) => actions[index],
          ),
        ),
      ],
    );
  }
}

class _ActionItem extends StatelessWidget {
  const _ActionItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 112,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF0E7A3B)),
          const Spacer(),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
