import 'package:flutter/material.dart';

import '../screens/forgot_password_page.dart';
import '../screens/register_page.dart';
import '../widgets/auth_widgets.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  static const routeName = '/';

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool rememberMe = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AuthLayout(
      child: Column(
        children: [
          const SizedBox(height: 8),
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              Container(
                height: 245,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0D6B33), Color(0xFF77B66E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(34),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: -30,
                      left: -40,
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: const BoxDecoration(
                          color: Color(0x22FFFFFF),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Positioned(
                      right: -30,
                      bottom: -20,
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: const BoxDecoration(
                          color: Color(0x22FFFFFF),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 72),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xCCFFFFFF),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Text(
                              'Mfumo wa Bei',
                              style: TextStyle(
                                color: Color(0xFF14532D),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Taarifa za Bei za Mchele na Maharage Morogoro',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Positioned(
                bottom: -55,
                child: AuthLogoBadge(size: 118),
              ),
            ],
          ),
          const SizedBox(height: 72),
          Text(
            'Ingia kwenye akaunti yako',
            style: theme.textTheme.titleMedium?.copyWith(
              color: const Color(0xFF374151),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          const AuthTextField(
            hintText: 'Namba ya simu',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 14),
          const AuthTextField(
            hintText: 'Nenosiri',
            icon: Icons.lock_outline,
            obscureText: true,
            suffixIcon: Icon(Icons.visibility_outlined, size: 20),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: rememberMe,
                  onChanged: (value) {
                    setState(() {
                      rememberMe = value ?? false;
                    });
                  },
                  activeColor: const Color(0xFF0E7A3B),
                  side: const BorderSide(color: Color(0xFFD1D5DB)),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Nikumbuke',
                style: TextStyle(
                  color: Color(0xFF4B5563),
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, ForgotPasswordPage.routeName);
                },
                child: const Text(
                  'Umesahau nenosiri?',
                  style: TextStyle(
                    color: Color(0xFF0E7A3B),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          PrimaryAuthButton(
            label: 'INGIA',
            onPressed: () {},
          ),
          const SizedBox(height: 20),
          Row(
            children: const [
              Expanded(child: Divider(color: Color(0xFFD1D5DB))),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text('au', style: TextStyle(color: Color(0xFF6B7280))),
              ),
              Expanded(child: Divider(color: Color(0xFFD1D5DB))),
            ],
          ),
          const SizedBox(height: 20),
          OutlineAuthButton(
            label: 'JISAJILI SASA',
            onPressed: () {
              Navigator.pushNamed(context, RegisterPage.routeName);
            },
          ),
        ],
      ),
    );
  }
}
