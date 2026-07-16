import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../utils/auth_validators.dart';
import '../widgets/auth_widgets.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  static const routeName = '/forgot-password';

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _apiService = ApiService();

  bool isSubmitting = false;
  String? resetCode;

  @override
  void dispose() {
    _identifierController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      final data = await _apiService.requestPasswordReset(
        identifier: _identifierController.text.trim(),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        resetCode = data['reset_code']?.toString();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Msimbo umetumwa kwa mafanikio.')),
      );
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
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
              'Weka barua pepe au namba ya simu',
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
            AuthTextField(
              controller: _identifierController,
              hintText: 'Barua pepe au namba ya simu',
              icon: Icons.alternate_email,
              keyboardType: TextInputType.emailAddress,
              validator: AuthValidators.emailOrPhone,
              maxLength: 254,
            ),
            const SizedBox(height: 18),
            PrimaryAuthButton(
              label: isSubmitting ? 'INATUMA...' : 'TUMA MSIMBO',
              onPressed: isSubmitting ? () {} : _submit,
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Color(0xFF4B6B50),
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      resetCode == null
                          ? 'Hakikishia umetumia barua pepe au namba ya simu iliyosajiliwa.'
                          : 'Msimbo wa majaribio: $resetCode',
                      style: const TextStyle(
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
      ),
    );
  }
}
