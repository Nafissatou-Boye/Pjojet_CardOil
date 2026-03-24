// lib/screens/auth/login_screen_fixed.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../langue/app_localizations.dart';
import '../../utils/countries.dart';
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
  final _fullNameController = TextEditingController();
  final _passwordController = TextEditingController();

  Country _selectedCountry = Countries.westAfrica[0];
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _phoneController.dispose();
    _fullNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loginIndividual() async {
    final t = AppLocalizations.of(context);
    final authService = Provider.of<AuthService>(context, listen: false);

    final fullPhone =
        '${_selectedCountry.dialCode}${_phoneController.text.trim()}';
    final cleanPhone = fullPhone.replaceAll(RegExp(r'[^0-9+]'), '');

    final result = await authService.checkCredentials(
      phone: cleanPhone,
      password: _passwordController.text.trim(),
    );

    if (!mounted) return;

    if (result['success'] == true) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const ClientDashboard()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result['error'] ?? t.unknownError),
        backgroundColor: Colors.red,
      ));
    }
  }

  Future<void> _loginCorporate() async {
    final t = AppLocalizations.of(context);
    final authService = Provider.of<AuthService>(context, listen: false);

    final result = await authService.signInWithLogin(
      login: _fullNameController.text.trim(),
      password: _passwordController.text.trim(),
    );

    if (!mounted) return;

    if (result['success'] == true) {
      final user = result['user'];
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => CorporateDashboardScreen(userId: user?.uid ?? ''),
        ),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result['error'] ?? t.unknownError),
        backgroundColor: Colors.red,
      ));
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
      final t = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${t.unexpectedError}: $e'),
        backgroundColor: Colors.red,
      ));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Directionality(
      textDirection: t.textDirection,
      child: Scaffold(
        backgroundColor: const Color(0xFF2563EB),
        // ✅ FIX: resizeToAvoidBottomInset pour gérer le clavier
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: Column(
            children: [
              // Header fixe
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 8),
                child: Column(
                  children: [
                    Text(
                      t.welcomeGreeting,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      t.connectToAccount,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              
              // ✅ FIX: Container scrollable avec Expanded
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF5F7FA),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      
                      // Tabs
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Container(
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TabBar(
                            controller: _tabController,
                            indicator: BoxDecoration(
                              color: const Color(0xFF2563EB),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            labelColor: Colors.white,
                            unselectedLabelColor: Colors.grey.shade600,
                            tabs: [
                              Tab(
                                icon: const Icon(Icons.phone),
                                text: t.phoneTab,
                              ),
                              Tab(
                                icon: const Icon(Icons.person),
                                text: t.identifierTab,
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // ✅ FIX: SingleChildScrollView pour éviter overflow
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Form(
                            key: _formKey,
                            child: SizedBox(
                              height: MediaQuery.of(context).size.height * 0.5,
                              child: TabBarView(
                                controller: _tabController,
                                children: [
                                  _buildPhoneTab(t),
                                  _buildLoginTab(t),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      // Footer
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            RichText(
                              text: const TextSpan(
                                children: [
                                  TextSpan(
                                    text: '@',
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF2563EB)),
                                  ),
                                  TextSpan(
                                    text: 'Sen',
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF2563EB)),
                                  ),
                                  TextSpan(
                                    text: 'Pay',
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF9CA3AF)),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 3),
                            const Text('©',
                                style: TextStyle(
                                    fontSize: 10, color: Color(0xFF9CA3AF))),
                            Text(
                              ' ${DateTime.now().year}',
                              style: const TextStyle(
                                  fontSize: 10, color: Color(0xFF9CA3AF)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneTab(AppLocalizations t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              InkWell(
                onTap: _showCountryPicker,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 18),
                  child: Row(
                    children: [
                      Text(_selectedCountry.flag,
                          style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 6),
                      Text(_selectedCountry.dialCode,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w500)),
                      const Icon(Icons.arrow_drop_down, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    hintText: t.enterPhone,
                    border: InputBorder.none,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 18),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? t.requiredField : null,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildPasswordField(t),
        const SizedBox(height: 32),
        _buildSignInButton(t),
        const SizedBox(height: 16),
        _buildFooterLinks(t),
      ],
    );
  }

  Widget _buildLoginTab(AppLocalizations t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextFormField(
            controller: _fullNameController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              prefixIcon:
                  const Icon(Icons.person_outline, color: Color(0xFF9CA3AF)),
              hintText: t.yourIdentifier,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(18),
            ),
            validator: (v) =>
                v == null || v.isEmpty ? t.requiredField : null,
          ),
        ),
        const SizedBox(height: 16),
        _buildPasswordField(t),
        const SizedBox(height: 32),
        _buildSignInButton(t),
        const SizedBox(height: 16),
        _buildFooterLinks(t),
      ],
    );
  }

  Widget _buildPasswordField(AppLocalizations t) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextFormField(
        controller: _passwordController,
        obscureText: _obscurePassword,
        decoration: InputDecoration(
          prefixIcon:
              const Icon(Icons.lock_outline, color: Color(0xFF9CA3AF)),
          hintText: t.password,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(18),
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: const Color(0xFF9CA3AF),
            ),
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
        validator: (v) =>
            v == null || v.isEmpty ? t.requiredField : null,
      ),
    );
  }

  Widget _buildSignInButton(AppLocalizations t) {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _login,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2563EB),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                t.connect,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white),
              ),
      ),
    );
  }

  Widget _buildFooterLinks(AppLocalizations t) {
    return Column(
      children: [
        TextButton(
          onPressed: () =>
              Navigator.pushNamed(context, '/reset-password'),
          child: Text(t.forgotPasswordQ,
              style: TextStyle(color: Colors.grey.shade600)),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(t.noAccountYet,
                style: TextStyle(color: Colors.grey.shade600)),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/register'),
              child: Text(
                t.createAccount,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showCountryPicker() {
    final t = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Column(
        children: [
          const SizedBox(height: 12),
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(99))),
          const SizedBox(height: 16),
          Text(t.chooseCountry,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: Countries.westAfrica.length,
              itemBuilder: (context, index) {
                final country = Countries.westAfrica[index];
                return ListTile(
                  leading: Text(country.flag,
                      style: const TextStyle(fontSize: 32)),
                  title: Text(country.name),
                  trailing: Text(country.dialCode,
                      style:
                          const TextStyle(fontWeight: FontWeight.bold)),
                  onTap: () {
                    setState(() => _selectedCountry = country);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
