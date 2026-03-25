// lib/screens/auth/register_screen.dart
// ✅ CORRECTIONS :
//   1. API pays : champs réels → nomPays, indicatif, drapeau (URL image)
//   2. Drapeau affiché via Image.network() si URL, sinon emoji de fallback
//   3. Sélection par défaut Sénégal (code SN ou nomPays contient 'égal')
//   4. Tous les textes traduits via t.xxx

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../services/auth_service.dart';
import '../../langue/app_localizations.dart';
import 'otp_verification_screen.dart';
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

  // ── Chargement initial ─────────────────────────────────────────────────────
  Future<void> _loadInitialData() async {
    try {
      final results = await Future.wait([
        _fetchCompanies(),
        _fetchCountries(),
      ]);

      if (mounted) {
        setState(() {
          _companies = results[0];
          _countries = results[1];
          _isLoadingData = false;

          // Sélectionner Sénégal par défaut
          if (_countries.isNotEmpty) {
            _selectedCountry = _countries.firstWhere(
              (c) =>
                  (c['nomPays'] ?? '').toLowerCase().contains('égal') ||
                  (c['nomPays'] ?? '').toLowerCase().contains('senegal') ||
                  (c['indicatif'] ?? '') == '+221',
              orElse: () => _countries[0],
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingData = false);
        _showError('Erreur chargement: $e');
      }
    }
  }

  // ── GET /api/auth/companies ────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> _fetchCompanies() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.cardoil.io/api/auth/companies'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
        return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } catch (e) {
      print('❌ _fetchCompanies: $e');
    }
    return [];
  }

  // ── GET /api/pays ──────────────────────────────────────────────────────────
  // Réponse : { id, nomPays, indicatif, devise, drapeau (URL), icone (URL) }
  Future<List<Map<String, dynamic>>> _fetchCountries() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.cardoil.io/api/pays'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
        return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } catch (e) {
      print('❌ _fetchCountries: $e');
    }
    return [];
  }

  // ── Helpers accès champs pays ──────────────────────────────────────────────
  // nomPays → nom affiché
  String _countryName(Map<String, dynamic> c) =>
      c['nomPays']?.toString() ?? c['nom']?.toString() ?? '';

  // indicatif → ex: +221
  String _countryDial(Map<String, dynamic> c) =>
      c['indicatif']?.toString() ?? '+221';

  // drapeau → URL image (peut être null ou vide)
  String? _countryFlag(Map<String, dynamic> c) {
    final url = c['drapeau']?.toString() ?? c['icone']?.toString() ?? '';
    return url.isNotEmpty ? url : null;
  }

  // Widget drapeau : image réseau si URL dispo, sinon emoji fallback
  Widget _flagWidget(Map<String, dynamic> c, {double size = 28}) {
    final url = _countryFlag(c);
    if (url != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: Image.network(
          url,
          width: size,
          height: size * 0.67,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Text('🌍', style: TextStyle(fontSize: size * 0.75)),
        ),
      );
    }
    // Emoji fallback depuis le nom du pays
    final emoji = _emojiFromName(_countryName(c));
    return Text(emoji, style: TextStyle(fontSize: size * 0.75));
  }

  // Emoji de secours selon nom pays
  String _emojiFromName(String name) {
    final n = name.toLowerCase();
    if (n.contains('sénégal') || n.contains('senegal')) return '🇸🇳';
    if (n.contains('gambie') || n.contains('gambia')) return '🇬🇲';
    if (n.contains('mali')) return '🇲🇱';
    if (n.contains('mauritanie')) return '🇲🇷';
    if (n.contains('guinée') || n.contains('guinea')) return '🇬🇳';
    if (n.contains('côte') || n.contains('ivoire')) return '🇨🇮';
    if (n.contains('maroc')) return '🇲🇦';
    if (n.contains('algérie')) return '🇩🇿';
    if (n.contains('tunisie')) return '🇹🇳';
    return '🌍';
  }

  // ── Inscription ────────────────────────────────────────────────────────────
  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final t = AppLocalizations.of(context);

    if (_selectedCompany == null) {
      _showError(t.mustSelectCompany);
      return;
    }
    if (!_acceptTerms) {
      _showError(t.mustAcceptTerms);
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      _showError(t.passwordMismatch);
      return;
    }

    final authService = Provider.of<AuthService>(context, listen: false);
    setState(() => _isLoading = true);

    try {
      final dial = _countryDial(_selectedCountry ?? {});
      final fullPhone = '$dial${_phoneController.text.trim()}';

      final validateResult = await authService.validatePhone(phone: fullPhone);

      if (!mounted) return;

      if (validateResult['success'] == true) {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => OTPVerificationScreen(
            phone: fullPhone,
            fullName: _fullNameController.text.trim(),
            password: _passwordController.text.trim(),
            countryCode: _selectedCountry?['id']?.toString() ?? 'SN',
            companyId: _selectedCompany!['id']?.toString() ?? '1',
          ),
        ));
      } else {
        _showError(validateResult['error'] ?? t.unknownError);
      }
    } catch (e) {
      if (!mounted) return;
      _showError('${AppLocalizations.of(context).unexpectedError}: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  bool get _canSubmit => _acceptTerms && !_isLoading && _selectedCompany != null;

  // ── BUILD ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    if (_isLoadingData) {
      return const Scaffold(
        backgroundColor: Color(0xFF2563EB),
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Directionality(
      textDirection: t.textDirection,
      child: Scaffold(
        backgroundColor: const Color(0xFF2563EB),
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: Column(children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
              child: Column(children: [
                Row(children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                ]),
                const SizedBox(height: 8),
                Text(t.inscription,
                    style: const TextStyle(
                        fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 4),
                Text(t.fillFormToRegister,
                    style: const TextStyle(fontSize: 13, color: Colors.white70)),
              ]),
            ),

            // Formulaire blanc
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      const SizedBox(height: 16),

                      // Nom complet
                      _buildTextField(
                        controller: _fullNameController,
                        label: t.fullName,
                        icon: Icons.person_outline,
                        validator: (v) => v == null || v.isEmpty ? t.requiredField : null,
                      ),
                      const SizedBox(height: 14),

                      // Téléphone avec drapeau
                      _buildPhoneField(t),
                      const SizedBox(height: 14),

                      // Compagnie
                      _buildCompanySelector(t),
                      const SizedBox(height: 14),

                      // Mot de passe
                      _buildPasswordField(
                        controller: _passwordController,
                        label: t.password,
                        obscure: _obscurePassword,
                        onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
                        t: t,
                      ),
                      const SizedBox(height: 14),

                      // Confirmation
                      _buildPasswordField(
                        controller: _confirmPasswordController,
                        label: t.confirmPassword,
                        obscure: _obscureConfirmPassword,
                        onToggle: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                        t: t,
                      ),
                      const SizedBox(height: 20),

                      // Checkbox politique
                      _buildPrivacyCheckbox(t),
                      const SizedBox(height: 24),

                      // Bouton
                      _buildSubmitButton(t),
                      const SizedBox(height: 16),

                      // Lien connexion
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text(t.alreadyHaveAccount,
                            style: TextStyle(color: Colors.grey.shade600)),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(t.connect,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                        ),
                      ]),
                    ]),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // ── Champ téléphone avec drapeau ─────────────────────────────────────────
  Widget _buildPhoneField(AppLocalizations t) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        // ✅ Sélecteur pays avec drapeau API
        InkWell(
          onTap: () => _showCountryPicker(t),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              // ✅ Drapeau depuis URL API
              if (_selectedCountry != null)
                _flagWidget(_selectedCountry!, size: 30)
              else
                const Text('🌍', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 6),
              Text(
                _selectedCountry != null
                    ? _countryDial(_selectedCountry!)
                    : '+221',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const Icon(Icons.arrow_drop_down, color: Colors.grey, size: 20),
            ]),
          ),
        ),
        // Séparateur vertical
        Container(width: 1, height: 36, color: Colors.grey.shade200),
        // Champ numéro
        Expanded(
          child: TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              hintText: t.enterPhone,
              hintStyle: TextStyle(color: Colors.grey.shade400),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
            ),
            validator: (v) => v == null || v.isEmpty ? t.requiredField : null,
          ),
        ),
      ]),
    );
  }

  // ── Sélecteur compagnie ───────────────────────────────────────────────────
  Widget _buildCompanySelector(AppLocalizations t) {
    return GestureDetector(
      onTap: () => _showCompanyPicker(t),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _selectedCompany != null
              ? const Color(0xFF2563EB).withOpacity(0.06)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _selectedCompany != null
                ? const Color(0xFF2563EB).withOpacity(0.3)
                : Colors.transparent,
          ),
        ),
        child: Row(children: [
          Icon(Icons.local_gas_station,
              color: _selectedCompany != null
                  ? const Color(0xFFDC2626)
                  : const Color(0xFF9CA3AF),
              size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _selectedCompany?['nom'] ??
                  _selectedCompany?['name'] ??
                  t.selectCompany,
              style: TextStyle(
                fontSize: 15,
                fontWeight: _selectedCompany != null ? FontWeight.w600 : FontWeight.normal,
                color: _selectedCompany != null
                    ? const Color(0xFF1F2937)
                    : const Color(0xFF9CA3AF),
              ),
            ),
          ),
          Icon(
            _selectedCompany != null ? Icons.check_circle : Icons.keyboard_arrow_down,
            color: _selectedCompany != null
                ? const Color(0xFF10B981)
                : const Color(0xFF9CA3AF),
            size: 22,
          ),
        ]),
      ),
    );
  }

  // ── Checkbox politique ────────────────────────────────────────────────────
  Widget _buildPrivacyCheckbox(AppLocalizations t) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _acceptTerms
            ? const Color(0xFF10B981).withOpacity(0.05)
            : const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _acceptTerms ? const Color(0xFF10B981) : Colors.grey.shade300,
          width: 1.5,
        ),
      ),
      child: Row(children: [
        Checkbox(
          value: _acceptTerms,
          onChanged: (v) => setState(() => _acceptTerms = v!),
          activeColor: const Color(0xFF10B981),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _acceptTerms = !_acceptTerms),
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 13, color: Color(0xFF1F2937)),
                children: [
                  TextSpan(text: '${t.iAccept} '),
                  WidgetSpan(
                    child: GestureDetector(
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen())),
                      child: Text(t.readPrivacy,
                          style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF2563EB),
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ]),
    );
  }

  // ── Bouton soumettre ──────────────────────────────────────────────────────
  Widget _buildSubmitButton(AppLocalizations t) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 56,
      decoration: BoxDecoration(
        gradient: _canSubmit
            ? const LinearGradient(colors: [Color(0xFF1D4ED8), Color(0xFF2563EB)])
            : null,
        color: _canSubmit ? null : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(14),
        boxShadow: _canSubmit
            ? [BoxShadow(
                color: const Color(0xFF2563EB).withOpacity(0.4),
                blurRadius: 14,
                offset: const Offset(0, 6))]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _canSubmit ? _register : null,
          borderRadius: BorderRadius.circular(14),
          child: Center(
            child: _isLoading
                ? const SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : Text(t.register,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: _canSubmit ? Colors.white : Colors.grey.shade500,
                    )),
          ),
        ),
      ),
    );
  }

  // ── Champ texte générique ─────────────────────────────────────────────────
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: const Color(0xFF9CA3AF)),
          hintText: label,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(18),
        ),
        validator: validator,
      ),
    );
  }

  // ── Champ mot de passe ────────────────────────────────────────────────────
  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
    required AppLocalizations t,
  }) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF9CA3AF)),
          hintText: label,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(18),
          suffixIcon: IconButton(
            icon: Icon(
              obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: const Color(0xFF9CA3AF),
            ),
            onPressed: onToggle,
          ),
        ),
        validator: (v) {
          if (v == null || v.isEmpty) return t.requiredField;
          if (v.length < 6) return t.min6chars;
          return null;
        },
      ),
    );
  }

  // ── Sélecteur pays avec drapeaux API ──────────────────────────────────────
  void _showCountryPicker(AppLocalizations t) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (context, scrollController) => Column(children: [
          const SizedBox(height: 12),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
                color: Colors.grey.shade300, borderRadius: BorderRadius.circular(99)),
          ),
          const SizedBox(height: 16),
          Text(t.chooseCountry,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Expanded(
            child: _countries.isEmpty
                ? Center(child: Text(t.loadingError,
                    style: TextStyle(color: Colors.grey.shade500)))
                : ListView.builder(
                    controller: scrollController,
                    itemCount: _countries.length,
                    itemBuilder: (context, index) {
                      final country = _countries[index];
                      final isSelected =
                          _selectedCountry?['id'] == country['id'];
                      return ListTile(
                        // ✅ Drapeau depuis URL API
                        leading: _flagWidget(country, size: 32),
                        title: Text(
                          _countryName(country),
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                            color: isSelected
                                ? const Color(0xFF2563EB)
                                : const Color(0xFF1F2937),
                          ),
                        ),
                        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                          Text(_countryDial(country),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2563EB))),
                          if (isSelected) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.check_circle,
                                color: Color(0xFF10B981), size: 18),
                          ],
                        ]),
                        onTap: () {
                          setState(() => _selectedCountry = country);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
          ),
        ]),
      ),
    );
  }

  // ── Sélecteur compagnie ───────────────────────────────────────────────────
  void _showCompanyPicker(AppLocalizations t) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.5,
        maxChildSize: 0.85,
        minChildSize: 0.3,
        builder: (context, scrollController) => Column(children: [
          const SizedBox(height: 12),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
                color: Colors.grey.shade300, borderRadius: BorderRadius.circular(99)),
          ),
          const SizedBox(height: 16),
          Text(t.chooseCompany,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(t.canChangeLater,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
          const SizedBox(height: 16),
          Expanded(
            child: _companies.isEmpty
                ? Center(child: Text(t.loadingError,
                    style: TextStyle(color: Colors.grey.shade500)))
                : ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _companies.length,
                    itemBuilder: (context, index) {
                      final company = _companies[index];
                      final isSelected = _selectedCompany?['id'] == company['id'];
                      final name = company['nom']?.toString() ??
                          company['name']?.toString() ?? '';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF2563EB).withOpacity(0.08)
                              : const Color(0xFFF5F7FA),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF2563EB)
                                : Colors.grey.shade200,
                          ),
                        ),
                        child: ListTile(
                          leading: const Icon(Icons.local_gas_station,
                              color: Color(0xFFDC2626)),
                          title: Text(name,
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? const Color(0xFF2563EB)
                                    : const Color(0xFF1F2937),
                              )),
                          trailing: isSelected
                              ? const Icon(Icons.check_circle,
                                  color: Color(0xFF10B981))
                              : null,
                          onTap: () {
                            setState(() => _selectedCompany = company);
                            Navigator.pop(context);
                          },
                        ),
                      );
                    },
                  ),
          ),
        ]),
      ),
    );
  }
}