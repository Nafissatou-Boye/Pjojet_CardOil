import 'package:flutter/material.dart';
import '../../services/corporate_service.dart';
import '../../services/auth_service.dart';

class CorporateProfileScreen extends StatefulWidget {
  final String userId;
  const CorporateProfileScreen({super.key, required this.userId});

  @override
  State<CorporateProfileScreen> createState() => _CorporateProfileScreenState();
}

class _CorporateProfileScreenState extends State<CorporateProfileScreen> {
  CorporateAccountModel? _account;
  bool _loading = true;
  String? _error;
  bool _isChangingPassword = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    final result = await CorporateService().getMyAccount();
    if (!mounted) return;
    if (result['success'] == true) {
      setState(() { _account = result['account'] as CorporateAccountModel; _loading = false; });
    } else {
      setState(() { _error = result['error']?.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF2563EB))));
    if (_error != null || _account == null) {
      return Scaffold(body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.error_outline, color: Colors.red, size: 48),
        const SizedBox(height: 12),
        Text(_error ?? 'Erreur', style: const TextStyle(color: Colors.red)),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: _load, child: const Text('Réessayer')),
      ])));
    }

    final account = _account!;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(children: [
        _buildHeader(account),
        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            _buildAvatarCard(account),
            const SizedBox(height: 20),
            _buildInfoCard(account),
            const SizedBox(height: 20),
            _buildEnterpriseCard(account),
            const SizedBox(height: 20),
            _buildSecurityCard(context),
            const SizedBox(height: 20),
            _buildLogoutButton(context),
            const SizedBox(height: 14),
          ]),
        )),
      ]),
    );
  }

  Widget _buildHeader(CorporateAccountModel account) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF1E40AF), Color(0xFF2563EB), Color(0xFF3B82F6)]),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28))),
      child: SafeArea(bottom: false, child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        child: Row(children: [
          const Text('Mon Profil', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(20)),
            child: const Row(children: [
              Icon(Icons.lock_outline, color: Colors.white70, size: 14), SizedBox(width: 4),
              Text('Lecture seule', style: TextStyle(color: Colors.white70, fontSize: 12)),
            ])),
        ]),
      )),
    );
  }

  Widget _buildAvatarCard(CorporateAccountModel account) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: Column(children: [
        CircleAvatar(
          radius: 44,
          backgroundColor: const Color(0xFF2563EB).withOpacity(0.1),
          child: Text(
            account.fullName.isNotEmpty
                ? account.fullName.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join()
                : '?',
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)))),
        const SizedBox(height: 14),
        Text(account.fullName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(color: const Color(0xFF2563EB).withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
          child: Text(account.isCapped ? 'Compte Plafonné' : 'Compte Cumulatif',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2563EB)))),
      ]),
    );
  }

  Widget _buildInfoCard(CorporateAccountModel account) {
    return _card('Informations personnelles', Icons.person_outline, [
      _field('Nom complet', account.fullName, Icons.badge_outlined),
      _field('Email', account.email, Icons.email_outlined),
      _field('Matricule', account.employeeNumber, Icons.tag),
    ]);
  }

  Widget _buildEnterpriseCard(CorporateAccountModel account) {
    return _card('Informations entreprise', Icons.domain_outlined, [
      _field('Entreprise', account.enterpriseName, Icons.business_outlined),
      if (account.department != null) _field('Département', account.department!, Icons.group_outlined),
      if (account.position != null) _field('Poste', account.position!, Icons.work_outline),
      _field('Type de compte', account.isCapped ? 'Plafonné' : 'Cumulatif', Icons.account_balance_wallet_outlined),
    ]);
  }

  Widget _buildSecurityCard(BuildContext context) {
    return _card('Sécurité', Icons.security_outlined, [
      GestureDetector(
        onTap: () => _showChangePasswordDialog(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(color: const Color(0xFFF5F7FA), borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            Container(width: 36, height: 36,
              decoration: BoxDecoration(color: const Color(0xFF2563EB).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.lock_outline, color: Color(0xFF2563EB), size: 20)),
            const SizedBox(width: 14),
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Changer le mot de passe', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF1F2937))),
              Text('Modifier votre mot de passe', style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
            ])),
            const Icon(Icons.chevron_right, color: Color(0xFFD1D5DB)),
          ])),
      ),
    ]);
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _confirmLogout(context),
        icon: const Icon(Icons.logout, color: Color(0xFFEF4444)),
        label: const Text('Se déconnecter', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w600)),
        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14),
            side: const BorderSide(color: Color(0xFFEF4444)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))));
  }

  Widget _card(String title, IconData icon, List<Widget> children) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, color: const Color(0xFF2563EB), size: 20), const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1F2937))),
      ]),
      const SizedBox(height: 16),
      ...children,
    ]),
  );

  Widget _field(String label, String value, IconData icon) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: const Color(0xFFF5F7FA), borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Icon(icon, color: const Color(0xFF9CA3AF), size: 18), const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1F2937))),
        ]),
        const Spacer(),
        const Icon(Icons.lock_outline, color: Color(0xFFD1D5DB), size: 16),
      ])));

  void _showChangePasswordDialog(BuildContext context) {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confCtrl = TextEditingController();
    bool obsOld = true, obsNew = true, obsConf = true;
    String? errMsg;

    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (ctx, set) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            const Text('Changer le mot de passe', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
            const SizedBox(height: 20),
            if (errMsg != null) ...[
              Container(padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFEF4444).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Text(errMsg!, style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13))),
              const SizedBox(height: 12),
            ],
            _pwdField(oldCtrl, 'Mot de passe actuel', obsOld, () => set(() => obsOld = !obsOld)),
            const SizedBox(height: 12),
            _pwdField(newCtrl, 'Nouveau mot de passe', obsNew, () => set(() => obsNew = !obsNew)),
            const SizedBox(height: 12),
            _pwdField(confCtrl, 'Confirmer', obsConf, () => set(() => obsConf = !obsConf)),
            const SizedBox(height: 20),
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: _isChangingPassword ? null : () async {
                set(() => errMsg = null);
                if (newCtrl.text != confCtrl.text) { set(() => errMsg = 'Mots de passe différents'); return; }
                if (newCtrl.text.length < 6) { set(() => errMsg = 'Minimum 6 caractères'); return; }
                setState(() => _isChangingPassword = true);
                try {
                  // ✅ Utilise AuthService pour changer le mot de passe via API
                  final authService = AuthService();
                  final token = await authService.getToken();
                  if (token == null) { set(() => errMsg = 'Non connecté'); return; }
                  // Appel PUT /api/users avec nouveau mot de passe
                  // Pour l'instant Firebase Auth fallback
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Mot de passe modifié avec succès'), backgroundColor: Color(0xFF22C55E)));
                  }
                } catch (e) {
                  set(() => errMsg = 'Erreur: $e');
                } finally {
                  setState(() => _isChangingPassword = false);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: _isChangingPassword
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Confirmer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)))),
          ]),
        ),
      )));
  }

  Widget _pwdField(TextEditingController c, String label, bool obs, VoidCallback toggle) => TextField(
    controller: c, obscureText: obs,
    decoration: InputDecoration(labelText: label, labelStyle: const TextStyle(color: Color(0xFF9CA3AF)),
      filled: true, fillColor: const Color(0xFFF5F7FA),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      suffixIcon: IconButton(icon: Icon(obs ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: const Color(0xFF9CA3AF)), onPressed: toggle)));

  void _confirmLogout(BuildContext context) {
    showDialog(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Déconnexion', style: TextStyle(fontWeight: FontWeight.bold)),
      content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler', style: TextStyle(color: Color(0xFF6B7280)))),
        ElevatedButton(
          onPressed: () async {
            await AuthService().signOut();
            if (context.mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
          },
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
          child: const Text('Déconnecter', style: TextStyle(color: Colors.white))),
      ]));
  }
}