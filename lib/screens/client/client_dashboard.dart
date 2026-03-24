// lib/screens/client/client_dashboard.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/company_service.dart';
import '../../services/promotion_service.dart';
import '../../services/transaction_service.dart';
import '../../services/notification_service.dart';
import '../../models/models.dart';
import '../../models/transaction_model.dart';
import '../../models/company_model.dart';
import '../../models/promotion_model.dart';
import '../../langue/app_localizations.dart';
import 'qr_code_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import 'notifications_screen.dart';

// ─────────────────────────────────────────────────────
// SHELL
// ─────────────────────────────────────────────────────

class ClientDashboard extends StatefulWidget {
  const ClientDashboard({super.key});

  @override
  State<ClientDashboard> createState() => _ClientDashboardState();
}

class _ClientDashboardState extends State<ClientDashboard> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardHome(),
    const HistoryScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Directionality(
      textDirection: t.textDirection,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: _screens[_currentIndex],
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.07),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (i) => setState(() => _currentIndex = i),
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.white,
              selectedItemColor: const Color(0xFF2563EB),
              unselectedItemColor: Colors.grey.shade400,
              selectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 12),
              unselectedLabelStyle: const TextStyle(fontSize: 12),
              elevation: 0,
              items: [
                BottomNavigationBarItem(
                  icon: const Icon(Icons.home_outlined, size: 26),
                  activeIcon: const Icon(Icons.home, size: 26),
                  label: t.home,
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.history_outlined, size: 26),
                  activeIcon: const Icon(Icons.history, size: 26),
                  label: t.history,
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.person_outline, size: 26),
                  activeIcon: const Icon(Icons.person, size: 26),
                  label: t.profile,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// ÉCRAN ACCUEIL — charge le profil via API REST
// ─────────────────────────────────────────────────────

class DashboardHome extends StatefulWidget {
  const DashboardHome({super.key});

  @override
  State<DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<DashboardHome> {
  UserModel? _user;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final result = await authService.loadUserProfile();
    if (!mounted) return;
    if (result['success'] == true) {
      setState(() { _user = result['user'] as UserModel; _loading = false; });
    } else {
      setState(() { _error = result['error']; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null || _user == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            Text(_error ?? 'Erreur inconnue',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () { setState(() { _loading = true; _error = null; }); _loadUser(); },
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    final user = _user!;
    final companyService = CompanyService();

    return FutureBuilder<CompanyModel?>(
      future: companyService.getCompany(user.selectedCompagnie),
      builder: (context, companySnap) {
        final company = companySnap.data;
        return Column(
          children: [
            _BlueHeader(user: user, company: company),
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(top: 100),
                child: _WhiteContent(user: user),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────
// ZONE BLEUE
// ─────────────────────────────────────────────────────

class _BlueHeader extends StatelessWidget {
  final UserModel user;
  final CompanyModel? company;
  const _BlueHeader({required this.user, required this.company});

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
          Container(
            height: 180,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1E40AF),
                  Color(0xFF2563EB),
                  Color(0xFF3B82F6),
                ],
              ),
              borderRadius:
                  BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Column(
                children: [
                  _TopRow(user: user),
                  const SizedBox(height: 10),
                  Transform.translate(
                    offset: const Offset(0, -8),
                    child: _CompanyBadge(user: user, company: company),
                  ),
                  const SizedBox(height: 90),
                ],
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: -100,
            child: _BalanceCard(user: user),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// TOP ROW
// ─────────────────────────────────────────────────────

class _TopRow extends StatelessWidget {
  final UserModel user;
  const _TopRow({required this.user});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final notifService = NotificationService();

    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const QRCodeScreen())),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.qr_code_scanner,
                color: Colors.white, size: 24),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            t.helloUser(user.fullName.split(' ').first),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        // Notifications — gardé avec un FutureBuilder simple
        FutureBuilder<int>(
          future: notifService.getUnreadCount(),
          builder: (context, snap) {
            final count = snap.data ?? 0;
            return GestureDetector(
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const NotificationsScreen())),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.notifications_outlined,
                        color: Colors.white, size: 24),
                  ),
                  if (count > 0)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                            color: Color(0xFFEF4444),
                            shape: BoxShape.circle),
                        child: Text(
                          count > 9 ? '9+' : '$count',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────
// BADGE COMPAGNIE
// ─────────────────────────────────────────────────────

class _CompanyBadge extends StatelessWidget {
  final UserModel user;
  final CompanyModel? company;
  const _CompanyBadge({required this.user, required this.company});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    if (user.selectedCompagnie.isEmpty) {
      return GestureDetector(
        onTap: () => Navigator.pushNamed(context, '/profile'),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Text(t.chooseCompanyPrompt,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_gas_station,
              color: Color(0xFFDC2626), size: 18),
          const SizedBox(width: 8),
          Text(
            company?.name ?? user.selectedCompagnie,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFFDC2626),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// CARTE SOLDE
// ─────────────────────────────────────────────────────

class _BalanceCard extends StatelessWidget {
  final UserModel user;
  const _BalanceCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    final balanceStr = user.balance
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]} ',
        );

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
            Positioned.fill(
              child: CustomPaint(
                painter: WavePainter(color: Colors.white, opacity: 0.08),
              ),
            ),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.availableBalance,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        balanceStr,
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
                        child: Text(
                          'FCFA',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Divider(color: Colors.white.withOpacity(0.3), height: 1),
                  const SizedBox(height: 10),
                  Text(
                    '${t.loyaltyPointsLabel} : ${user.currentCompanyPoints} pts',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Divider(color: Colors.white.withOpacity(0.3), height: 1),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        '${t.status} : ${user.phoneVerified ? t.statusVerified : t.statusNotVerified}',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 14),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: user.phoneVerified
                              ? const Color(0xFF22C55E)
                              : Colors.orange,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          user.phoneVerified ? Icons.check : Icons.close,
                          color: Colors.white,
                          size: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WavePainter extends CustomPainter {
  final Color color;
  final double opacity;
  WavePainter({required this.color, required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(opacity)
      ..style = PaintingStyle.fill;
    final path = Path();
    path.moveTo(0, size.height * 0.65);
    path.quadraticBezierTo(
        size.width * 0.25, size.height * 0.55, size.width * 0.5, size.height * 0.7);
    path.quadraticBezierTo(
        size.width * 0.75, size.height * 0.85, size.width, size.height * 0.7);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────
// ZONE GRISE
// ─────────────────────────────────────────────────────

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

class _WhiteContent extends StatelessWidget {
  final UserModel user;
  const _WhiteContent({required this.user});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final promotionService = PromotionService();

    return ClipPath(
      clipper: _ConcaveClipper(),
      child: Container(
        color: const Color(0xFFF5F7FA),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildServicesGrid(t),
              const SizedBox(height: 15),

              Text(
                t.promotions,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 12),

              FutureBuilder<List<PromotionModel>>(
                future: promotionService.getPromotions(
                    user.selectedCompagnie,
                    limit: 3),
                builder: (ctx, snap) {
                  if (snap.hasData && snap.data!.isNotEmpty) {
                    return SizedBox(
                      height: 50,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: snap.data!.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(width: 12),
                        itemBuilder: (_, i) =>
                            _buildPromoCard(snap.data![i], t),
                      ),
                    );
                  }
                  return Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(t.noPromotion,
                          style:
                              const TextStyle(color: Color(0xFF9CA3AF))),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              _buildMonthlyExpenses(context, t),
              const SizedBox(height: 14),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServicesGrid(AppLocalizations t) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
                child: _ServiceCard(
              label: t.wash,
              icon: Icons.local_car_wash,
              colors: const [Color(0xFF0EA5E9), Color(0xFF06B6D4)],
            )),
            const SizedBox(width: 12),
            Expanded(
                child: _ServiceCard(
              label: t.fuelMaintenance,
              icon: Icons.build_rounded,
              colors: const [Color(0xFFF59E0B), Color(0xFFFBBF24)],
            )),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
                child: _ServiceCard(
              label: t.fuel,
              icon: Icons.local_gas_station,
              colors: const [Color(0xFFDC2626), Color(0xFFEF4444)],
            )),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.more_horiz,
                        color: Color(0xFF6B7280), size: 20),
                    const SizedBox(width: 6),
                    Text(
                      t.other,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF374151),
                          height: 1.3),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right,
                        color: Color(0xFF2563EB), size: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPromoCard(PromotionModel promo, AppLocalizations t) {
    final isYellow = promo.type == 'reward' || promo.type == 'cagnotte';
    final colors = isYellow
        ? [const Color(0xFFFBBF24), const Color(0xFFF59E0B)]
        : [const Color(0xFFDC2626), const Color(0xFFEF4444)];
    return Container(
      width: 240,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(promo.title,
              style: const TextStyle(
                  color: Color(0xFF1F2937),
                  fontSize: 15,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Expanded(
            child: Text(promo.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Color(0xFF374151), fontSize: 12)),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(t.seeAll,
                    style: TextStyle(
                        color: colors[0],
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward, size: 12, color: colors[0]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyExpenses(BuildContext context, AppLocalizations t) {
    final txService = TransactionService();

    return FutureBuilder<List<TransactionModel>>(
      future: txService.getTransactions(),
      builder: (context, snap) {
        double total = 0;
        int count = 0;
        final now = DateTime.now();
        final firstDay = DateTime(now.year, now.month, 1);
        final daily = List.generate(31, (_) => 0.0);

        if (snap.hasData) {
          for (final tx in snap.data!) {
            if (tx.createdAt.isAfter(firstDay) && tx.type == 'PAYMENT') {
              total += tx.amount.toDouble();
              count++;
              final d = tx.createdAt.day - 1;
              if (d >= 0 && d < 31) daily[d] += tx.amount.toDouble();
            }
          }
        }

        final last6 = <double>[];
        for (int i = daily.length - 1;
            i >= 0 && last6.length < 6;
            i--) {
          if (daily[i] > 0 || last6.isNotEmpty) {
            last6.insert(0, daily[i]);
          }
        }
        while (last6.length < 6) last6.insert(0, 0.0);

        final mx = last6.reduce((a, b) => a > b ? a : b);
        final normalized = mx > 0
            ? last6.map((e) => e / mx).toList()
            : [0.3, 0.4, 0.55, 0.7, 0.85, 1.0];

        final totalStr = total
            .toStringAsFixed(0)
            .replaceAllMapped(
              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
              (m) => '${m[1]} ',
            );

        return Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                t.monthlyExpenses,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    totalStr,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF2563EB),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 2, left: 4),
                    child: Text(
                      ' FCFA',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                t.transactionCount(count),
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF9CA3AF),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 44,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: normalized.map((v) {
                    final h = (v * 44).clamp(4.0, 44.0);
                    final color = v > 0.8
                        ? const Color(0xFF2563EB)
                        : v > 0.5
                            ? const Color(0xFF93C5FD)
                            : const Color(0xFFE5E7EB);
                    return Container(
                      width: 28,
                      height: h,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────
// CARTE SERVICE
// ─────────────────────────────────────────────────────

class _ServiceCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final List<Color> colors;

  const _ServiceCard({
    required this.label,
    required this.icon,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: colors[0].withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            right: -12,
            bottom: -12,
            child: Icon(icon,
                size: 72, color: Colors.white.withOpacity(0.18)),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const Spacer(),
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}