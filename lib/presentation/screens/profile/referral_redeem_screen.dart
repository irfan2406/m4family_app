import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';

class ReferralRedeemScreen extends ConsumerStatefulWidget {
  final double walletBalance;

  const ReferralRedeemScreen({super.key, required this.walletBalance});

  @override
  ConsumerState<ReferralRedeemScreen> createState() =>
      _ReferralRedeemScreenState();
}

class _ReferralRedeemScreenState extends ConsumerState<ReferralRedeemScreen> {
  String? _selectedOption;
  bool _isLoading = false;
  final TextEditingController _amountController = TextEditingController();

  /// Catalog from GET /api/rewards — the same list the web's "REDEMPTION
  /// CATALOG" renders. Empty means we fall back to the fixed options below so
  /// the screen is never blank if the call fails.
  List<dynamic> _rewards = [];
  bool _loadingCatalog = true;

  @override
  void initState() {
    super.initState();
    _fetchCatalog();
  }

  /// GET /api/rewards answers 404 for an authenticated user, so the catalog
  /// route is still unknown. These are tried in order until one returns a list;
  /// the winner is logged so it can be pinned as the single call.
  static const _catalogCandidates = [
    '/api/rewards',
    '/api/rewards/catalog',
    '/api/rewards/list',
    '/api/rewards/all',
    '/api/rewards/available',
    '/api/rewards/active',
    '/api/rewards/items',
    '/api/user/rewards/catalog',
    '/api/user/referrals/rewards',
    '/api/user/referrals/catalog',
    '/api/loyalty/rewards',
    '/api/redemption/catalog',
    '/api/admin/rewards',
  ];

  List<dynamic>? _extractList(dynamic body) {
    if (body is List) return body;
    if (body is Map) {
      for (final k in ['data', 'rewards', 'items', 'results', 'catalog']) {
        final v = body[k];
        if (v is List) return v;
        if (v is Map && v['rewards'] is List) return v['rewards'] as List;
      }
    }
    return null;
  }

  Future<void> _fetchCatalog() async {
    final api = ref.read(apiClientProvider);
    for (final path in _catalogCandidates) {
      try {
        final res = await api.dio.get(
          path,
          options: Options(validateStatus: (_) => true),
        );
        if (res.statusCode != 200) {
          if (kDebugMode) debugPrint('M4 catalog $path -> ${res.statusCode}');
          continue;
        }
        final list = _extractList(res.data);
        if (list == null || list.isEmpty) {
          if (kDebugMode) debugPrint('M4 catalog $path -> 200 but no list');
          continue;
        }
        _rewards = list;
        if (kDebugMode) {
          debugPrint('M4 catalog FOUND $path (${list.length} items)');
          if (list.first is Map) {
            debugPrint(
              'M4 reward keys: ${(list.first as Map).keys.join(', ')}',
            );
            debugPrint('M4 reward sample: ${list.first}');
          }
        }
        break;
      } catch (e) {
        if (kDebugMode) debugPrint('M4 catalog $path -> error $e');
      }
    }
    if (mounted) setState(() => _loadingCatalog = false);
  }

  // The catalog payload is authored in the CMS, so field names are read
  // leniently rather than assumed.
  String _rs(dynamic reward, List<String> keys, [String fallback = '']) {
    if (reward is! Map) return fallback;
    for (final k in keys) {
      final v = reward[k];
      if (v == null) continue;
      final s = v.toString().trim();
      if (s.isNotEmpty && s != 'null') return s;
    }
    return fallback;
  }

  int _rewardPoints(dynamic reward) {
    final raw = _rs(reward, [
      'points',
      'pointsCost',
      'pointsRequired',
      'cost',
      'price',
    ], '0');
    return int.tryParse(raw.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
  }

  /// Stock is optional — null means the CMS did not publish a count.
  int? _rewardStock(dynamic reward) {
    final raw = _rs(reward, ['stock', 'stockLeft', 'quantity', 'available']);
    if (raw.isEmpty) return null;
    return int.tryParse(raw.replaceAll(RegExp(r'[^0-9]'), ''));
  }

  String _rewardImage(dynamic reward) {
    var url = _rs(reward, ['image', 'imageUrl', 'thumbnail', 'photo']);
    if (url.isEmpty && reward is Map) {
      final imgs = reward['images'];
      if (imgs is List && imgs.isNotEmpty) url = imgs.first.toString();
    }
    if (url.isEmpty) return '';
    return ref.read(apiClientProvider).resolveUrl(url);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  final List<Map<String, dynamic>> _redemptionOptions = [
    {
      'id': 'wallet',
      'title': 'M4 WALLET CREDIT',
      'subtitle': '1 POINT = ₹1',
      'icon': LucideIcons.wallet,
    },
    {
      'id': 'booking_discount',
      'title': 'BOOKING DISCOUNT',
      'subtitle': '1 POINT = ₹1',
      'icon': LucideIcons.creditCard,
    },
    {
      'id': 'shopping_vouchers',
      'title': 'SHOPPING VOUCHERS',
      'subtitle': '100 POINTS = ₹80',
      'icon': LucideIcons.shoppingBag,
    },
    {
      'id': 'priority_concierge',
      'title': 'PRIORITY CONCIERGE',
      'subtitle': 'FIXED: 2000 POINTS',
      'icon': LucideIcons.zap,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            LucideIcons.chevronLeft,
            color: isDark ? Colors.white : Color(0xFF0C312B),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        // Web parity: title with a "CONVERT YOUR POINTS" sub-line.
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'REDEEM REWARDS',
              style: GoogleFonts.gelasio(
                textStyle: const TextStyle(inherit: true),
                color: isDark ? Colors.white : const Color(0xFF0C312B),
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'CONVERT YOUR POINTS',
              style: GoogleFonts.gelasio(
                textStyle: const TextStyle(inherit: true),
                color: (isDark ? Colors.white : const Color(0xFF155A4F))
                    .withOpacity(0.75),
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            _buildWalletCard(isDark),
            const SizedBox(height: 24),
            Text(
              'REDEMPTION CATALOG',
              style: GoogleFonts.gelasio(
                textStyle: const TextStyle(inherit: true),
                color: (isDark ? Colors.white : const Color(0xFF155A4F))
                    .withOpacity(0.75),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 16),
            if (_loadingCatalog)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else if (_rewards.isNotEmpty)
              ..._rewards.map((r) => _buildRewardCard(r, isDark))
            else
              // Catalog unavailable — keep the fixed options so redemption
              // still works rather than showing an empty page.
              ..._redemptionOptions.map((opt) => _buildOption(opt, isDark)),
            // Catalog rewards cost a fixed number of points; only the legacy
            // options need a volume entry.
            if (_selectedOption != null && _rewards.isEmpty) ...[
              const SizedBox(height: 8),
              _buildVolumeInput(isDark),
            ],
            const SizedBox(height: 24),
            _buildConfirmButton(isDark),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141B3A) : const Color(0xFFF4EFE3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (isDark ? Colors.white : Color(0xFF0C312B)).withOpacity(0.05),
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
      ),
      // Web parity: a large gift glyph watermarked behind the balance.
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            right: -10,
            child: Icon(
              LucideIcons.gift,
              size: 110,
              color: (isDark ? Colors.white : const Color(0xFF0C312B))
                  .withOpacity(0.05),
            ),
          ),
          Column(
            children: [
              Text(
                'YOUR WALLET BALANCE',
                style: GoogleFonts.gelasio(
                  textStyle: const TextStyle(inherit: true),
                  color: isDark ? Colors.white24 : Colors.black26,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.walletBalance.toStringAsFixed(0),
                    style: GoogleFonts.gelasio(
                      textStyle: const TextStyle(inherit: true),
                      color: isDark ? Colors.white : Color(0xFF0C312B),
                      fontSize: 48,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'PTS',
                    style: GoogleFonts.inter(
                      textStyle: const TextStyle(inherit: true),
                      color: isDark ? Colors.white38 : Color(0xFF155A4F),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Catalog reward (web parity: thumbnail, copy, points badge, stock) ──
  Widget _buildRewardCard(dynamic reward, bool isDark) {
    final id = _rs(reward, ['_id', 'id']);
    final title = _rs(reward, ['title', 'name'], 'REWARD');
    final desc = _rs(reward, ['description', 'subtitle', 'desc']);
    final points = _rewardPoints(reward);
    final stock = _rewardStock(reward);
    final image = _rewardImage(reward);

    final ink = isDark ? Colors.white : const Color(0xFF0C312B);
    final muted = isDark ? Colors.white38 : const Color(0xFF155A4F);
    final isSelected = _selectedOption == id;
    final affordable = points <= widget.walletBalance;

    return GestureDetector(
      onTap: () => setState(() => _selectedOption = id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF141B3A) : const Color(0xFFF4EFE3),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? ink : ink.withOpacity(0.05),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                width: 64,
                height: 64,
                child: image.isEmpty
                    ? Container(
                        color: ink.withOpacity(0.05),
                        child: Icon(
                          LucideIcons.package,
                          size: 22,
                          color: muted,
                        ),
                      )
                    : CachedNetworkImage(
                        imageUrl: image,
                        fit: BoxFit.cover,
                        memCacheWidth: 200,
                        placeholder: (c, u) =>
                            Container(color: ink.withOpacity(0.05)),
                        errorWidget: (c, u, e) => Container(
                          color: ink.withOpacity(0.05),
                          child: Icon(
                            LucideIcons.package,
                            size: 22,
                            color: muted,
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      textStyle: const TextStyle(inherit: true),
                      color: ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (desc.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      desc,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        textStyle: const TextStyle(inherit: true),
                        color: muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  if (stock != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'STOCK: $stock LEFT',
                      style: GoogleFonts.inter(
                        textStyle: const TextStyle(inherit: true),
                        color: muted,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: ink.withOpacity(0.04),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: ink.withOpacity(0.12)),
              ),
              child: Text(
                '$points pts',
                style: GoogleFonts.inter(
                  textStyle: const TextStyle(inherit: true),
                  color: affordable ? ink : const Color(0xFFC65B46),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(Map<String, dynamic> opt, bool isDark) {
    final isSelected = _selectedOption == opt['id'];
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedOption = opt['id'];
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF141B3A) : const Color(0xFFF4EFE3),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected
                ? (isDark ? Colors.white : Color(0xFF0C312B))
                : (isDark ? Colors.white : Color(0xFF0C312B)).withOpacity(0.05),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Color(0xFF0C312B)).withOpacity(
                  0.05,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                opt['icon'],
                color: isDark ? Colors.white : Color(0xFF0C312B),
                size: 20,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    opt['title'],
                    style: GoogleFonts.inter(
                      textStyle: const TextStyle(inherit: true),
                      color: isDark ? Colors.white : Color(0xFF155A4F),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    opt['subtitle'],
                    style: GoogleFonts.inter(
                      textStyle: const TextStyle(inherit: true),
                      color: isDark ? Colors.white38 : Color(0xFF155A4F),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                LucideIcons.checkCircle2,
                color: isDark ? Colors.white : Color(0xFF0C312B),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVolumeInput(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 10, bottom: 10, top: 10),
          child: Text(
            'REDEEM VOLUME',
            style: GoogleFonts.gelasio(
              textStyle: const TextStyle(inherit: true),
              color: isDark ? Colors.white24 : Colors.black26,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF141B3A) : const Color(0xFFF4EFE3),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: (isDark ? Colors.white : Color(0xFF0C312B)).withOpacity(
                0.05,
              ),
            ),
          ),
          child: TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: GoogleFonts.gelasio(
              textStyle: const TextStyle(inherit: true),
              color: isDark ? Colors.white : Color(0xFF0C312B),
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
            onChanged: (val) => setState(() {}),
            decoration: const InputDecoration(
              hintText: '0000',
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 20),
            ),
          ),
        ),
        const SizedBox(height: 15),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children:
              [500, 1000, 2000]
                  .map(
                    (amount) => _buildPresetButton(amount.toString(), isDark),
                  )
                  .toList()
                ..add(_buildPresetButton('MAX', isDark, isMax: true)),
        ),
      ],
    );
  }

  Widget _buildPresetButton(String label, bool isDark, {bool isMax = false}) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            if (isMax) {
              _amountController.text = widget.walletBalance.toInt().toString();
            } else {
              _amountController.text = label;
            }
          });
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isMax
                ? (isDark ? Colors.white10 : Colors.black12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: (isDark ? Colors.white : Color(0xFF0C312B)).withOpacity(
                0.1,
              ),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.inter(
              textStyle: const TextStyle(inherit: true),
              color: isDark ? Colors.white : Color(0xFF155A4F),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmButton(bool isDark) {
    // A catalog reward carries its own fixed cost, so no amount is typed.
    final catalogMode = _rewards.isNotEmpty;
    final isEnabled =
        _selectedOption != null &&
        (catalogMode || _amountController.text.isNotEmpty) &&
        !_isLoading;
    return GestureDetector(
      onTap: isEnabled
          ? () async {
              setState(() => _isLoading = true);
              try {
                final apiClient = ref.read(apiClientProvider);
                final selected = catalogMode
                    ? _rewards.firstWhere(
                        (r) => _rs(r, ['_id', 'id']) == _selectedOption,
                        orElse: () => null,
                      )
                    : null;
                final response = await apiClient.redeemPoints({
                  'points': catalogMode
                      ? _rewardPoints(selected).toString()
                      : _amountController.text,
                  'optionId': _selectedOption,
                  // Catalog redemptions are keyed by reward id; both keys are
                  // sent so whichever the API expects is present.
                  if (catalogMode) 'rewardId': _selectedOption,
                });

                if (response.data['status'] == true) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: const Color(0xFF163A2C),
                        content: Text(
                          response.data['message'] ??
                              'Redemption Request Submitted',
                        ),
                      ),
                    );
                    Navigator.pop(
                      context,
                      true,
                    ); // true indicates success so previous screen can refresh
                  }
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: const Color(0xFFC65B46),
                        content: Text(
                          response.data['message'] ?? 'Redemption failed',
                        ),
                      ),
                    );
                  }
                }
              } catch (e) {
                String errorMessage =
                    'Failed to process redemption request. Please try again later.';
                if (e is DioException && e.response?.data != null) {
                  errorMessage = e.response!.data['message'] ?? errorMessage;
                }
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: const Color(0xFFC65B46),
                      content: Text(errorMessage),
                    ),
                  );
                }
              } finally {
                if (mounted) {
                  setState(() => _isLoading = false);
                }
              }
            }
          : null,
      child: Opacity(
        opacity: isEnabled ? 1.0 : 0.5,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: isDark ? Colors.white : Color(0xFF0C312B),
            borderRadius: BorderRadius.circular(15),
          ),
          alignment: Alignment.center,
          child: _isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: isDark ? Colors.black : const Color(0xFFF4EFE3),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.gift,
                      color: isDark ? Colors.black : const Color(0xFFF4EFE3),
                      size: 16,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'CONFIRM REDEMPTION',
                      style: GoogleFonts.gelasio(
                        textStyle: const TextStyle(inherit: true),
                        color: isDark ? Colors.black : const Color(0xFFF4EFE3),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
