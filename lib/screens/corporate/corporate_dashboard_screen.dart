import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/corporate_employee_model.dart';
import 'corporate_history_screen.dart';
import 'corporate_profile_screen.dart';
import 'corporate_notifications_screen.dart';
import 'corporate_qr_screen.dart';

class CorporateDashboardScreen extends StatefulWidget {
  final String userId;

  const CorporateDashboardScreen({
    super.key,
    required this.userId,
  });

  @override
  State<CorporateDashboardScreen> createState() => _CorporateDashboardScreenState();
}

class _CorporateDashboardScreenState extends State<CorporateDashboardScreen> {
  int _currentIndex = 0;

  String _formatCurrency(double amount) {
    return NumberFormat('#,###', 'fr_FR').format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      _CorporateHomeTab(userId: widget.userId, formatCurrency: _formatCurrency),
      CorporateHistoryScreen(userId: widget.userId),
      CorporateProfileScreen(userId: widget.userId),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (i) => setState(() => _currentIndex = i),
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: const Color(0xFF2563EB),
            unselectedItemColor: Colors.grey.shade400,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            unselectedLabelStyle: const TextStyle(fontSize: 12),
            elevation: 0,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined, size: 26),
                activeIcon: Icon(Icons.home, size: 26),
                label: 'Accueil',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.history_outlined, size: 26),
                activeIcon: Icon(Icons.history, size: 26),
                label: 'Historique',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline, size: 26),
                activeIcon: Icon(Icons.person, size: 26),
                label: 'Profil',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Wrapper Home Tab ──
class _CorporateHomeTab extends StatelessWidget {
  final String userId;
  final String Function(double) formatCurrency;
  const _CorporateHomeTab({required this.userId, required this.formatCurrency});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('corporate_employees')
          .doc(userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final employee = CorporateEmployeeModel.fromFirestore(snapshot.data!);
        return Column(
          children: [
            _CorporateBlueHeader(employee: employee, userId: userId),
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(top: 100),
                child: _CorporateWhiteContent(
                  employee: employee,
                  userId: userId,
                  formatCurrency: formatCurrency,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Header bleu avec QR + cloche ──
class _CorporateBlueHeader extends StatelessWidget {
  final CorporateEmployeeModel employee;
  final String userId; // ← ajouté

  const _CorporateBlueHeader({required this.employee, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF5F7FF),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(5)),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Fond bleu
          Container(
            height: 180,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1E40AF), Color(0xFF2563EB), Color(0xFF3B82F6)],
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.business, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Bonjour, ${employee.fullName.split(' ').first}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // QR Code
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CorporateQRScreen(userId: userId),
                          ),
                        ),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 24),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Cloche notifications
                      _CorporateNotifBell(userId: userId),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Transform.translate(
                    offset: const Offset(0, -8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 4))],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.domain, color: Color(0xFF2563EB), size: 18),
                          const SizedBox(width: 8),
                          Text(
                            employee.enterpriseName,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 90),
                ],
              ),
            ),
          ),
          Positioned(left: 20, right: 20, bottom: -110, child: _CorporateBalanceCard(employee: employee)),
        ],
      ),
    );
  }
}

// ── Cloche notifications ──
class _CorporateNotifBell extends StatelessWidget {
  final String userId;
  const _CorporateNotifBell({required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .snapshots(),
      builder: (context, snap) {
        final count = snap.data?.docs.length ?? 0;
        return GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CorporateNotificationsScreen(userId: userId))),
          child: Stack(clipBehavior: Clip.none, children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.notifications_outlined, color: Colors.white, size: 24),
            ),
            if (count > 0)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
                  child: Text(count > 9 ? '9+' : '$count', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                ),
              ),
          ]),
        );
      },
    );
  }
}

// ── White scrollable content ──
class _CorporateWhiteContent extends StatelessWidget {
  final CorporateEmployeeModel employee;
  final String userId;
  final String Function(double) formatCurrency;

  const _CorporateWhiteContent({required this.employee, required this.userId, required this.formatCurrency});

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _ConcaveClipper(),
      child: Container(
        color: const Color(0xFFF5F7FA),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Grille de services
              _buildServicesGrid(context),
              const SizedBox(height: 20),
              // Carte alerte / résumé
              _buildAlertOrSummaryCard(),
              const SizedBox(height: 20),
              _buildEnterpriseInfoCard(),
              const SizedBox(height: 20),
              _buildRecentTransactions(context),
              const SizedBox(height: 14),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServicesGrid(BuildContext context) {
    final services = [
      {'label': 'Carburant', 'icon': Icons.local_gas_station, 'colors': [const Color(0xFFDC2626), const Color(0xFFEF4444)]},
      {'label': 'Lavage', 'icon': Icons.local_car_wash, 'colors': [const Color(0xFF0EA5E9), const Color(0xFF06B6D4)]},
      {'label': 'Entretien', 'icon': Icons.build_rounded, 'colors': [const Color(0xFFF59E0B), const Color(0xFFFBBF24)]},
      {'label': 'Autres', 'icon': Icons.more_horiz, 'colors': [const Color(0xFF6366F1), const Color(0xFF8B5CF6)]},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Services', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
        const SizedBox(height: 12),
        Row(
          children: services.map((s) {
            final colors = s['colors'] as List<Color>;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: s == services.last ? 0 : 10),
                child: Container(
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: colors[0].withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Stack(
                    clipBehavior: Clip.hardEdge,
                    children: [
                      Positioned(right: -10, bottom: -10, child: Icon(s['icon'] as IconData, size: 60, color: Colors.white.withOpacity(0.18))),
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(s['icon'] as IconData, color: Colors.white, size: 20),
                            const Spacer(),
                            Text(s['label'] as String, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, height: 1.2)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }


  // ── Alerte plafond (capped) ou Résumé cumulatif ──
  Widget _buildAlertOrSummaryCard() {
    if (employee.isCapped) {
      return _buildCappedAlertCard();
    } else {
      return _buildCumulativeSummaryCard();
    }
  }

  // 🔔 Carte alerte plafond — couleur dynamique
  Widget _buildCappedAlertCard() {
    final Color bgColor;
    final Color iconColor;
    final Color textColor;
    final IconData icon;
    final String message;

    switch (employee.usageLevel) {
      case 'red':
        bgColor = const Color(0xFFEF4444).withOpacity(0.1);
        iconColor = const Color(0xFFEF4444);
        textColor = const Color(0xFFEF4444);
        icon = Icons.warning_rounded;
        message = employee.hasReachedLimit
            ? 'Plafond atteint — aucune dépense possible'
            : 'Attention ! Vous approchez de votre plafond';
        break;
      case 'yellow':
        bgColor = const Color(0xFFF59E0B).withOpacity(0.1);
        iconColor = const Color(0xFFF59E0B);
        textColor = const Color(0xFFB45309);
        icon = Icons.info_rounded;
        message = 'Vous avez consommé ${employee.usagePercentage.toStringAsFixed(0)}% de votre plafond';
        break;
      default: // green
        bgColor = const Color(0xFF22C55E).withOpacity(0.1);
        iconColor = const Color(0xFF22C55E);
        textColor = const Color(0xFF15803D);
        icon = Icons.check_circle_rounded;
        message = 'Votre consommation est dans les limites normales';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: iconColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 32),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Alerte plafond',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: TextStyle(fontSize: 13, color: textColor.withOpacity(0.8)),
                ),
                const SizedBox(height: 8),
                // Mini barre colorée
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: employee.usagePercentage / 100,
                    minHeight: 6,
                    backgroundColor: iconColor.withOpacity(0.15),
                    valueColor: AlwaysStoppedAnimation(iconColor),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${formatCurrency(employee.currentMonthUsage)} / ${formatCurrency(employee.monthlyLimit)} FCFA',
                  style: TextStyle(fontSize: 11, color: textColor.withOpacity(0.7)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 📊 Carte résumé cumulatif
  Widget _buildCumulativeSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.account_balance_wallet_rounded,
                    color: Color(0xFF2563EB), size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Résumé du compte',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _summaryRow(
            icon: Icons.trending_up,
            iconColor: const Color(0xFFEF4444),
            label: 'Dépensé ce mois',
            value: '${formatCurrency(employee.cumulativeUsed)} FCFA',
          ),
          const SizedBox(height: 10),
          _summaryRow(
            icon: Icons.savings_rounded,
            iconColor: const Color(0xFF22C55E),
            label: 'Solde disponible',
            value: '${formatCurrency(employee.cumulativeBalance)} FCFA',
          ),
          const SizedBox(height: 10),
          _summaryRow(
            icon: Icons.all_inclusive,
            iconColor: const Color(0xFF6366F1),
            label: 'Type de compte',
            value: 'Cumulatif — sans plafond',
          ),
        ],
      ),
    );
  }

  Widget _summaryRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 18),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
        const Spacer(),
        Text(value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1F2937))),
      ],
    );
  }

  // ── Infos entreprise ──
  Widget _buildEnterpriseInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Informations entreprise',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1F2937))),
          const SizedBox(height: 16),
          _infoRow('Matricule', employee.employeeNumber),
          if (employee.department != null) _infoRow('Département', employee.department!),
          if (employee.position != null) _infoRow('Poste', employee.position!),
          _infoRow('Compte', employee.isCapped ? 'Plafonné' : 'Cumulatif'),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text('$label : ', style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14)),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF1F2937))),
          ),
        ],
      ),
    );
  }

  // ── Transactions ──
  Widget _buildRecentTransactions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Dernières transactions',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('client_transactions')
              .where('clientId', isEqualTo: userId)
              .orderBy('createdAt', descending: true)
              .limit(5)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Container(
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Text('Aucune transaction', style: TextStyle(color: Color(0xFF9CA3AF))),
                ),
              );
            }
            return Column(
              children: snapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final amount = (data['amount'] ?? 0).toDouble();
                final type = data['type'] ?? 'debit';
                final isDebit = type == 'debit' || type == 'PAYMENT';

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isDebit
                              ? const Color(0xFFEF4444).withOpacity(0.1)
                              : const Color(0xFF22C55E).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isDebit ? Icons.arrow_upward : Icons.arrow_downward,
                          color: isDebit ? const Color(0xFFEF4444) : const Color(0xFF22C55E),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isDebit ? 'Paiement' : 'Crédit',
                          style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
                        ),
                      ),
                      Text(
                        '${isDebit ? "-" : "+"}${formatCurrency(amount)} FCFA',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: isDebit ? const Color(0xFFEF4444) : const Color(0xFF22C55E),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _CorporateBalanceCard extends StatelessWidget {
  final CorporateEmployeeModel employee;
  const _CorporateBalanceCard({required this.employee});

  String _fmt(double v) => NumberFormat('#,###', 'fr_FR').format(v);

  // Couleurs de la barre selon usageLevel
  Color get _barColor {
    switch (employee.usageLevel) {
      case 'yellow': return const Color(0xFFF59E0B);
      case 'red':    return const Color(0xFFEF4444);
      default:       return const Color(0xFF22C55E); // green
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF3B82F6),
            Color(0xFF6366F1),
            Color(0xFFA855F7),
            Color(0xFF10B981),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Vagues décoratives
            Positioned.fill(
              child: CustomPaint(
                painter: _WavePainter(color: Colors.white, opacity: 0.08),
              ),
            ),
            Positioned.fill(
              child: CustomPaint(
                painter: _WavePainter(color: Colors.white, opacity: 0.04),
              ),
            ),
            // Cercle lumineux
            Positioned(
              right: -40,
              top: -40,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.2),
                ),
              ),
            ),

            // ── Contenu adaptatif ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: employee.isCapped
                  ? _buildCappedContent()
                  : _buildCumulativeContent(),
            ),
          ],
        ),
      ),
    );
  }

  // ── PLAFONNÉ ──
  Widget _buildCappedContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Solde disponible',
          style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _fmt(employee.remainingBalance),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 46,
                fontWeight: FontWeight.w900,
                height: 1.05,
                letterSpacing: -1,
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 5, left: 6),
              child: Text('FCFA',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
            ),
          ],
        ),

        const SizedBox(height: 12),
        Divider(color: Colors.white.withOpacity(0.3), height: 1),
        const SizedBox(height: 10),

        // 🔔 Barre de plafond colorée (remplace "Points fidélité")
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Plafond : ${_fmt(employee.monthlyLimit)} FCFA',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            Text(
              '${employee.usagePercentage.toStringAsFixed(0)}%',
              style: TextStyle(
                color: _barColor,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: employee.usagePercentage / 100,
            minHeight: 8,
            backgroundColor: Colors.white.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation(_barColor),
          ),
        ),

        const SizedBox(height: 10),
        Divider(color: Colors.white.withOpacity(0.3), height: 1),
        const SizedBox(height: 10),

        // Statut
        Row(
          children: [
            Text(
              'Statut : ${employee.hasReachedLimit ? "Plafond atteint" : "Actif"}',
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(width: 8),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: employee.hasReachedLimit ? const Color(0xFFEF4444) : const Color(0xFF22C55E),
                shape: BoxShape.circle,
              ),
              child: Icon(
                employee.hasReachedLimit ? Icons.warning_amber : Icons.check,
                color: Colors.white,
                size: 13,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── CUMULATIF ──
  Widget _buildCumulativeContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Solde cumulé disponible',
          style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _fmt(employee.cumulativeBalance),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 46,
                fontWeight: FontWeight.w900,
                height: 1.05,
                letterSpacing: -1,
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 5, left: 6),
              child: Text('FCFA',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
            ),
          ],
        ),

        const SizedBox(height: 12),
        Divider(color: Colors.white.withOpacity(0.3), height: 1),
        const SizedBox(height: 10),

        // Dépenses du mois (remplace "Points fidélité")
        Row(
          children: [
            const Icon(Icons.trending_up, color: Colors.white70, size: 16),
            const SizedBox(width: 6),
            Text(
              'Dépensé ce mois : ${_fmt(employee.cumulativeUsed)} FCFA',
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ),

        const SizedBox(height: 10),
        Divider(color: Colors.white.withOpacity(0.3), height: 1),
        const SizedBox(height: 10),

        // Statut
        Row(
          children: [
            const Text(
              'Type de compte : Cumulatif',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(width: 8),
            Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                color: Color(0xFF22C55E),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.all_inclusive, color: Colors.white, size: 13),
            ),
          ],
        ),
      ],
    );
  }
}


class _WavePainter extends CustomPainter {
  final Color color;
  final double opacity;
  _WavePainter({required this.color, required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(opacity)
      ..style = PaintingStyle.fill;
    final path = Path();
    path.moveTo(0, size.height * 0.65);
    path.quadraticBezierTo(size.width * 0.25, size.height * 0.55, size.width * 0.5, size.height * 0.7);
    path.quadraticBezierTo(size.width * 0.75, size.height * 0.85, size.width, size.height * 0.7);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _ConcaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    const depth = 30.0;
    final path = Path();
    path.moveTo(0, 0);
    path.quadraticBezierTo(size.width / 2, depth, size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> old) => false;
}