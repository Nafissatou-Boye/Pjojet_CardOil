// lib/screens/auth/register_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../langue/app_localizations.dart';
import '../../utils/countries.dart';
import 'otp_verification_screen.dart';

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

  Country _selectedCountry = Countries.westAfrica[0];
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _fullNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    // Validation password match
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Les mots de passe ne correspondent pas'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    final authService = Provider.of<AuthService>(context, listen: false);
    setState(() => _isLoading = true);

    try {
      // Construire le numéro complet
      final fullPhone =
          '${_selectedCountry.dialCode}${_phoneController.text.trim()}';

      // Étape 1 : Valider le téléphone et envoyer le SMS
      final validateResult = await authService.validatePhone(
        phone: fullPhone,
      );

      if (!mounted) return;

      if (validateResult['success'] == true) {
        // SMS envoyé ! Rediriger vers l'écran OTP
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OTPVerificationScreen(
              phone: fullPhone,
              fullName: _fullNameController.text.trim(),
              password: _passwordController.text.trim(),
              countryCode: _selectedCountry.code,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(validateResult['error'] ?? 'Erreur inconnue'),
          backgroundColor: Colors.red,
        ));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erreur: $e'),
        backgroundColor: Colors.red,
      ));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Scaffold(
        backgroundColor: const Color(0xFF2563EB),
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 8),
                child: Column(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      alignment: Alignment.centerLeft,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Inscription',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Créez votre compte',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),

              // Formulaire
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 24),

                          // Nom complet
                          _buildTextField(
                            controller: _fullNameController,
                            label: 'Nom complet',
                            icon: Icons.person_outline,
                            keyboardType: TextInputType.name,
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Requis' : null,
                          ),

                          const SizedBox(height: 16),

                          // Téléphone
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
                                            style:
                                                const TextStyle(fontSize: 24)),
                                        const SizedBox(width: 6),
                                        Text(_selectedCountry.dialCode,
                                            style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500)),
                                        const Icon(Icons.arrow_drop_down,
                                            color: Colors.grey),
                                      ],
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: TextFormField(
                                    controller: _phoneController,
                                    keyboardType: TextInputType.phone,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly
                                    ],
                                    decoration: const InputDecoration(
                                      hintText: 'Numéro de téléphone',
                                      border: InputBorder.none,
                                      contentPadding:
                                          EdgeInsets.symmetric(
                                              vertical: 18),
                                    ),
                                    validator: (v) => v == null || v.isEmpty
                                        ? 'Requis'
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Mot de passe
                          _buildPasswordField(
                            controller: _passwordController,
                            label: 'Mot de passe',
                            obscure: _obscurePassword,
                            onToggle: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),

                          const SizedBox(height: 16),

                          // Confirmation mot de passe
                          _buildPasswordField(
                            controller: _confirmPasswordController,
                            label: 'Confirmer le mot de passe',
                            obscure: _obscureConfirmPassword,
                            onToggle: () => setState(() =>
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword),
                          ),

                          const SizedBox(height: 32),

                          // Bouton inscription
                          SizedBox(
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _register,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white)
                                  : const Text(
                                      'S\'inscrire',
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Lien vers connexion
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Vous avez déjà un compte ?',
                                  style: TextStyle(color: Colors.grey.shade600)),
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text(
                                  'Se connecter',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2563EB)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
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

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          prefixIcon:
              const Icon(Icons.lock_outline, color: Color(0xFF9CA3AF)),
          hintText: label,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(18),
          suffixIcon: IconButton(
            icon: Icon(
              obscure
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: const Color(0xFF9CA3AF),
            ),
            onPressed: onToggle,
          ),
        ),
        validator: (v) {
          if (v == null || v.isEmpty) return 'Requis';
          if (v.length < 6) return 'Minimum 6 caractères';
          return null;
        },
      ),
    );
  }

  void _showCountryPicker() {
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
          const Text('Choisir le pays',
              style: TextStyle(
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
                      style: const TextStyle(fontWeight: FontWeight.bold)),
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
