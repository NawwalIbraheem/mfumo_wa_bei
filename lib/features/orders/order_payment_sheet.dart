import 'dart:async';
import 'package:flutter/material.dart';

import '../../core/network/api_service.dart';

class OrderPaymentSheet extends StatefulWidget {
  const OrderPaymentSheet({
    super.key,
    required this.token,
    required this.orderId,
    required this.totalAmount,
    this.initialPhoneNumber,
    this.listingTitle,
  });

  final String token;
  final String orderId;
  final String totalAmount;
  final String? initialPhoneNumber;
  final String? listingTitle;

  static Future<bool?> show(
    BuildContext context, {
    required String token,
    required String orderId,
    required String totalAmount,
    String? initialPhoneNumber,
    String? listingTitle,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => OrderPaymentSheet(
        token: token,
        orderId: orderId,
        totalAmount: totalAmount,
        initialPhoneNumber: initialPhoneNumber,
        listingTitle: listingTitle,
      ),
    );
  }

  @override
  State<OrderPaymentSheet> createState() => _OrderPaymentSheetState();
}

enum _PaymentStep { input, processing, success, failed }

class _OrderPaymentSheetState extends State<OrderPaymentSheet> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _phoneController;

  _PaymentStep _step = _PaymentStep.input;
  String? _errorMessage;
  String? _statusMessage;
  Timer? _statusPollTimer;
  int _pollCount = 0;
  static const int _maxPolls = 12; // 36 seconds max polling

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(
      text: widget.initialPhoneNumber ?? '',
    );
  }

  @override
  void dispose() {
    _statusPollTimer?.cancel();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _initiatePayment() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _step = _PaymentStep.processing;
      _errorMessage = null;
      _statusMessage = 'Inatuma ombi la malipo kwenye simu yako...';
    });

    try {
      final response = await _apiService.initiateOrderPayment(
        token: widget.token,
        orderId: widget.orderId,
        phoneNumber: _phoneController.text.trim(),
      );

      final message = response['message']?.toString() ??
          'Ombi la malipo (USSD-PUSH) limetumwa kwenye simu yako. Tafadhali thibitisha kwa PIN.';
      if (!mounted) return;

      setState(() {
        _statusMessage = message;
      });

      _startPollingPaymentStatus();
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _step = _PaymentStep.failed;
        _errorMessage = error.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _step = _PaymentStep.failed;
        _errorMessage = 'Kuna hitilafu imetokea wakati wa kuanzisha malipo.';
      });
    }
  }

  void _startPollingPaymentStatus() {
    _pollCount = 0;
    _statusPollTimer?.cancel();
    _statusPollTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      _pollCount++;
      if (_pollCount > _maxPolls) {
        timer.cancel();
        if (mounted && _step == _PaymentStep.processing) {
          setState(() {
            _statusMessage =
                'Uthibitishaji unachukua muda. Unaweza kuangalia hali ya oda yako baadaye.';
          });
        }
        return;
      }

      try {
        final statusData = await _apiService.getOrderPaymentStatus(
          token: widget.token,
          orderId: widget.orderId,
        );

        final orderStatus = statusData['order_status']?.toString().toLowerCase();
        final payment = statusData['payment'];
        final paymentStatus = (payment is Map<String, dynamic>
                ? payment['status']?.toString()
                : null)
            ?.toLowerCase();

        if (orderStatus == 'paid' ||
            orderStatus == 'confirmed' ||
            paymentStatus == 'success') {
          timer.cancel();
          if (mounted) {
            setState(() {
              _step = _PaymentStep.success;
              _statusMessage = 'Malipo yamekamilika kikamilifu! Oda yako imethibitishwa.';
            });
          }
        } else if (paymentStatus == 'failed' || orderStatus == 'cancelled') {
          timer.cancel();
          if (mounted) {
            setState(() {
              _step = _PaymentStep.failed;
              _errorMessage =
                  payment is Map<String, dynamic> && payment['failure_message'] != null
                      ? payment['failure_message'].toString()
                      : 'Malipo yameshindikana au yameghairiwa.';
            });
          }
        }
      } catch (_) {
        // Continue polling
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        8,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _step == _PaymentStep.success
                ? 'Malipo Yamekamilika!'
                : 'Lipa kwa Simu (Mobile Money)',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF17221B),
            ),
          ),
          const SizedBox(height: 8),

          // Order summary banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF7FAF8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5EBE7)),
            ),
            child: Column(
              children: [
                if (widget.listingTitle != null && widget.listingTitle!.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Bidhaa:',
                        style: TextStyle(fontSize: 13, color: Color(0xFF66736B)),
                      ),
                      Flexible(
                        child: Text(
                          widget.listingTitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF17221B),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Namba ya Oda:',
                      style: TextStyle(fontSize: 13, color: Color(0xFF66736B)),
                    ),
                    Text(
                      '#${widget.orderId}',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF17221B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Jumla ya Malipo:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF17221B),
                      ),
                    ),
                    Text(
                      'TSh ${_formatPrice(widget.totalAmount)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0E7A3B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (_step == _PaymentStep.input) ...[
            // Providers list
            const Text(
              'Mitandao Inayoungwa Mkono:',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF66736B),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildProviderPill('HaloPesa', const Color(0xFFE8F5E9)),
                const SizedBox(width: 8),
                _buildProviderPill('Mixx by Yas', const Color(0xFFFFF3E0)),
                const SizedBox(width: 8),
                _buildProviderPill('Airtel Money', const Color(0xFFFFEBEE)),
              ],
            ),
            const SizedBox(height: 16),

            Form(
              key: _formKey,
              child: TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Namba ya Simu',
                  hintText: 'Mfano: 0712345678 au 0687...',
                  prefixIcon: const Icon(Icons.phone_android_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Tafadhali weka namba ya simu ya kulipia.';
                  }
                  final digits = value.replaceAll(RegExp(r'\D'), '');
                  if (digits.length < 9) {
                    return 'Namba ya simu si sahihi.';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Baada ya kubonyeza "Lipa Sasa", utapokea ombi la USSD (pop-up) kwenye simu yako. Weka namba yako ya siri (PIN) kukamilisha.',
              style: TextStyle(fontSize: 12, color: Color(0xFF66736B)),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _initiatePayment,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0E7A3B),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Lipa Sasa',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ] else if (_step == _PaymentStep.processing) ...[
            const SizedBox(height: 12),
            const Center(
              child: SizedBox(
                height: 48,
                width: 48,
                child: CircularProgressIndicator(
                  strokeWidth: 3.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0E7A3B)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _statusMessage ?? 'Inasubiri uthibitisho wa PIN kwenye simu yako...',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF17221B),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tafadhali angalia simu yako na uweke PIN kukamilisha malipo.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Color(0xFF66736B)),
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: () => Navigator.pop(context, true),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Funga (Fuatilia Baadaye)'),
            ),
          ] else if (_step == _PaymentStep.success) ...[
            const SizedBox(height: 12),
            const Center(
              child: Icon(
                Icons.check_circle_rounded,
                size: 64,
                color: Color(0xFF0E7A3B),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _statusMessage ?? 'Malipo yamethibitishwa kikamilifu!',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0E7A3B),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0E7A3B),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Sawa',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ] else if (_step == _PaymentStep.failed) ...[
            const SizedBox(height: 12),
            const Center(
              child: Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: Colors.redAccent,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Malipo yameshindikana.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.redAccent,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Ghairi'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      setState(() {
                        _step = _PaymentStep.input;
                        _errorMessage = null;
                      });
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0E7A3B),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Jaribu Tena'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProviderPill(String label, Color bg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF17221B),
          ),
        ),
      ),
    );
  }

  String _formatPrice(String value) {
    final parsed = double.tryParse(value.replaceAll(',', ''));
    if (parsed == null) return value;
    final integer = parsed.round().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < integer.length; i++) {
      final remaining = integer.length - i;
      buffer.write(integer[i]);
      if (remaining > 1 && remaining % 3 == 1) {
        buffer.write(',');
      }
    }
    return buffer.toString();
  }
}
