import 'package:flutter/material.dart';
import 'login_page.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  static const routeName = '/welcome';

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  String selectedCropFilter = 'Zote'; // 'Zote', 'Mchele', 'Maharage'
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Mock Market Data
  final List<Map<String, dynamic>> markets = [
    {
      'name': 'Soko Kuu la Morogoro',
      'location': 'Katikati ya Mji, Morogoro',
      'ricePrice': 2400,
      'riceTrend': 'up', // 'up', 'down', 'stable'
      'riceChange': '+2.5%',
      'beanPrice': 3100,
      'beanTrend': 'stable',
      'beanChange': '0.0%',
      'distance': '0.5 km',
    },
    {
      'name': 'Soko la Sabasaba',
      'location': 'Sabasaba, Morogoro',
      'ricePrice': 2500,
      'riceTrend': 'stable',
      'riceChange': '0.0%',
      'beanPrice': 3200,
      'beanTrend': 'up',
      'beanChange': '+4.1%',
      'distance': '2.1 km',
    },
    {
      'name': 'Soko la Kiwanja cha Ndege',
      'location': 'Kiwanja cha Ndege, Morogoro',
      'ricePrice': 2300,
      'riceTrend': 'down',
      'riceChange': '-1.2%',
      'beanPrice': 3000,
      'beanTrend': 'down',
      'beanChange': '-2.0%',
      'distance': '3.5 km',
    },
    {
      'name': 'Soko la Mazimbu',
      'location': 'Mazimbu Rd, Morogoro',
      'ricePrice': 2450,
      'riceTrend': 'up',
      'riceChange': '+1.0%',
      'beanPrice': 3150,
      'beanTrend': 'up',
      'beanChange': '+1.8%',
      'distance': '4.2 km',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Get Initials of User Name
  String _getInitials(String name) {
    List<String> names = name.split(' ');
    String initials = '';
    if (names.isNotEmpty && names[0].isNotEmpty) {
      initials += names[0][0];
    }
    if (names.length > 1 && names[1].isNotEmpty) {
      initials += names[1][0];
    }
    return initials.toUpperCase();
  }

  // Show Profile Dialog Modal
  void _showProfileDialog(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 10,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.grey),
                  ),
                ),
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFF0D6B33), Color(0xFF77B66E)],
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _getInitials(user['full_name'] ?? 'Mtumiaji'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  user['full_name'] ?? 'Mtumiaji',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Mwanachama',
                    style: TextStyle(
                      color: Color(0xFF0E7A3B),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.email_outlined, color: Color(0xFF6B7280), size: 22),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Barua Pepe',
                            style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11),
                          ),
                          Text(
                            user['email'] ?? 'Hakuna barua pepe',
                            style: const TextStyle(color: Color(0xFF374151), fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.phone_outlined, color: Color(0xFF6B7280), size: 22),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Namba ya Simu',
                            style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11),
                          ),
                          Text(
                            user['phone_number'] ?? 'Hakuna namba ya simu',
                            style: const TextStyle(color: Color(0xFF374151), fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                      Navigator.pushReplacementNamed(context, LoginPage.routeName);
                    },
                    icon: const Icon(Icons.logout, color: Colors.redAccent),
                    label: const Text(
                      'Ondoka (Logout)',
                      style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.redAccent),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Show Market Details Dialog with Price Graph
  void _showMarketDetails(Map<String, dynamic> market) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        market['name'],
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.grey),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Color(0xFF0E7A3B), size: 16),
                    const SizedBox(width: 4),
                    Text(
                      market['location'],
                      style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'Mwenendo wa Bei (Wiki 4 Zilizopita)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF374151),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                // Simulated Graph Layout
                Container(
                  height: 120,
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildGraphBar('W1', 0.65, market['ricePrice'] - 150),
                      _buildGraphBar('W2', 0.75, market['ricePrice'] - 100),
                      _buildGraphBar('W3', 0.90, market['ricePrice'] - 50),
                      _buildGraphBar('Leo', 1.0, market['ricePrice']),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Text(
                          'MCHELE (kilo)',
                          style: TextStyle(color: Color(0xFF6B7280), fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'TSh ${market['ricePrice']}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0D6B33),
                          ),
                        ),
                        Text(
                          market['riceChange'],
                          style: TextStyle(
                            fontSize: 12,
                            color: market['riceTrend'] == 'up'
                                ? Colors.green
                                : market['riceTrend'] == 'down'
                                    ? Colors.red
                                    : Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Container(height: 40, width: 1, color: const Color(0xFFE5E7EB)),
                    Column(
                      children: [
                        const Text(
                          'MAHARAGE (kilo)',
                          style: TextStyle(color: Color(0xFF6B7280), fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'TSh ${market['beanPrice']}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFB45309),
                          ),
                        ),
                        Text(
                          market['beanChange'],
                          style: TextStyle(
                            fontSize: 12,
                            color: market['beanTrend'] == 'up'
                                ? Colors.green
                                : market['beanTrend'] == 'down'
                                    ? Colors.red
                                    : Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGraphBar(String label, double heightPercent, int price) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text('TSh $price', style: const TextStyle(fontSize: 9, color: Color(0xFF6B7280))),
        const SizedBox(height: 4),
        Container(
          width: 28,
          height: 60 * heightPercent,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF81C784), Color(0xFF4CAF50)],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
      ],
    );
  }

  // Show Report Price Bottom Sheet Form
  void _showReportPriceBottomSheet() {
    final formKey = GlobalKey<FormState>();
    String crop = 'Mchele';
    String marketName = 'Soko Kuu la Morogoro';
    final priceController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 48,
                        height: 5,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD1D5DB),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Ripoti Bei Mpya Morogoro',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Changia taarifa za bei ili kusaidia jamii ya wakulima na wanunuzi.',
                      style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                    ),
                    const SizedBox(height: 20),
                    const Text('Chagua Zao', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setModalState(() => crop = 'Mchele'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: crop == 'Mchele' ? const Color(0xFFE8F5E9) : Colors.white,
                                border: Border.all(
                                  color: crop == 'Mchele' ? const Color(0xFF0E7A3B) : const Color(0xFFE5E7EB),
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.rice_bowl,
                                    color: crop == 'Mchele' ? const Color(0xFF0E7A3B) : Colors.grey,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Mchele',
                                    style: TextStyle(
                                      color: crop == 'Mchele' ? const Color(0xFF0E7A3B) : const Color(0xFF374151),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setModalState(() => crop = 'Maharage'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: crop == 'Maharage' ? const Color(0xFFFFF3E0) : Colors.white,
                                border: Border.all(
                                  color: crop == 'Maharage' ? const Color(0xFFB45309) : const Color(0xFFE5E7EB),
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.grain,
                                    color: crop == 'Maharage' ? const Color(0xFFB45309) : Colors.grey,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Maharage',
                                    style: TextStyle(
                                      color: crop == 'Maharage' ? const Color(0xFFB45309) : const Color(0xFF374151),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('Soko la Mazao', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: marketName,
                          isExpanded: true,
                          items: markets.map((m) {
                            return DropdownMenuItem<String>(
                              value: m['name'],
                              child: Text(m['name']),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setModalState(() => marketName = val);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Bei ya Kilo Moja (TSh)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: 'Mfano: 2400',
                        prefixIcon: Icon(Icons.payments_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Tafadhali jaza bei.';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Jaza bei halali kwa namba.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          if (formKey.currentState!.validate()) {
                            Navigator.pop(context); // Close bottom sheet
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Asante! Ripoti yako ya bei ya $crop katika $marketName imetunziwa.'),
                                backgroundColor: const Color(0xFF0E7A3B),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0E7A3B),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Ripoti Sasa', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Read route arguments passed from login page
    final user = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>? ?? {
      'full_name': 'Mtumiaji',
      'email': 'user@example.com',
      'phone_number': '0700000000',
    };

    final fullName = user['full_name']?.toString() ?? 'Mtumiaji';

    // Filter and search markets
    List<Map<String, dynamic>> filteredMarkets = markets.where((m) {
      final matchesSearch = m['name'].toLowerCase().contains(searchQuery.toLowerCase()) ||
          m['location'].toLowerCase().contains(searchQuery.toLowerCase());
      return matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0D6B33), Color(0xFF14532D)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Mfumo wa Bei',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Colors.greenAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          const Text(
                            'Soko la Morogoro (Live)',
                            style: TextStyle(
                              color: Color(0xFFA7F3D0),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => _showProfileDialog(user),
                    child: Hero(
                      tag: 'user-profile-avatar',
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withAlpha(50),
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: Center(
                          child: Text(
                            _getInitials(fullName),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner Welcome Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0D6B33), Color(0xFF77B66E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Karibu tena,',
                    style: TextStyle(
                      color: Colors.white.withAlpha(204),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    fullName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Hapa kuna mtazamo wa bei za vyakula leo katika soko la Morogoro.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Current Date & Weather Mock
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(38),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.calendar_month, color: Colors.white, size: 14),
                            SizedBox(width: 6),
                            Text(
                              'Leo, 26 Julai 2026',
                              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(38),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.wb_sunny, color: Colors.amber, size: 14),
                            SizedBox(width: 6),
                            Text(
                              'Morogoro 28°C',
                              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Average Price Overview
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Wastani wa Bei Kitaifa / Morogoro',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      // Mchele Card
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(10),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFE8F5E9),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.rice_bowl, color: Color(0xFF0E7A3B), size: 20),
                                  ),
                                  const Icon(Icons.trending_up, color: Colors.green, size: 20),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Mchele (Safi)',
                                style: TextStyle(color: Color(0xFF6B7280), fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'TSh 2,400 / kg',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                '+1.5% wiki hii',
                                style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Maharage Card
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(10),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFFFF3E0),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.grain, color: Color(0xFFB45309), size: 20),
                                  ),
                                  const Icon(Icons.trending_flat, color: Colors.grey, size: 20),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Maharage (Njano)',
                                style: TextStyle(color: Color(0xFF6B7280), fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'TSh 3,100 / kg',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Imetulia wiki hii',
                                style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Market Price Listing header with search
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bei Katika Masoko ya Morogoro',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Search Field
                  TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Tafuta soko au eneo...',
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF6B7280)),
                      suffixIcon: searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                  searchQuery = '';
                                });
                              },
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Crop Filter Chips
                  Row(
                    children: [
                      _buildFilterChip('Zote'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Mchele'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Maharage'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Markets List
            ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: filteredMarkets.length,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              itemBuilder: (context, index) {
                final market = filteredMarkets[index];
                return GestureDetector(
                  onTap: () => _showMarketDetails(market),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(5),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                market['name'],
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF374151),
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                const Icon(Icons.navigation_outlined, size: 12, color: Color(0xFF6B7280)),
                                const SizedBox(width: 3),
                                Text(
                                  market['distance'],
                                  style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF9CA3AF)),
                            const SizedBox(width: 4),
                            Text(
                              market['location'],
                              style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(height: 1, color: Color(0xFFF3F4F6)),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Rice Price Row
                            if (selectedCropFilter == 'Zote' || selectedCropFilter == 'Mchele')
                              Expanded(
                                child: Row(
                                  children: [
                                    const Icon(Icons.rice_bowl_outlined, color: Color(0xFF0E7A3B), size: 18),
                                    const SizedBox(width: 6),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Mchele', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 10)),
                                        Row(
                                          children: [
                                            Text(
                                              'TSh ${market['ricePrice']}',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF374151),
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Icon(
                                              market['riceTrend'] == 'up'
                                                  ? Icons.arrow_upward
                                                  : market['riceTrend'] == 'down'
                                                      ? Icons.arrow_downward
                                                      : Icons.trending_flat,
                                              size: 11,
                                              color: market['riceTrend'] == 'up'
                                                  ? Colors.green
                                                  : market['riceTrend'] == 'down'
                                                      ? Colors.red
                                                      : Colors.grey,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            // Beans Price Row
                            if (selectedCropFilter == 'Zote' || selectedCropFilter == 'Maharage')
                              Expanded(
                                child: Row(
                                  children: [
                                    const Icon(Icons.grain_outlined, color: Color(0xFFB45309), size: 18),
                                    const SizedBox(width: 6),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Maharage', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 10)),
                                        Row(
                                          children: [
                                            Text(
                                              'TSh ${market['beanPrice']}',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF374151),
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Icon(
                                              market['beanTrend'] == 'up'
                                                  ? Icons.arrow_upward
                                                  : market['beanTrend'] == 'down'
                                                      ? Icons.arrow_downward
                                                      : Icons.trending_flat,
                                              size: 11,
                                              color: market['beanTrend'] == 'up'
                                                  ? Colors.green
                                                  : market['beanTrend'] == 'down'
                                                      ? Colors.red
                                                      : Colors.grey,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 80), // Space for floating button
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showReportPriceBottomSheet,
        backgroundColor: const Color(0xFF0E7A3B),
        icon: const Icon(Icons.add_chart_outlined, color: Colors.white),
        label: const Text(
          'Ripoti Bei Mpya',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.3),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = selectedCropFilter == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool selected) {
        if (selected) {
          setState(() {
            selectedCropFilter = label;
          });
        }
      },
      selectedColor: const Color(0xFFE8F5E9),
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF0E7A3B) : const Color(0xFF4B5563),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? const Color(0xFF0E7A3B) : const Color(0xFFE5E7EB),
        ),
      ),
    );
  }
}
