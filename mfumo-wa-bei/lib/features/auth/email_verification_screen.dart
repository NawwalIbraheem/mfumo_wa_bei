import 'package:flutter/material.dart';

import '../../core/network/api_service.dart';
import 'login_screen.dart';
import 'utils/auth_validators.dart';
import 'widgets/auth_widgets.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  static const routeName = '/email-verification';

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _apiService = ApiService();

  bool _didReadArguments = false;
  bool _isVerifying = false;
  bool _isResending = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didReadArguments) {
      return;
    }

    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments is Map && arguments['email'] is String) {
      _emailController.text = arguments['email'] as String;
    }
    _didReadArguments = true;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    try {
      await _apiService.verifyEmail(
        email: _emailController.text.trim(),
        code: _codeController.text.trim(),
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Barua pepe imethibitishwa. Sasa ingia.')),
      );
      Navigator.pushNamedAndRemoveUntil(
        context,
        LoginScreen.routeName,
        (route) => false,
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
          _isVerifying = false;
        });
      }
    }
  }

  Future<void> _resendCode() async {
    final emailError = AuthValidators.emailRequired(_emailController.text);
    if (emailError != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(emailError)));
      return;
    }

    setState(() {
      _isResending = true;
    });

    try {
      await _apiService.resendEmailVerification(
        email: _emailController.text.trim(),
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kodi mpya imetumwa kwenye barua pepe.')),
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
          _isResending = false;
        });
      }
    }
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
                title: 'Thibitisha barua pepe',
                subtitle: 'Weka kodi ya tarakimu 6 uliyotumiwa',
              ),
            ),
            const SizedBox(height: 22),
            const AuthLogoBadge(size: 120),
            const SizedBox(height: 24),
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
              controller: _codeController,
              hintText: 'Kodi ya uthibitisho',
              icon: Icons.verified_user_outlined,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              validator: AuthValidators.verificationCode,
              maxLength: 6,
            ),
            const SizedBox(height: 18),
            PrimaryAuthButton(
              label: _isVerifying ? 'INATHIBITISHA...' : 'THIBITISHA',
              onPressed: _isVerifying ? () {} : _verify,
            ),
            const SizedBox(height: 12),
            OutlineAuthButton(
              label: _isResending ? 'INATUMA...' : 'TUMA KODI MPYA',
              onPressed: _isResending ? () {} : _resendCode,
            ),
            const SizedBox(height: 18),
            GestureDetector(
              onTap: () {
                Navigator.pushReplacementNamed(context, LoginScreen.routeName);
              },
              child: const Text(
                'Rudi kuingia',
                style: TextStyle(
                  color: Color(0xFF0E7A3B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
