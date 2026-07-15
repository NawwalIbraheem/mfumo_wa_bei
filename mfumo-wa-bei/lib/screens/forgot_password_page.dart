import 'package:flutter/material.dart';

import '../widgets/auth_widgets.dart';

class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({super.key});

  static const routeName = '/forgot-password';

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      showBack: true,
      child: Column(
        children: [
          const SizedBox(height: 4),
          const Center(
            child: PageTitleBlock(
              title: 'Umesahau nenosiri?',
              subtitle: 'Pata msaada wa kurejesha akaunti yako.',
            ),
          ),
          const SizedBox(height: 28),
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 145,
                height: 145,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFEFF7EF),
                ),
              ),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Icon(
                  Icons.mark_email_read_outlined,
                  size: 52,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          const Text(
            'Weka namba yako ya simu',
            style: TextStyle(
              color: Color(0xFF111827),
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              'Tutakutumia msimbo wa kuthibitisha ili uweze kuweka nenosiri jipya.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 14,
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const AuthTextField(
            hintText: 'Namba ya simu',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 18),
          PrimaryAuthButton(
            label: 'TUMA MSIMBO',
            onPressed: () {},
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  color: Color(0xFF4B6B50),
                  size: 18,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Hakikishia namba ya simu iliyosajili ndiyo unayotumia sasa.',
                    style: TextStyle(
                      color: Color(0xFF4B5563),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
