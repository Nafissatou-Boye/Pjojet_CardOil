import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/auth_service.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String phone;
  final String fullName;
  final String password;
  final String countryCode;
  final String companyId;

 
  final void Function(String otpCode)? onVerified;

  const OTPVerificationScreen({
    super.key,
    required this.phone,
    required this.fullName,
    required this.password,
    required this.countryCode,
    required this.companyId,
    this.onVerified,
  });

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen>
    with SingleTickerProviderStateMixin {
  final _authService = AuthService();

  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isVerifying = false;
  bool _isResending = false;
  String? _errorMessage;
  int _resendCountdown = 60;

  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(_shakeCtrl);
    _startCountdown();
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    _shakeCtrl.dispose();
    super.dispose();
  }

  void _startCountdown() async {
    for (int i = 60; i >= 0; i--) {
      if (!mounted) return;
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) setState(() => _resendCountdown = i);
    }
  }

  Future<void> _resendCode() async {
    setState(() { _isResending = true; _errorMessage = null; });
    final result = await _authService.resendOtp(phone: widget.phone);
    if (!mounted) return;
    setState(() => _isResending = false);
    if (result['success'] == true) {
      setState(() => _resendCountdown = 60);
      _startCountdown();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Code renvoyé avec succès'), backgroundColor: Colors.green));
    } else {
      setState(() => _errorMessage = result['error']?.toString());
    }
  }

  void _onDigitChanged(int index, String value) {
    if (value.length == 1) {
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        _verifyCode();
      }
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  String get _otpCode => _controllers.map((c) => c.text).join();

  void _clearFields() {
    for (final c in _controllers) c.clear();
    _focusNodes[0].requestFocus();
  }

 
  Future<void> _verifyCode() async {
    final code = _otpCode;
    if (code.length < 6) return;

    setState(() { _isVerifying = true; _errorMessage = null; });

   
    if (widget.onVerified != null) {
      HapticFeedback.heavyImpact();
      setState(() => _isVerifying = false);
      widget.onVerified!(code);
      return;
    }

   
    setState(() => _isVerifying = false);
    HapticFeedback.heavyImpact();
    if (mounted) Navigator.pop(context, code);
  }

  String _maskPhone(String phone) {
    if (phone.length < 4) return phone;
    return '${phone.substring(0, phone.length - 4)}****';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 40, 28, 28),
          child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.arrow_back_ios_new, size: 18, color: Color(0xFF1F2937))),
              ),
            ),
            const SizedBox(height: 40),
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF3B82F6)]),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: const Color(0xFF2563EB).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))]),
              child: const Icon(Icons.sms_rounded, color: Colors.white, size: 38)),
            const SizedBox(height: 28),
            const Text('Vérification du numéro',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF111827)),
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: TextStyle(fontSize: 15, color: Colors.grey.shade600, height: 1.5),
                children: [
                  const TextSpan(text: 'Code envoyé par SMS au\n'),
                  TextSpan(text: _maskPhone(widget.phone),
                      style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1F2937))),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Champs OTP avec shake
            AnimatedBuilder(
              animation: _shakeAnim,
              builder: (_, child) {
                final offset = _shakeCtrl.isAnimating
                    ? ((_shakeAnim.value * 4).round().isEven ? 8.0 : -8.0) : 0.0;
                return Transform.translate(offset: Offset(offset, 0), child: child);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, _buildDigitField)),
            ),
            const SizedBox(height: 20),

            if (_errorMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50, borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200)),
                child: Row(children: [
                  Icon(Icons.error_outline, color: Colors.red.shade400, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_errorMessage!,
                      style: TextStyle(color: Colors.red.shade700, fontSize: 13))),
                ])),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity, height: 56,
              child: ElevatedButton(
                onPressed: (_isVerifying || _otpCode.length < 6) ? null : _verifyCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  disabledBackgroundColor: const Color(0xFF2563EB).withOpacity(0.4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0),
                child: _isVerifying
                    ? const SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : const Text('Confirmer',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 24),

            _resendCountdown > 0
                ? Text('Renvoyer le code dans ${_resendCountdown}s',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500))
                : GestureDetector(
                    onTap: _isResending ? null : _resendCode,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(12)),
                      child: _isResending
                          ? const SizedBox(width: 18, height: 18,
                              child: CircularProgressIndicator(color: Color(0xFF2563EB), strokeWidth: 2))
                          : const Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(Icons.refresh_rounded, color: Color(0xFF2563EB), size: 18),
                              SizedBox(width: 8),
                              Text('Renvoyer le code',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF2563EB))),
                            ]),
                    ),
                  ),
          ]),
        ),
      ),
    );
  }

  Widget _buildDigitField(int index) {
    return SizedBox(
      width: 48, height: 60,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF111827)),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          counterText: '', contentPadding: EdgeInsets.zero,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2)),
          filled: true,
          fillColor: _controllers[index].text.isNotEmpty
              ? const Color(0xFFEFF6FF) : Colors.grey.shade50),
        onChanged: (v) => _onDigitChanged(index, v),
      ),
    );
  }
}