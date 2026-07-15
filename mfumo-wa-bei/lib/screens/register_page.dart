import 'package:flutter/material.dart';

import '../screens/login_page.dart';
import '../widgets/auth_widgets.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  static const routeName = '/register';

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  bool acceptedTerms = false;

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      showBack: true,
      child: Column(
        children: [
          const SizedBox(height: 4),
          const Center(
            child: PageTitleBlock(
              title: 'Jisajili',
              subtitle: 'Unda akaunti mpya',
            ),
          ),
          const SizedBox(height: 22),
          const AuthLogoBadge(size: 120),
          const SizedBox(height: 24),
          const AuthTextField(
            hintText: 'Jina kamili',
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 14),
          const AuthTextField(
            hintText: 'Namba ya simu',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 14),
          const AuthTextField(
            hintText: 'Barua pepe (hiari)',
            icon: Icons.mail_outline,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 14),
          const AuthTextField(
            hintText: 'Nenosiri',
            icon: Icons.lock_outline,
            obscureText: true,
            suffixIcon: Icon(Icons.visibility_outlined, size: 20),
          ),
          const SizedBox(height: 14),
          const AuthTextField(
            hintText: 'Thibitisha nenosiri',
            icon: Icons.lock_outline,
            obscureText: true,
            suffixIcon: Icon(Icons.visibility_outlined, size: 20),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: acceptedTerms,
                  onChanged: (value) {
                    setState(() {
                      acceptedTerms = value ?? false;
                    });
                  },
                  activeColor: const Color(0xFF0E7A3B),
                  side: const BorderSide(color: Color(0xFFD1D5DB)),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Padding(
                  padding: EdgeInsets.only(top: 3),
                  child: Text.rich(
                    TextSpan(
                      text: 'Nakubali ',
                      style: TextStyle(
                        color: Color(0xFF4B5563),
                        fontSize: 13,
                      ),
                      children: [
                        TextSpan(
                          text: 'Sheria na Masharti',
                          style: TextStyle(
                            color: Color(0xFF0E7A3B),
                            fontWeight: FontWeight.w600,
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
          PrimaryAuthButton(
            label: 'JISAJILI',
            onPressed: () {},
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Tayari una akaunti? ',
                style: TextStyle(color: Color(0xFF6B7280)),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.pushReplacementNamed(context, LoginPage.routeName);
                },
                child: const Text(
                  'Ingia hapa',
                  style: TextStyle(
                    color: Color(0xFF0E7A3B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
