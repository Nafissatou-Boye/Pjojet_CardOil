import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../services/auth_service.dart';
import '../../langue/app_localizations.dart';
import 'otp_verification_screen.dart';
import '../client/client_dashboard.dart';
import '../client/privacy_policy_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  List<Map<String, dynamic>> _companies = [];
  List<Map<String, dynamic>> _countries = [];
  Map<String, dynamic>? _selectedCompany;
  Map<String, dynamic>? _selectedCountry;

  bool _isLoading = false;
  bool _isLoadingData = true;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _fullNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() { _isLoadingData = true; _loadError = null; });
    try {
      final results = await Future.wait([_fetchCompanies(), _fetchCountries()]);
      if (mounted) {
        setState(() {
          _companies = results[0];
          _countries = results[1];
          _isLoadingData = false;
          if (_countries.isNotEmpty) {
            _selectedCountry = _countries.firstWhere(
              (c) {
                final nom = (c['nomPays'] ?? c['nom'] ?? '').toString().toLowerCase();
                return nom.contains('sénégal') || nom.contains('senegal') ||
                    c['indicatif']?.toString() == '+221';
              },
              orElse: () => _countries.first,
            );
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() { _isLoadingData = false; _loadError = 'Erreur de connexion.'; });
    }
  }

  Future<List<Map<String, dynamic>>> _fetchCompanies() async {
    try {
      final r = await http.get(Uri.parse('https://api.cardoil.io/api/auth/companies'),
          headers: {'Accept': 'application/json'}).timeout(const Duration(seconds: 15));
      if (r.statusCode == 200) {
        final d = jsonDecode(r.body);
        final list = d is List ? d : (d['data'] ?? d['companies'] ?? []) as List;
        return list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<List<Map<String, dynamic>>> _fetchCountries() async {
    try {
      final r = await http.get(Uri.parse('https://api.cardoil.io/api/pays'),
          headers: {'Accept': 'application/json'}).timeout(const Duration(seconds: 15));
      if (r.statusCode == 200) {
        final d = jsonDecode(r.body);
        final list = d is List ? d : (d['data'] ?? d['pays'] ?? []) as List;
        return list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (_) {}
    return [];
  }

 
  String _countryName(Map<String, dynamic> c) =>
      c['nomPays']?.toString() ?? c['nom']?.toString() ?? '';
  String _countryDial(Map<String, dynamic> c) => c['indicatif']?.toString() ?? '+221';
  String _getFlagEmoji(Map<String, dynamic> c) {
    final code = c['code']?.toString().toUpperCase() ?? '';
    if (code.length == 2) {
      return String.fromCharCode(code.codeUnitAt(0) - 0x41 + 0x1F1E6) +
          String.fromCharCode(code.codeUnitAt(1) - 0x41 + 0x1F1E6);
    }
    final n = _countryName(c).toLowerCase();
    if (n.contains('sénégal') || n.contains('senegal')) return '🇸🇳';
    if (n.contains('mali')) return '🇲🇱';
    if (n.contains('gambie')) return '🇬🇲';
    return '🌍';
  }

 
  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCompany == null) { _showError('Sélectionnez une compagnie'); return; }
    if (!_acceptTerms) { _showError('Acceptez les conditions'); return; }
    if (_passwordController.text != _confirmPasswordController.text) {
      _showError('Les mots de passe ne correspondent pas'); return;
    }

    final authService = Provider.of<AuthService>(context, listen: false);
    setState(() => _isLoading = true);

    try {
      final dial = _countryDial(_selectedCountry ?? {});
      final fullPhone = '$dial${_phoneController.text.trim()}';

      final validateResult = await authService.validatePhone(phone: fullPhone);
      if (!mounted) return;

      if (validateResult['success'] != true) {
        _showError(validateResult['error']?.toString() ?? 'Erreur envoi SMS');
        return;
      }

      
      if (validateResult['skipOtp'] == true) {
        await _doSignup(authService: authService, phone: fullPhone, otpCode: '000000');
        return;
      }

     
      if (mounted) {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => OTPVerificationScreen(
            phone: fullPhone,
            fullName: _fullNameController.text.trim(),
            password: _passwordController.text.trim(),
            countryCode: _selectedCountry?['code']?.toString() ?? 'SN',
            companyId: _selectedCompany!['id']?.toString() ?? '1',
            // ✅ onVerified reçoit le code et déclenche le signup
            onVerified: (String otpCode) => _doSignup(
              authService: authService,
              phone: fullPhone,
              otpCode: otpCode,
            ),
          ),
        ));
      }
    } catch (e) {
      if (!mounted) return;
      _showError('Erreur: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }


  Future<void> _doSignup({
    required AuthService authService,
    required String phone,
    required String otpCode,
  }) async {
    // Montrer un spinner pendant le signup
    if (mounted) {
      showDialog(context: context, barrierDismissible: false,
          builder: (_) => const Center(
              child: CircularProgressIndicator(color: Color(0xFF2563EB))));
    }

    final result = await authService.signupWithOtp(
      phone: phone,
      fullName: _fullNameController.text.trim(),
      password: _passwordController.text.trim(),
      countryCode: _selectedCountry?['code']?.toString() ?? 'SN',
      otpCode: otpCode,
      companyId: _selectedCompany!['id']?.toString() ?? '1',
    );

    if (!mounted) return;

    
    Navigator.of(context, rootNavigator: true).pop();

    if (result['success'] == true) {
      if (result['requiresLogin'] == true) {
        // ✅ Compte créé mais pas de token → retour login avec message
        Navigator.of(context).popUntil((route) => route.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result['message']?.toString() ?? 'Compte créé ! Connectez-vous.'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ));
      } else {
        
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const ClientDashboard()),
          (route) => false,
        );
      }
    } else {
     
      if (Navigator.canPop(context)) Navigator.pop(context);
      _showError(result['error']?.toString() ?? 'Erreur lors de l\'inscription');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg), backgroundColor: Colors.red,
      behavior: SnackBarBehavior.floating, margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
  }

  bool get _canSubmit => _acceptTerms && !_isLoading && _selectedCompany != null;


  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    if (_isLoadingData) {
      return const Scaffold(
        backgroundColor: Color(0xFF2563EB),
        body: Center(child: CircularProgressIndicator(color: Colors.white)));
    }

    if (_loadError != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF2563EB),
        body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.cloud_off, color: Colors.white, size: 64),
          const SizedBox(height: 16),
          Text(_loadError!, style: const TextStyle(color: Colors.white, fontSize: 16), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: _loadInitialData, child: const Text('Réessayer')),
          TextButton(onPressed: () => Navigator.pop(context),
              child: const Text('Retour', style: TextStyle(color: Colors.white70))),
        ])));
    }

    return Directionality(
      textDirection: t.textDirection,
      child: Scaffold(
        backgroundColor: const Color(0xFF2563EB),
        resizeToAvoidBottomInset: true,
        body: SafeArea(child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
            child: Column(children: [
              Row(children: [
                IconButton(onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.white))]),
              const SizedBox(height: 8),
              Text(t.inscription, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 4),
              Text(t.fillFormToRegister, style: const TextStyle(fontSize: 13, color: Colors.white70)),
            ]),
          ),

          Expanded(child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF5F7FA),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32))),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const SizedBox(height: 16),

                // Nom complet
                _buildTextField(
                  controller: _fullNameController, label: t.fullName,
                  icon: Icons.person_outline,
                  validator: (v) => (v?.isEmpty ?? true) ? t.requiredField : null),
                const SizedBox(height: 14),

                // Téléphone
                _buildPhoneField(),
                const SizedBox(height: 14),

                // Compagnie
                _buildCompanySelector(),
                const SizedBox(height: 14),

                // Mot de passe
                _buildPasswordField(
                  controller: _passwordController, label: t.password,
                  obscure: _obscurePassword,
                  onToggle: () => setState(() => _obscurePassword = !_obscurePassword)),
                const SizedBox(height: 14),

                // Confirmation
                _buildPasswordField(
                  controller: _confirmPasswordController, label: t.confirmPassword,
                  obscure: _obscureConfirmPassword,
                  onToggle: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword)),
                const SizedBox(height: 20),

                _buildPrivacyCheckbox(),
                const SizedBox(height: 24),
                _buildSubmitButton(),
                const SizedBox(height: 16),

                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(t.alreadyHaveAccount, style: TextStyle(color: Colors.grey.shade600)),
                  TextButton(onPressed: () => Navigator.pop(context),
                      child: Text(t.connect,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB)))),
                ]),
              ])),
            ),
          )),
        ])),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String? Function(String?) validator,
  }) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: TextFormField(controller: controller,
        decoration: InputDecoration(prefixIcon: Icon(icon, color: const Color(0xFF9CA3AF)),
            hintText: label, border: InputBorder.none, contentPadding: const EdgeInsets.all(18)),
        validator: validator));
  }

  Widget _buildPhoneField() {
    final flag = _selectedCountry != null ? _getFlagEmoji(_selectedCountry!) : '🇸🇳';
    final dial = _selectedCountry != null ? _countryDial(_selectedCountry!) : '+221';
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        InkWell(
          onTap: _countries.isEmpty ? null : _showCountryPicker,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(flag, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 6),
              Text(dial, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const Icon(Icons.arrow_drop_down, color: Colors.grey, size: 20),
            ])),
        ),
        Container(width: 1, height: 36, color: Colors.grey.shade200),
        Expanded(child: TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(hintText: '77 838 01 35',
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 18)),
          validator: (v) => (v?.isEmpty ?? true) ? 'Requis' : null)),
      ]));
  }

  Widget _buildCompanySelector() {
    final name = _selectedCompany?['nom']?.toString() ?? _selectedCompany?['name']?.toString();
    return GestureDetector(
      onTap: _companies.isEmpty ? null : _showCompanyPicker,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _selectedCompany != null ? const Color(0xFF2563EB).withOpacity(0.06) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: _selectedCompany != null
              ? Border.all(color: const Color(0xFF2563EB).withOpacity(0.3)) : null),
        child: Row(children: [
          Icon(Icons.local_gas_station,
              color: _selectedCompany != null ? const Color(0xFFDC2626) : const Color(0xFF9CA3AF),
              size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(
            _companies.isEmpty ? 'Chargement...' : (name ?? 'Sélectionner la compagnie'),
            style: TextStyle(fontSize: 15,
                fontWeight: _selectedCompany != null ? FontWeight.w600 : FontWeight.normal,
                color: _selectedCompany != null ? const Color(0xFF1F2937) : const Color(0xFF9CA3AF)))),
          Icon(_selectedCompany != null ? Icons.check_circle : Icons.keyboard_arrow_down,
              color: _selectedCompany != null ? const Color(0xFF10B981) : const Color(0xFF9CA3AF),
              size: 22),
        ])));
  }

  Widget _buildPrivacyCheckbox() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _acceptTerms ? const Color(0xFF10B981).withOpacity(0.05) : const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: _acceptTerms ? const Color(0xFF10B981) : Colors.grey.shade300, width: 1.5)),
      child: Row(children: [
        Checkbox(value: _acceptTerms, onChanged: (v) => setState(() => _acceptTerms = v ?? false),
            activeColor: const Color(0xFF10B981)),
        Expanded(child: GestureDetector(
          onTap: () => setState(() => _acceptTerms = !_acceptTerms),
          child: RichText(text: TextSpan(
            style: const TextStyle(fontSize: 13, color: Color(0xFF1F2937)),
            children: [
              const TextSpan(text: "J'accepte la "),
              WidgetSpan(child: GestureDetector(
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen())),
                child: const Text('politique de confidentialité',
                    style: TextStyle(fontSize: 13, color: Color(0xFF2563EB),
                        fontWeight: FontWeight.w600, decoration: TextDecoration.underline)))),
            ])),
        )),
      ]));
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: TextFormField(
        controller: controller, obscureText: obscure,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF9CA3AF)),
          hintText: label, border: InputBorder.none, contentPadding: const EdgeInsets.all(18),
          suffixIcon: IconButton(
            icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: const Color(0xFF9CA3AF)),
            onPressed: onToggle)),
        validator: (v) {
          if (v?.isEmpty ?? true) return 'Requis';
          if ((v?.length ?? 0) < 6) return 'Minimum 6 caractères';
          return null;
        }));
  }

  Widget _buildSubmitButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200), height: 56,
      decoration: BoxDecoration(
        gradient: _canSubmit ? const LinearGradient(colors: [Color(0xFF1D4ED8), Color(0xFF2563EB)]) : null,
        color: _canSubmit ? null : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(14),
        boxShadow: _canSubmit
            ? [BoxShadow(color: const Color(0xFF2563EB).withOpacity(0.4), blurRadius: 14, offset: const Offset(0, 6))]
            : []),
      child: Material(color: Colors.transparent, child: InkWell(
        onTap: _canSubmit ? _register : null,
        borderRadius: BorderRadius.circular(14),
        child: Center(child: _isLoading
            ? const SizedBox(width: 22, height: 22,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
            : Text("S'inscrire", style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
                color: _canSubmit ? Colors.white : Colors.grey.shade500))))));
  }

  void _showCountryPicker() {
    showModalBottomSheet(context: context, backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false, initialChildSize: 0.6, maxChildSize: 0.9, minChildSize: 0.4,
        builder: (_, sc) => Column(children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(99))),
          const SizedBox(height: 16),
          const Text('Indicatif pays', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Expanded(child: ListView.builder(
            controller: sc, itemCount: _countries.length,
            itemBuilder: (_, i) {
              final c = _countries[i];
              return ListTile(
                leading: Text(_getFlagEmoji(c), style: const TextStyle(fontSize: 28)),
                title: Text(_countryName(c)),
                trailing: Text(_countryDial(c),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                onTap: () { setState(() => _selectedCountry = c); Navigator.pop(ctx); },
              );
            })),
        ])));
  }

  void _showCompanyPicker() {
    showModalBottomSheet(context: context, backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false, initialChildSize: 0.5, maxChildSize: 0.85, minChildSize: 0.3,
        builder: (_, sc) => Column(children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(99))),
          const SizedBox(height: 16),
          const Text('Choisir la compagnie', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          Text('Vous pourrez changer plus tard',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
          const SizedBox(height: 12),
          Expanded(child: ListView.builder(
            controller: sc, padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _companies.length,
            itemBuilder: (_, i) {
              final co = _companies[i];
              final isSelected = _selectedCompany?['id'] == co['id'];
              final name = co['nom']?.toString() ?? co['name']?.toString() ?? 'Compagnie';
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF2563EB).withOpacity(0.08) : const Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isSelected ? const Color(0xFF2563EB) : Colors.grey.shade200)),
                child: ListTile(
                  leading: const Icon(Icons.local_gas_station, color: Color(0xFFDC2626)),
                  title: Text(name, style: TextStyle(
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF1F2937))),
                  trailing: isSelected ? const Icon(Icons.check_circle, color: Color(0xFF10B981)) : null,
                  onTap: () { setState(() => _selectedCompany = co); Navigator.pop(ctx); },
                ));
            })),
        ])));
  }
}