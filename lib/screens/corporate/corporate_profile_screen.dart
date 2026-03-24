// lib/screens/corporate/corporate_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/corporate_employee_model.dart';

class CorporateProfileScreen extends StatefulWidget {
  final String userId;
  const CorporateProfileScreen({super.key, required this.userId});

  @override
  State<CorporateProfileScreen> createState() => _CorporateProfileScreenState();
}

class _CorporateProfileScreenState extends State<CorporateProfileScreen> {
  bool _isChangingPassword = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('corporate_employees')
            .doc(widget.userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final employee = CorporateEmployeeModel.fromFirestore(snapshot.data!);

          return Column(
            children: [
              _buildHeader(employee),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildAvatarCard(employee),
                      const SizedBox(height: 20),
                      _buildInfoCard(employee),
                      const SizedBox(height: 20),
                      _buildEnterpriseCard(employee),
                      const SizedBox(height: 20),
                      _buildSecurityCard(context, employee),
                      const SizedBox(height: 20),
                      _buildLogoutButton(context),
                      const SizedBox(height: 14),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Header ──
  Widget _buildHeader(CorporateEmployeeModel employee) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E40AF), Color(0xFF2563EB), Color(0xFF3B82F6)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: Row(
            children: [
              const Text(
                'Mon Profil',
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const Spacer(),
              // Badge lecture seule
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lock_outline, color: Colors.white70, size: 14),
                    SizedBox(width: 4),
                    Text('Lecture seule',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Avatar + nom ──
  Widget _buildAvatarCard(CorporateEmployeeModel employee) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          // Avatar avec bouton photo
          Stack(
            children: [
              CircleAvatar(
                radius: 44,
                backgroundColor: const Color(0xFF2563EB).withOpacity(0.1),
                child: Text(
                  employee.fullName.isNotEmpty
                      ? employee.fullName.split(' ').map((e) => e[0]).take(2).join()
                      : '?',
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: GestureDetector(
                  onTap: () => _showPhotoOptions(context),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            employee.fullName,
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              employee.isCapped ? 'Compte Plafonné' : 'Compte Cumulatif',
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2563EB)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Infos personnelles (lecture seule) ──
  Widget _buildInfoCard(CorporateEmployeeModel employee) {
    return _buildCard(
      title: 'Informations personnelles',
      icon: Icons.person_outline,
      children: [
        _readOnlyField(label: 'Nom complet', value: employee.fullName, icon: Icons.badge_outlined),
        _readOnlyField(label: 'Email', value: employee.email, icon: Icons.email_outlined),
        _readOnlyField(label: 'Matricule', value: employee.employeeNumber, icon: Icons.tag),
      ],
    );
  }

  // ── Infos entreprise (lecture seule) ──
  Widget _buildEnterpriseCard(CorporateEmployeeModel employee) {
    return _buildCard(
      title: 'Informations entreprise',
      icon: Icons.domain_outlined,
      children: [
        _readOnlyField(
            label: 'Entreprise', value: employee.enterpriseName, icon: Icons.business_outlined),
        if (employee.department != null)
          _readOnlyField(
              label: 'Département', value: employee.department!, icon: Icons.group_outlined),
        if (employee.position != null)
          _readOnlyField(
              label: 'Poste', value: employee.position!, icon: Icons.work_outline),
        _readOnlyField(
          label: 'Type de compte',
          value: employee.isCapped ? 'Plafonné' : 'Cumulatif',
          icon: Icons.account_balance_wallet_outlined,
        ),
      ],
    );
  }

  // ── Sécurité — changement mot de passe ──
  Widget _buildSecurityCard(BuildContext context, CorporateEmployeeModel employee) {
    return _buildCard(
      title: 'Sécurité',
      icon: Icons.security_outlined,
      children: [
        GestureDetector(
          onTap: () => _showChangePasswordDialog(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.lock_outline, color: Color(0xFF2563EB), size: 20),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Changer le mot de passe',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Color(0xFF1F2937))),
                      Text('Modifier votre mot de passe',
                          style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Color(0xFFD1D5DB)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Déconnexion ──
  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _confirmLogout(context),
        icon: const Icon(Icons.logout, color: Color(0xFFEF4444)),
        label: const Text('Se déconnecter',
            style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w600)),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: const BorderSide(color: Color(0xFFEF4444)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  // ── Helpers UI ──
  Widget _buildCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF2563EB), size: 20),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1F2937))),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _readOnlyField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF9CA3AF), size: 18),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937))),
              ],
            ),
            const Spacer(),
            const Icon(Icons.lock_outline, color: Color(0xFFD1D5DB), size: 16),
          ],
        ),
      ),
    );
  }

  // ── Dialogs ──
  void _showChangePasswordDialog(BuildContext context) {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    String? errorMsg;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Changer le mot de passe',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
                const SizedBox(height: 20),

                if (errorMsg != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(errorMsg!,
                        style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13)),
                  ),
                  const SizedBox(height: 12),
                ],

                _passwordField(
                  controller: currentCtrl,
                  label: 'Mot de passe actuel',
                  obscure: obscureCurrent,
                  onToggle: () => setModalState(() => obscureCurrent = !obscureCurrent),
                ),
                const SizedBox(height: 12),
                _passwordField(
                  controller: newCtrl,
                  label: 'Nouveau mot de passe',
                  obscure: obscureNew,
                  onToggle: () => setModalState(() => obscureNew = !obscureNew),
                ),
                const SizedBox(height: 12),
                _passwordField(
                  controller: confirmCtrl,
                  label: 'Confirmer le mot de passe',
                  obscure: obscureConfirm,
                  onToggle: () => setModalState(() => obscureConfirm = !obscureConfirm),
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isChangingPassword
                        ? null
                        : () async {
                            setModalState(() => errorMsg = null);
                            if (newCtrl.text != confirmCtrl.text) {
                              setModalState(() => errorMsg = 'Les mots de passe ne correspondent pas');
                              return;
                            }
                            if (newCtrl.text.length < 6) {
                              setModalState(() => errorMsg = 'Minimum 6 caractères requis');
                              return;
                            }
                            setState(() => _isChangingPassword = true);
                            try {
                              final user = FirebaseAuth.instance.currentUser!;
                              final cred = EmailAuthProvider.credential(
                                email: user.email!,
                                password: currentCtrl.text,
                              );
                              await user.reauthenticateWithCredential(cred);
                              await user.updatePassword(newCtrl.text);
                              if (ctx.mounted) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Mot de passe modifié avec succès'),
                                    backgroundColor: Color(0xFF22C55E),
                                  ),
                                );
                              }
                            } on FirebaseAuthException catch (e) {
                              setModalState(() {
                                errorMsg = e.code == 'wrong-password'
                                    ? 'Mot de passe actuel incorrect'
                                    : 'Erreur : ${e.message}';
                              });
                            } finally {
                              setState(() => _isChangingPassword = false);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isChangingPassword
                        ? const SizedBox(
                            height: 20, width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Confirmer',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF9CA3AF)),
        filled: true,
        fillColor: const Color(0xFFF5F7FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              color: const Color(0xFF9CA3AF)),
          onPressed: onToggle,
        ),
      ),
    );
  }

  void _showPhotoOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            const Text('Photo de profil',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _photoOption(Icons.camera_alt_outlined, 'Prendre une photo', () {}),
            const SizedBox(height: 10),
            _photoOption(Icons.photo_library_outlined, 'Choisir depuis la galerie', () {}),
          ],
        ),
      ),
    );
  }

  Widget _photoOption(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF2563EB), size: 22),
            const SizedBox(width: 14),
            Text(label,
                style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1F2937))),
          ],
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Déconnexion',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler', style: TextStyle(color: Color(0xFF6B7280))),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            child: const Text('Déconnecter', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}