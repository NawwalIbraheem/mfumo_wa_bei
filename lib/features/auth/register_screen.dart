import 'package:flutter/material.dart';

import '../../core/network/api_service.dart';
import 'utils/auth_validators.dart';
import 'widgets/auth_widgets.dart';
import 'email_verification_screen.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  static const routeName = '/register';

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _apiService = ApiService();

  bool acceptedTerms = false;
  bool isSubmitting = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (!acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kubali sheria na masharti kwanza.')),
      );
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      await _apiService.register(
        fullName: _fullNameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        passwordConfirmation: _confirmPasswordController.text,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Usajili umefanikiwa. Weka kodi ya uthibitisho.'),
        ),
      );
      Navigator.pushReplacementNamed(
        context,
        EmailVerificationScreen.routeName,
        arguments: {'email': _emailController.text.trim()},
      );
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  String? _confirmPasswordValidator(String? value) {
    return AuthValidators.confirmPassword(value, _passwordController.text);
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      showBack: true,
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            const SizedBox(height: 4),
            const Center(
              child: ScreenTitleBlock(
                title: 'Jisajili',
                subtitle: 'Unda akaunti mpya',
              ),
            ),
            const SizedBox(height: 22),
            const AuthLogoBadge(size: 120),
            const SizedBox(height: 24),
            AuthTextField(
              controller: _fullNameController,
              hintText: 'Jina kamili',
              icon: Icons.person_outline,
              textInputAction: TextInputAction.next,
              validator: AuthValidators.fullName,
              maxLength: 150,
            ),
            const SizedBox(height: 14),
            AuthTextField(
              controller: _phoneController,
              hintText: 'Namba ya simu',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              validator: AuthValidators.phoneNumber,
            ),
            const SizedBox(height: 14),
            AuthTextField(
              controller: _emailController,
              hintText: 'Barua pepe',
              icon: Icons.mail_outline,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: AuthValidators.emailRequired,
              maxLength: 254,
            ),
            const SizedBox(height: 14),
            AuthTextField(
              controller: _passwordController,
              hintText: 'Nenosiri',
              icon: Icons.lock_outline,
              obscureText: true,
              textInputAction: TextInputAction.next,
              validator: AuthValidators.password,
            ),
            const SizedBox(height: 14),
            AuthTextField(
              controller: _confirmPasswordController,
              hintText: 'Thibitisha nenosiri',
              icon: Icons.lock_outline,
              obscureText: true,
              textInputAction: TextInputAction.done,
              validator: _confirmPasswordValidator,
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
              label: isSubmitting ? 'INAJISAJILI...' : 'JISAJILI',
              onPressed: isSubmitting ? () {} : _submit,
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
                    Navigator.pushReplacementNamed(
                      context,
                      LoginScreen.routeName,
                    );
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
      ),
    );
  }
}
