// lib/screens/auth/otp_screen.dart
//
// ✅ Écran OTP universel — Inscription ET Connexion
// Usage :
//   Navigator.push(context, MaterialPageRoute(
//     builder: (_) => OtpScreen(
//       phoneNumber: '+221771234567',
//       mode: OtpMode.login,  // ou OtpMode.register
//       onVerified: () => Navigator.pushReplacementNamed(context, '/dashboard'),
//     ),
//   ));

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/orange_sms_service.dart';

enum OtpMode { login, register }

class OtpScreen extends StatefulWidget {
  final String phoneNumber;
  final OtpMode mode;
  final VoidCallback onVerified;
  final Map<String, dynamic>? registrationData; // Pour l'inscription

  const OtpScreen({
    super.key,
    required this.phoneNumber,
    required this.mode,
    required this.onVerified,
    this.registrationData,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen>
    with SingleTickerProviderStateMixin {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
      List.generate(6, (_) => FocusNode());

  bool _isVerifying = false;
  bool _isResending = false;
  bool _codeSent = false;
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
    _sendOtp();
  }

  @override
  void dispose() {
    for (final c in _controllers) { c.dispose(); }
    for (final f in _focusNodes) { f.dispose(); }
    _shakeCtrl.dispose();
    super.dispose();
  }

  // ── Envoyer OTP ─────────────────────────────────────────────────────────
  Future<void> _sendOtp() async {
    setState(() { _isResending = true; _errorMessage = null; });

    final result = await OrangeSmsService().sendOtp(
      phoneNumber: widget.phoneNumber,
    );

    if (!mounted) return;

    if (result.success) {
      setState(() {
        _codeSent = true;
        _isResending = false;
        _resendCountdown = 60;
      });
      _startCountdown();
    } else {
      setState(() {
        _isResending = false;
        _errorMessage = result.errorMessage;
      });
    }
  }

  void _startCountdown() async {
    for (int i = 60; i >= 0; i--) {
      if (!mounted) return;
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) setState(() => _resendCountdown = i);
    }
  }

  // ── Saisie OTP ───────────────────────────────────────────────────────────
  void _onDigitChanged(int index, String value) {
    if (value.length == 1) {
      // Avancer au champ suivant
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        // Dernier chiffre → vérifier automatiquement
        _focusNodes[index].unfocus();
        _verifyOtp();
      }
    } else if (value.isEmpty && index > 0) {
      // Reculer si effacement
      _focusNodes[index - 1].requestFocus();
    }
  }

  String get _otpCode =>
      _controllers.map((c) => c.text).join();

  void _clearFields() {
    for (final c in _controllers) { c.clear(); }
    _focusNodes[0].requestFocus();
  }

  // ── Vérifier OTP ─────────────────────────────────────────────────────────
  Future<void> _verifyOtp() async {
    final code = _otpCode;
    if (code.length < 6) return;

    setState(() { _isVerifying = true; _errorMessage = null; });

    final result = await OrangeSmsService().verifyOtp(
      phoneNumber: widget.phoneNumber,
      code: code,
    );

    if (!mounted) return;

    if (result.success) {
      HapticFeedback.heavyImpact();
      // ✅ Code correct → callback (login/register géré par l'appelant)
      widget.onVerified();
    } else {
      // ❌ Code incorrect → shake + message
      HapticFeedback.vibrate();
      setState(() {
        _isVerifying = false;
        _errorMessage = result.errorMessage;
      });
      _shakeCtrl.forward(from: 0);
      _clearFields();
    }
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Bouton retour ──
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.arrow_back_ios_new,
                        size: 18, color: Color(0xFF1F2937)),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // ── Icône ──
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF2563EB), Color(0xFF3B82F6)]),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                        color: const Color(0xFF2563EB).withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8))
                  ],
                ),
                child: const Icon(Icons.sms_rounded,
                    color: Colors.white, size: 38),
              ),
              const SizedBox(height: 28),

              // ── Titre ──
              Text(
                widget.mode == OtpMode.login
                    ? 'Vérification de connexion'
                    : 'Vérification du numéro',
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF111827)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // ── Sous-titre ──
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade600,
                      height: 1.5),
                  children: [
                    const TextSpan(text: 'Code envoyé par SMS au\n'),
                    TextSpan(
                      text: _maskPhone(widget.phoneNumber),
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F2937)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // ── État envoi ──
              if (_isResending && !_codeSent)
                Column(children: [
                  const CircularProgressIndicator(
                      color: Color(0xFF2563EB), strokeWidth: 2.5),
                  const SizedBox(height: 12),
                  Text('Envoi du SMS en cours…',
                      style: TextStyle(
                          color: Colors.grey.shade500, fontSize: 14)),
                  const SizedBox(height: 40),
                ])
              else if (_errorMessage != null && !_codeSent)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200)),
                  child: Row(children: [
                    Icon(Icons.error_outline,
                        color: Colors.red.shade400, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Text(_errorMessage!,
                            style: TextStyle(
                                color: Colors.red.shade700,
                                fontSize: 13))),
                  ]),
                )
              else ...[
                // ── Champs OTP ──
                AnimatedBuilder(
                  animation: _shakeAnim,
                  builder: (_, child) {
                    final offset =
                        _shakeCtrl.isAnimating
                            ? ((_shakeAnim.value * 4).round().isEven
                                ? 8.0
                                : -8.0)
                            : 0.0;
                    return Transform.translate(
                        offset: Offset(offset, 0), child: child);
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(6, (i) => _buildDigitField(i)),
                  ),
                ),
                const SizedBox(height: 20),

                // ── Message d'erreur ──
                if (_errorMessage != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: Colors.red.shade200)),
                    child: Row(children: [
                      Icon(Icons.error_outline,
                          color: Colors.red.shade400, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(_errorMessage!,
                              style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontSize: 13))),
                    ]),
                  ),
                const SizedBox(height: 32),

                // ── Bouton vérifier ──
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: (_isVerifying || _otpCode.length < 6)
                        ? null
                        : _verifyOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      disabledBackgroundColor:
                          const Color(0xFF2563EB).withOpacity(0.4),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: _isVerifying
                        ? const SizedBox(
                            width: 22, height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5))
                        : const Text(
                            'Confirmer',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white),
                          ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Renvoyer ──
                _resendCountdown > 0
                    ? Text(
                        'Renvoyer le code dans ${_resendCountdown}s',
                        style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500),
                      )
                    : GestureDetector(
                        onTap: _isResending ? null : _sendOtp,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: _isResending
                              ? const SizedBox(
                                  width: 18, height: 18,
                                  child: CircularProgressIndicator(
                                      color: Color(0xFF2563EB),
                                      strokeWidth: 2))
                              : const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.refresh_rounded,
                                        color: Color(0xFF2563EB),
                                        size: 18),
                                    SizedBox(width: 8),
                                    Text('Renvoyer le code',
                                        style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF2563EB))),
                                  ],
                                ),
                        ),
                      ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDigitField(int index) {
    return SizedBox(
      width: 48,
      height: 60,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Color(0xFF111827)),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          counterText: '',
          contentPadding: EdgeInsets.zero,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: Color(0xFF2563EB), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.red.shade400, width: 2),
          ),
          filled: true,
          fillColor: _controllers[index].text.isNotEmpty
              ? const Color(0xFFEFF6FF)
              : Colors.grey.shade50,
        ),
        onChanged: (v) => _onDigitChanged(index, v),
      ),
    );
  }
}