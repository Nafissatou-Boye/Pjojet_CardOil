// lib/screens/client/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../services/auth_service.dart';
import '../../langue/app_localizations.dart';
import '../../models/models.dart';
import 'privacy_policy_screen.dart';


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? _user;
  bool _loading = true;
  String? _companyName;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final result = await authService.loadUserProfile();
    if (!mounted) return;

    final user = result['success'] == true ? result['user'] as UserModel : null;

    if (user != null && user.selectedCompagnie.isNotEmpty) {
      final name = await _fetchCompanyName(user.selectedCompagnie);
      if (mounted) setState(() => _companyName = name);
    }

    setState(() {
      _user = user;
      _loading = false;
    });
  }

  Future<String?> _fetchCompanyName(String companyId) async {
    try {
      final r = await http.get(
        Uri.parse('https://api.cardoil.io/api/auth/companies'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (r.statusCode == 200) {
        final list = jsonDecode(r.body) as List;
        final found = list.firstWhere(
          (c) => c['id']?.toString() == companyId,
          orElse: () => null,
        );
        return found?['name']?.toString() ?? found?['nom']?.toString();
      }
    } catch (_) {}
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final t = AppLocalizations.of(context);

    return Directionality(
      textDirection: t.textDirection,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: Text(t.profileTitle),
          backgroundColor: const Color(0xFF2563EB),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _user == null
                ? Center(child: Text(t.notConnected))
                : _buildBody(context, authService, t),
      ),
    );
  }

  Widget _buildBody(BuildContext context, AuthService authService, AppLocalizations t) {
    final user = _user!;

    return SingleChildScrollView(
      child: Column(children: [
        // ── Header ──────────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF1E40AF)]),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
          ),
          child: Column(children: [
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                color: Colors.white, shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              child: Center(
                child: Text(
                  user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
                  style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(user.fullName,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            Text(user.phone,
                style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.9))),
            const SizedBox(height: 8),
            // ✅ Badge compagnie
            if (_companyName != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.local_gas_station, color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  Text(_companyName!,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ]),
              ),
          ]),
        ),

        const SizedBox(height: 24),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(t.informations,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            // ✅ Nom complet
            _buildInfoCard(
              icon: Icons.person_outline,
              title: 'Nom complet',
              value: user.fullName.isNotEmpty ? user.fullName : '—',
              color: Colors.indigo,
            ),
            const SizedBox(height: 12),

            // ✅ Téléphone
            _buildInfoCard(
              icon: Icons.phone_outlined,
              title: 'Téléphone',
              value: user.phone.isNotEmpty ? user.phone : '—',
              color: Colors.teal,
            ),
            const SizedBox(height: 12),

            // ✅ Compagnie préférée
            _buildInfoCard(
              icon: Icons.local_gas_station,
              title: t.preferredCompany,
              value: _companyName ?? (user.selectedCompagnie.isNotEmpty ? user.selectedCompagnie : '—'),
              color: Colors.blue,
            ),
            const SizedBox(height: 12),

            // ✅ Points fidélité
            _buildInfoCard(
              icon: Icons.star_outline,
              title: 'Points fidélité',
              value: '${user.currentCompanyPoints} pts',
              color: Colors.amber,
            ),
            const SizedBox(height: 12),

            // ✅ Statut
            _buildInfoCard(
              icon: Icons.verified_user,
              title: t.status,
              value: user.phoneVerified ? t.statusVerified : t.statusNotVerified,
              color: user.phoneVerified ? Colors.green : Colors.orange,
            ),

            if (user.qrCode.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildInfoCard(
                icon: Icons.qr_code_2,
                title: t.qrCode,
                value: user.qrCode,
                color: Colors.purple,
              ),
            ],

            const SizedBox(height: 12),

           _buildActionButton(context,
              icon: Icons.lock_outline,
              title: 'Changer le mot de passe',
              onTap: () => _changePassword(context)),
          ]),
        ),
     
        const SizedBox(height: 12),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(children: [
            _buildActionButton(context,
              icon: Icons.help_outline, title: t.helpCenter, onTap: () {}),
            const SizedBox(height: 12),
            _buildActionButton(context,
              icon: Icons.info_outline, title: t.about,
              onTap: () => showAboutDialog(
                context: context,
                applicationName: 'Card Oil',
                applicationVersion: '1.0.0',
                applicationLegalese: t.appVersion,
              )),

              const SizedBox(height: 12),

_buildActionButton(
  context,
  icon: Icons.privacy_tip_outlined,
  title: t.privacyTitle,
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const PrivacyPolicyScreen(),
      ),
    );
  },
),

            const SizedBox(height: 12),
            _buildActionButton(context,
              icon: Icons.logout, title: t.logout, color: Colors.red,
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) {
                    final td = AppLocalizations.of(context);
                    return AlertDialog(
                      title: Text(td.logoutConfirmTitle),
                      content: Text(td.logoutConfirmContent),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(td.cancel)),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(td.disconnect, style: const TextStyle(color: Colors.red))),
                      ],
                    );
                  },
                );
                if (confirm == true && context.mounted) {
                  await authService.signOut();
                  Navigator.pushReplacementNamed(context, '/welcome');
                }
              }),
          ]),
        ),
        const SizedBox(height: 32),
      ]),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Row(children: [
        Container(
          width: 50, height: 50,
          decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color),
        ),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ])),
      ]),
    );
  }

Future<void> _changePassword(BuildContext context) async {
  final oldCtrl = TextEditingController();
  final newCtrl = TextEditingController();
  final confCtrl = TextEditingController();
  bool obsOld = true, obsNew = true, obsConf = true;
  String? errMsg;
  bool isLoading = false;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, set) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            const Text('Changer le mot de passe',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
            const SizedBox(height: 20),

            if (errMsg != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10)),
                child: Text(errMsg!, style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13))),
              const SizedBox(height: 12),
            ],

            _pwdField(oldCtrl, 'Mot de passe actuel', obsOld, () => set(() => obsOld = !obsOld)),
            const SizedBox(height: 12),
            _pwdField(newCtrl, 'Nouveau mot de passe (4 chiffres)', obsNew, () => set(() => obsNew = !obsNew)),
            const SizedBox(height: 12),
            _pwdField(confCtrl, 'Confirmer', obsConf, () => set(() => obsConf = !obsConf)),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : () async {
                  set(() => errMsg = null);
                  if (newCtrl.text != confCtrl.text) {
                    set(() => errMsg = 'Mots de passe différents'); return;
                  }
                  if (newCtrl.text.length != 4) {
                    set(() => errMsg = 'Le mot de passe doit faire exactement 4 chiffres'); return;
                  }
                  set(() => isLoading = true);

                  try {
                    final authService = Provider.of<AuthService>(context, listen: false);
                    final token = await authService.getToken();
                    if (token == null) { set(() => errMsg = 'Non connecté'); return; }

                    final user = _user!;
                    final response = await http.put(
                      Uri.parse('https://api.cardoil.io/api/users'),
                      headers: {
                        'Content-Type': 'application/json',
                        'Authorization': 'Bearer $token',
                      },
                      body: jsonEncode({
                        'id': user.id,
                        'generatedPassword': newCtrl.text,
                        'password': newCtrl.text,
                      }),
                    ).timeout(const Duration(seconds: 15));

                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(response.statusCode == 200
                              ? 'Mot de passe modifié avec succès'
                              : 'Erreur lors du changement'),
                          backgroundColor: response.statusCode == 200
                              ? Colors.green : Colors.red,
                          behavior: SnackBarBehavior.floating,
                        ));
                    }
                  } catch (e) {
                    set(() => errMsg = 'Erreur réseau: $e');
                  } finally {
                    set(() => isLoading = false);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: isLoading
                    ? const SizedBox(height: 20, width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Confirmer',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
          ]),
        ),
      ),
    ),
  );
}

Widget _pwdField(TextEditingController c, String label, bool obs, VoidCallback toggle) {
  return TextField(
    controller: c,
    obscureText: obs,
    keyboardType: TextInputType.number,
    maxLength: 4,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    decoration: InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF9CA3AF)),
      counterText: '',
      filled: true,
      fillColor: const Color(0xFFF5F7FA),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      suffixIcon: IconButton(
        icon: Icon(obs ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            color: const Color(0xFF9CA3AF)),
        onPressed: toggle)),
  );
}
  Widget _buildActionButton(BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
        ),
        child: Row(children: [
          Icon(icon, color: color ?? Colors.grey.shade700),
          const SizedBox(width: 16),
          Expanded(child: Text(title,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: color ?? Colors.black87))),
          Icon(Icons.chevron_right, color: Colors.grey.shade400),
        ]),
      ),
    );
  }
}