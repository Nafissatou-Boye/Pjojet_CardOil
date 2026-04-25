// lib/screens/auth/login_screen.dart
// ✅ Adapté à tous les écrans — plus de SizedBox(height fixe)
//    TabBarView dans un Expanded avec LayoutBuilder

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../langue/app_localizations.dart';
import '../../models/country_model.dart';
import '../../models/models.dart';
import '../client/client_dashboard.dart';
import '../corporate/corporate_dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  CountryModel _selectedCountry = CountryModel(
    id: 0,
    nomPays: "Sénégal",
    indicatif: "+221",
    devise: "XOF",
    drapeau: "🇸🇳",
    icone: "",
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _phoneController.dispose();
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── Redirection par rôle ────────────────────────────────────────────────
  void _redirectByRole(UserModel user) {
    final role = (user.role ?? '').toUpperCase().trim();
    print('🔀 Redirection pour role: $role');

Widget destination;
switch (role) {
  case 'EMPLOYE':
  case 'CLIENT_ENTREPRISE':
    destination = CorporateDashboardScreen(userId: user.stringId);
    print('→ Corporate Dashboard');
    break;
  case 'CLIENT':
  default:
    destination = const ClientDashboard();
    print('→ Client Dashboard');
}

Navigator.pushAndRemoveUntil(
  context,
  MaterialPageRoute(builder: (_) => destination),
  (route) => false,
);
  }

  Future<void> _loginIndividual() async {
    final t = AppLocalizations.of(context);
    final authService = Provider.of<AuthService>(context, listen: false);

    final fullPhone = '${_selectedCountry.indicatif}${_phoneController.text.trim()}';
    final cleanPhone = fullPhone.replaceAll(RegExp(r'[^0-9+]'), '');

    final result = await authService.checkCredentials(
        phone: cleanPhone, password: _passwordController.text.trim());

    if (!mounted) return;
    if (result['success'] == true) {
      _redirectByRole(result['user'] as UserModel);
    } else {
      _showError(result['error'] ?? t.unknownError);
    }
  }

  Future<void> _loginCorporate() async {
    final t = AppLocalizations.of(context);
    final authService = Provider.of<AuthService>(context, listen: false);

    final result = await authService.signInWithLogin(
        login: _loginController.text.trim(),
        password: _passwordController.text.trim());

    if (!mounted) return;
    if (result['success'] == true && result['user'] != null) {
      _redirectByRole(result['user'] as UserModel);
    } else {
      _showError(result['error'] ?? t.unknownError);
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      if (_tabController.index == 0) {
        await _loginIndividual();
      } else {
        await _loginCorporate();
      }
    } catch (e) {
      if (!mounted) return;
      _showError('Erreur: $e');
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

  // ── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Directionality(
      textDirection: t.textDirection,
      child: Scaffold(
        backgroundColor: const Color(0xFF2563EB),
        // ✅ resizeToAvoidBottomInset gère le clavier
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: Column(children: [
            // ── Header bleu ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
              child: Column(children: [
                Text(t.welcomeGreeting,
                    style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                const SizedBox(height: 4),
                Text(t.connectToAccount,
                    style: const TextStyle(fontSize: 14, color: Colors.white70)),
              ]),
            ),

            // ── Corps blanc scrollable ─────────────────────────────────────
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(28))),
                // ✅ SingleChildScrollView pour éviter l'overflow sur petits écrans
                child: SingleChildScrollView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // ── Tabs ─────────────────────────────────────────
                          Container(
                            height: 56,
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12)),
                            child: TabBar(
                              controller: _tabController,
                              indicator: BoxDecoration(
                                  color: const Color(0xFF2563EB),
                                  borderRadius: BorderRadius.circular(12)),
                              labelColor: Colors.white,
                              unselectedLabelColor: Colors.grey.shade600,
                              labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                              tabs: [
                                Tab(icon: const Icon(Icons.phone, size: 18), text: t.phoneTab),
                                Tab(icon: const Icon(Icons.badge_outlined, size: 18), text: t.identifierTab),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // ── Contenu des tabs ──────────────────────────────
                          // ✅ SizedBox avec hauteur fixe REMPLACÉ par AnimatedBuilder
                          _TabContent(
                            tabController: _tabController,
                            phoneTab: _buildPhoneTab(t),
                            loginTab: _buildLoginTab(t),
                          ),

                          const SizedBox(height: 20),

                          // ── Bouton connexion ──────────────────────────────
                          SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                                disabledBackgroundColor:
                                    const Color(0xFF2563EB).withOpacity(0.5),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                elevation: 0),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 22, height: 22,
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2.5))
                                  : Text(t.connect,
                                      style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white)),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // ── Liens footer ──────────────────────────────────
                          Center(
                            child: TextButton(
                              onPressed: () =>
                                  Navigator.pushNamed(context, '/reset-password'),
                              child: Text(t.forgotPasswordQ,
                                  style: TextStyle(color: Colors.grey.shade600)),
                            ),
                          ),
                          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Text(t.noAccountYet,
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                            TextButton(
                              onPressed: () => Navigator.pushNamed(context, '/register'),
                              child: Text(t.createAccount,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2563EB),
                                      fontSize: 14)),
                            ),
                          ]),

                          // ── Footer brand ──────────────────────────────────
                          Center(
                            child: RichText(
                              text: const TextSpan(children: [
                                TextSpan(
                                    text: '@SenPay',
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF2563EB))),
                                TextSpan(
                                    text: ' ©',
                                    style: TextStyle(
                                        fontSize: 10, color: Color(0xFF9CA3AF))),
                              ]),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildPhoneTab(AppLocalizations t) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      // Champ téléphone
      Container(
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          InkWell(
            onTap: () {}, // Country picker
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(_selectedCountry.drapeau,
                    style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 4),
                Text(_selectedCountry.indicatif,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
                const Icon(Icons.arrow_drop_down, color: Colors.grey, size: 20),
              ]),
            ),
          ),
          Container(width: 1, height: 32, color: Colors.grey.shade200),
          Expanded(
            child: TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                  hintText: t.enterPhone,
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 16)),
              validator: (v) => v == null || v.isEmpty ? t.requiredField : null,
            ),
          ),
        ]),
      ),
      const SizedBox(height: 14),
      _buildPasswordField(t),
    ]);
  }

  Widget _buildLoginTab(AppLocalizations t) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Container(
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: TextFormField(
          controller: _loginController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
              prefixIcon:
                  const Icon(Icons.badge_outlined, color: Color(0xFF9CA3AF)),
              hintText: t.yourIdentifier,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16)),
          validator: (v) => v == null || v.isEmpty ? t.requiredField : null,
        ),
      ),
      const SizedBox(height: 14),
      _buildPasswordField(t),
    ]);
  }

  Widget _buildPasswordField(AppLocalizations t) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: TextFormField(
        controller: _passwordController,
        obscureText: _obscurePassword,
        decoration: InputDecoration(
          prefixIcon:
              const Icon(Icons.lock_outline, color: Color(0xFF9CA3AF)),
          hintText: t.password,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
          suffixIcon: IconButton(
            icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: const Color(0xFF9CA3AF)),
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
        validator: (v) => v == null || v.isEmpty ? t.requiredField : null,
      ),
    );
  }
}

// ── Widget qui switche entre les 2 tabs sans SizedBox fixe ────────────────────
class _TabContent extends StatefulWidget {
  final TabController tabController;
  final Widget phoneTab;
  final Widget loginTab;
  const _TabContent({
    required this.tabController,
    required this.phoneTab,
    required this.loginTab,
  });

  @override
  State<_TabContent> createState() => _TabContentState();
}

class _TabContentState extends State<_TabContent> {
  @override
  void initState() {
    super.initState();
    widget.tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    // ✅ AnimatedSwitcher pour transition fluide sans height fixe
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: widget.tabController.index == 0
          ? KeyedSubtree(key: const ValueKey('phone'), child: widget.phoneTab)
          : KeyedSubtree(key: const ValueKey('login'), child: widget.loginTab),
    );
  }
}