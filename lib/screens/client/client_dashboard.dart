// lib/screens/client/client_dashboard.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../services/auth_service.dart';
import '../../services/card_service.dart';
import '../../services/company_service.dart';
import '../../services/promotion_service.dart';
import '../../services/transaction_service.dart';
import '../../services/notification_service.dart';
import '../../services/service_service.dart';
import '../../models/models.dart';
import '../../models/transaction_model.dart';
import '../../models/company_model.dart';
import '../../models/promotion_model.dart';
import '../../models/service_model.dart';
import '../../langue/app_localizations.dart';
import 'qr_code_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import 'notifications_screen.dart';
import 'services_screen.dart';        // ← nouveau
import 'promotions_screen.dart';  // ← nouveau
import 'promotion_detail_screen.dart'; // ← nouveau

class ClientDashboard extends StatefulWidget {
  const ClientDashboard({super.key});

  @override
  State<ClientDashboard> createState() => _ClientDashboardState();
}

class DashboardHome extends StatefulWidget {
  const DashboardHome({super.key});

  @override
  State<DashboardHome> createState() => _DashboardHomeState();
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
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 16, offset: const Offset(0, -4)),
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

// ════════════════════════════════════════════════════════════════
// DashboardHome
// ════════════════════════════════════════════════════════════════
class _DashboardHomeState extends State<DashboardHome> {
  UserModel? _user;
  CardModel? _card;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });

    final authService = Provider.of<AuthService>(context, listen: false);
    final cardService = CardService();

    final results = await Future.wait([
      authService.loadUserProfile(),
      cardService.getMyCard(),
    ]);

    if (!mounted) return;

    final userResult = results[0];
    final cardResult = results[1];

    if (userResult['success'] == true) {
      final user = userResult['user'] as UserModel;
      setState(() {
        _user = user;
        if (cardResult['success'] == true) {
          _card = cardResult['card'] as CardModel;
        }
        _loading = false;
      });
    } else {
      setState(() { _error = userResult['error']; _loading = false; });
    }
  }

  // ✅ Récupère la compagnie depuis l'API publique
  Future<CompanyModel?> _getCompanyFromPublicApi(String companyId) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.cardoil.io/api/auth/companies'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List;
        final found = list.firstWhere(
          (c) => c['id']?.toString() == companyId,
          orElse: () => null,
        );
        if (found != null) return CompanyModel.fromJson(found);
      }
    } catch (e) {
      print('getCompanyFromPublicApi error: $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null || _user == null) {
      return Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 12),
          Text(_error ?? 'Erreur', textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadData,
            child: const Text('Réessayer'),
          ),
        ],
      ));
    }

    final user = _user!;

    return FutureBuilder<CompanyModel?>(
      // ✅ utilise l'API publique avec le bon token
      future: _getCompanyFromPublicApi(user.selectedCompagnie),
      builder: (context, companySnap) {
        return RefreshIndicator(
          onRefresh: _loadData,
          color: const Color(0xFF2563EB),
          child: Column(children: [
            _BlueHeader(user: user, card: _card, company: companySnap.data),
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(top: 100),
                child: _WhiteContent(user: user),
              ),
            ),
          ]),
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════════════
// _BlueHeader, _TopRow, _CompanyBadge, _BalanceCard — inchangés
// ════════════════════════════════════════════════════════════════

class _BlueHeader extends StatelessWidget {
  final UserModel user;
  final CardModel? card;
  final CompanyModel? company;
  const _BlueHeader({required this.user, required this.card, required this.company});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF5F7FF),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(5)),
      ),
      child: Stack(clipBehavior: Clip.none, children: [
        Container(
          height: 180,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Color(0xFF1E40AF), Color(0xFF2563EB), Color(0xFF3B82F6)],
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
          ),
        ),
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: Column(children: [
              _TopRow(user: user),
              const SizedBox(height: 10),
              Transform.translate(
                offset: const Offset(0, -8),
                child: _CompanyBadge(user: user, company: company),
              ),
              const SizedBox(height: 110),
            ]),
          ),
        ),
        Positioned(
          left: 20, right: 20, bottom: -100,
          child: _BalanceCard(user: user, card: card),
        ),
      ]),
    );
  }
}

class _TopRow extends StatefulWidget {
  final UserModel user;
  const _TopRow({required this.user});

  @override
  State<_TopRow> createState() => _TopRowState();
}

class _TopRowState extends State<_TopRow> {
  final _authService = AuthService();
  final _notifService = NotificationService();
  String? _token;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final token = await _authService.getToken();
    if (!mounted) return;
    setState(() => _token = token);
    final count = await _notifService.getUnreadCount(token: token);
    if (!mounted) return;
    setState(() => _unreadCount = count);
  }

  Future<void> _refreshCount() async {
    final count = await _notifService.getUnreadCount(token: _token);
    if (!mounted) return;
    setState(() => _unreadCount = count);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Row(children: [
      GestureDetector(
        onTap: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const QRCodeScreen())),
        child: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 24),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          t.helloUser(widget.user.fullName.split(' ').first),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => NotificationsScreen(token: _token)),
        ).then((_) => _refreshCount()),
        child: Stack(clipBehavior: Clip.none, children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.notifications_outlined, color: Colors.white, size: 24),
          ),
          if (_unreadCount > 0)
            Positioned(
              right: -2, top: -2,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
                child: Text(
                  _unreadCount > 9 ? '9+' : '$_unreadCount',
                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ]),
      ),
    ]);
  }
}

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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.4)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.add, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text(t.chooseCompanyPrompt,
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
          ]),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.local_gas_station, color: Color(0xFFDC2626), size: 18),
        const SizedBox(width: 8),
        Text(company?.name ?? user.selectedCompagnie,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
      ]),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final UserModel user;
  final CardModel? card;
  const _BalanceCard({required this.user, required this.card});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final balance = card?.balance ?? user.balance;
    final points = card?.loyaltyPoints ?? user.currentCompanyPoints;
    final isVerified = card?.isActive ?? user.phoneVerified;
    final balanceStr = balance.toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ');

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF3B82F6), Color(0xFF6366F1), Color(0xFFA855F7), Color(0xFF10B981)],
        ),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 24, offset: const Offset(0, 10))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(children: [
          Positioned.fill(child: CustomPaint(painter: WavePainter(color: Colors.white, opacity: 0.08))),
          Positioned(right: -40, top: -40,
              child: Container(width: 160, height: 160,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.2)))),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t.availableBalance,
                  style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(balanceStr, style: const TextStyle(
                    color: Colors.white, fontSize: 46, fontWeight: FontWeight.w900, height: 1.05, letterSpacing: -1)),
                const Padding(
                  padding: EdgeInsets.only(bottom: 5, left: 6),
                  child: Text('FCFA', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                ),
              ]),
              const SizedBox(height: 12),
              Divider(color: Colors.white.withOpacity(0.3), height: 1),
              const SizedBox(height: 10),
              Text('${t.loyaltyPointsLabel} : $points pts',
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Divider(color: Colors.white.withOpacity(0.3), height: 1),
              const SizedBox(height: 10),
              Row(children: [
                Text('${t.status} : ${isVerified ? t.statusVerified : t.statusNotVerified}',
                    style: const TextStyle(color: Colors.white, fontSize: 14)),
                const SizedBox(width: 8),
                Container(
                  width: 22, height: 22,
                  decoration: BoxDecoration(
                    color: isVerified ? const Color(0xFF22C55E) : Colors.orange,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(isVerified ? Icons.check : Icons.close, color: Colors.white, size: 13),
                ),
              ]),
              if (card?.reference.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                Text('N° ${card!.reference}',
                    style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11)),
              ],
            ]),
          ),
        ]),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// _WhiteContent — avec services et promos CLIQUABLES
// ════════════════════════════════════════════════════════════════

class _WhiteContent extends StatelessWidget {
  final UserModel user;
  const _WhiteContent({required this.user});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final promotionService = PromotionService();
    final companyId = int.tryParse(user.selectedCompagnie) ?? 0;

    return ClipPath(
      clipper: _ConcaveClipper(),
      child: Container(
        color: const Color(0xFFF5F7FA),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // ── Services dynamiques cliquables ──
            DashboardServicesGrid(companyId: companyId),

            const SizedBox(height: 24),

            // ── Titre Promotions + bouton "Voir tout" ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(t.promotions,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
                // ← NOUVEAU : bouton "Voir tout" cliquable
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AllPromotionsScreen(companyId: companyId),
                    ),
                  ),
                  child: const Text(
                    'Voir tout',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Carrousel de promos cliquables ──
            FutureBuilder<List<PromotionModel>>(
              future: promotionService.getPromotions(companyId, limit: 3),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 160,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snap.hasData && snap.data!.isNotEmpty) {
                  return SizedBox(
                    height: 160,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: snap.data!.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (_, i) => _buildPromoCard(context, snap.data![i], companyId),
                    ),
                  );
                }
                return Container(
                  height: 60,
                  decoration: BoxDecoration(
                      color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: Center(
                      child: Text(t.noPromotion,
                          style: const TextStyle(color: Color(0xFF9CA3AF)))),
                );
              },
            ),

            const SizedBox(height: 24),
            _buildMonthlyExpenses(context, t),
            const SizedBox(height: 14),
          ]),
        ),
      ),
    );
  }

  // ── Promo card cliquable ─────────────────────────────────────
  Widget _buildPromoCard(BuildContext context, PromotionModel promo, int companyId) {
    final colors = promo.type == PromotionType.gift
        ? [const Color(0xFF10B981), const Color(0xFF34D399)]
        : promo.type == PromotionType.scratch
            ? [const Color(0xFFDC2626), const Color(0xFFEF4444)]
            : [const Color(0xFF2563EB), const Color(0xFF60A5FA)];

    return GestureDetector(
      // ← CLIQUABLE : ouvre le détail de la promo
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PromotionDetailScreen(promotionId: promo.id),
        ),
      ),
      child: Container(
        width: 240,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            gradient: LinearGradient(colors: colors),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: colors[0].withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4))
            ]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Badge type
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8)),
            child: Text(promo.typeLabel,
                style: const TextStyle(
                    color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 10),
          Text(promo.title,
              style: const TextStyle(
                  color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Expanded(
            child: Text(promo.description ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ),
          // Flèche "voir détail"
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20)),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Text('Détails',
                    style: TextStyle(
                        color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward, size: 12, color: Colors.white),
              ]),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _buildMonthlyExpenses(BuildContext context, AppLocalizations t) {
    final txService = TransactionService();

    return FutureBuilder<List<StationTransactionModel>>(
      future: txService.getTransactions(),
      builder: (context, snap) {
        double total = 0;
        int count = 0;
        final now = DateTime.now();
        final firstDay = DateTime(now.year, now.month, 1);
        final daily = List.generate(31, (_) => 0.0);

        if (snap.hasData) {
          for (final tx in snap.data!) {
            if (tx.createdAt.isAfter(firstDay) && tx.isDebit) {
              total += tx.amount;
              count++;
              final d = tx.createdAt.day - 1;
              if (d >= 0 && d < 31) daily[d] += tx.amount;
            }
          }
        }

        final last6 = <double>[];
        for (int i = daily.length - 1; i >= 0 && last6.length < 6; i--) {
          if (daily[i] > 0 || last6.isNotEmpty) last6.insert(0, daily[i]);
        }
        while (last6.length < 6) last6.insert(0, 0.0);

        final mx = last6.reduce((a, b) => a > b ? a : b);
        final normalized = mx > 0
            ? last6.map((e) => e / mx).toList()
            : [0.3, 0.4, 0.55, 0.7, 0.85, 1.0];

        final totalStr = total.toStringAsFixed(0).replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ');

        return Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(t.monthlyExpenses,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF6B7280))),
            const SizedBox(height: 6),
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(totalStr,
                  style: const TextStyle(
                      fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF2563EB), letterSpacing: -0.5)),
              const Padding(
                padding: EdgeInsets.only(bottom: 2, left: 4),
                child: Text(' FCFA',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
              ),
            ]),
            const SizedBox(height: 2),
            Text(t.transactionCount(count),
                style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
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
                    width: 28, height: h,
                    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(5)),
                  );
                }).toList(),
              ),
            ),
          ]),
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════════════
// Painters & Clippers — inchangés
// ════════════════════════════════════════════════════════════════

class WavePainter extends CustomPainter {
  final Color color;
  final double opacity;
  WavePainter({required this.color, required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withOpacity(opacity)..style = PaintingStyle.fill;
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



 class DashboardServicesGrid extends StatefulWidget {
  final int companyId;
  const DashboardServicesGrid({super.key, required this.companyId});
 
  @override
  State<DashboardServicesGrid> createState() => _DashboardServicesGridState();
}
 
class _DashboardServicesGridState extends State<DashboardServicesGrid> {
  final _serviceService = ServiceService();
  List<ServiceModel> _services = [];
  bool _loading = true;
 
  @override
  void initState() {
    super.initState();
    _load();
  }
 
  Future<void> _load() async {
    if (widget.companyId == 0) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final token = await Provider.of<AuthService>(context, listen: false).getToken();
    final list = await _serviceService.getActiveServices(widget.companyId, token: token);
    if (!mounted) return;
    setState(() {
      _services = list;
      _loading = false;
    });
  }
 
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Titre + "Voir tout" ──
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Services',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
            ),
            if (!_loading && _services.length > 8)
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => ServicesScreen(companyId: widget.companyId),
                )),
                child: const Text(
                  'Voir tout',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF2563EB)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
 
        if (_loading)
          _buildSkeleton()
        else if (_services.isEmpty)
          _buildEmptyState()
        else
          _buildGrid(),
      ],
    );
  }
 
  // ── Skeleton 4 tuiles grises ──
  Widget _buildSkeleton() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4, mainAxisSpacing: 12, crossAxisSpacing: 10, childAspectRatio: 0.82,
      ),
      itemCount: 4,
      itemBuilder: (_, __) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(16)),
          ),
          const SizedBox(height: 6),
          Container(
            height: 10, width: 44,
            decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4)),
          ),
        ],
      ),
    );
  }
 
  // ── État vide propre ──
  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.miscellaneous_services_outlined, color: Color(0xFF2563EB), size: 22),
          ),
          const SizedBox(width: 12),
          const Text(
            'Aucun service disponible',
            style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
 
  // ── Grille ──
  Widget _buildGrid() {
    final displayed = _services.take(8).toList();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4, mainAxisSpacing: 12, crossAxisSpacing: 10, childAspectRatio: 0.82,
      ),
      itemCount: displayed.length,
      itemBuilder: (ctx, i) => _ServiceTile(service: displayed[i], companyId: widget.companyId),
    );
  }
}
 
// ════════════════════════════════════════════════════════════════
// _ServiceTile
// ════════════════════════════════════════════════════════════════
 
class _ServiceTile extends StatelessWidget {
  final ServiceModel service;
  final int companyId;
  const _ServiceTile({required this.service, required this.companyId});
 
  Color _hexColor(String hex) {
    try {
      return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
    } catch (_) {
      return const Color(0xFF2563EB);
    }
  }
 
  @override
  Widget build(BuildContext context) {
    final color = _hexColor(service.effectiveColorHex);
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => ServicesScreen(companyId: companyId, highlightServiceId: service.id),
      )),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.25), width: 1),
            ),
            child: service.iconUrl != null && service.iconUrl!.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      service.iconUrl!,
                      width: 32, height: 32, fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => _FallbackIcon(color: color, service: service),
                    ),
                  )
                : _FallbackIcon(color: color, service: service),
          ),
          const SizedBox(height: 6),
          Text(
            service.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF374151), height: 1.2),
          ),
        ],
      ),
    );
  }
}
 
// ════════════════════════════════════════════════════════════════
// _FallbackIcon
// ════════════════════════════════════════════════════════════════
 
class _FallbackIcon extends StatelessWidget {
  final Color color;
  final ServiceModel service;
  const _FallbackIcon({required this.color, required this.service});
 
  IconData _iconForCode(String code) {
    final c = code.toLowerCase();
    if (c.contains('wash') || c.contains('lavage'))           return Icons.local_car_wash;
    if (c.contains('fuel') || c.contains('carburant'))        return Icons.local_gas_station;
    if (c.contains('maintenance') || c.contains('entretien')) return Icons.build;
    if (c.contains('shop') || c.contains('boutique'))         return Icons.shopping_bag;
    if (c.contains('food') || c.contains('restaurant') || c.contains('vente')) return Icons.restaurant;
    if (c.contains('park'))                                   return Icons.local_parking;
    if (c.contains('air') || c.contains('gonflage'))          return Icons.tire_repair;
    return Icons.miscellaneous_services;
  }
 
  @override
  Widget build(BuildContext context) {
    return Center(child: Icon(_iconForCode(service.code), color: color, size: 26));
  }
}
 