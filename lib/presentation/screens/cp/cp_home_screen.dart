import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:m4_mobile/presentation/providers/cp_shell_provider.dart';
import 'package:m4_mobile/presentation/providers/project_provider.dart';

/// Mirrors web `app/(cp)/cp/home/page.tsx` layout: hero, search, chips, recommended,
/// videos, philosophy, featured property, action grid, partner inquiry.
class CpHomeScreen extends ConsumerStatefulWidget {
  const CpHomeScreen({super.key});

  @override
  ConsumerState<CpHomeScreen> createState() => _CpHomeScreenState();
}

class _CpHomeScreenState extends ConsumerState<CpHomeScreen> {
  final _inquiryKey = GlobalKey();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _scrollController = ScrollController();

  String _searchQuery = '';
  String _selectedFilter = 'All';
  String? _projectId;
  bool _submitting = false;
  int _heroImgIndex = 0;
  int _featuredPropIndex = 0;
  Timer? _heroTimer;
  String _heroCycleFeaturedId = '';

  static const _filters = ['All', 'Ongoing', 'Upcoming'];

  static const _philosophyBody =
      'To redefine modern luxury living by crafting homes with cutting edge design, enduring quality and thoughtful amenities delivered with trust, transparency, timeliness, and a human touch that creates lasting value for every homeowner.';

  @override
  void dispose() {
    _heroTimer?.cancel();
    _nameController.dispose();
    _phoneController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<String> _heroUrls(dynamic p) {
    final imgs = p['images'];
    if (imgs is List && imgs.isNotEmpty) {
      return imgs.map((e) => e.toString()).toList();
    }
    if (p['heroImage'] != null) return [p['heroImage'].toString()];
    return ['https://images.unsplash.com/photo-1600596542815-ffad4c1539a9'];
  }

  String _heroUrl(dynamic p) => _heroUrls(p).first;

  String _secondImg(dynamic p) {
    final u = _heroUrls(p);
    return u.length > 1 ? u[1] : u.first;
  }

  String _locLine(dynamic p) {
    final loc = p['location'];
    if (loc is String) return loc.split(',').first.trim();
    if (loc is Map) return (loc['name']?.toString() ?? '').split(',').first.trim();
    return '';
  }

  String _starting(dynamic p) {
    return (p['startingPrice'] ?? p['price'] ?? '').toString();
  }

  String _desc(dynamic p) {
    return (p['description'] ?? p['shortDescription'] ?? '').toString();
  }

  bool _statusMatch(String selected, dynamic p) {
    if (selected == 'All') return true;
    var st = p['status']?.toString() ?? '';
    if (st == 'Completed') st = 'Ongoing';
    return st == selected;
  }

  List<dynamic> _filtered(List<dynamic> projects) {
    final q = _searchQuery.toLowerCase();
    return projects.where((p) {
      final title = p['title']?.toString().toLowerCase() ?? '';
      final loc = _locLine(p).toLowerCase();
      final searchOk = q.isEmpty || title.contains(q) || loc.contains(q);
      return searchOk && _statusMatch(_selectedFilter, p);
    }).toList();
  }

  void _syncHeroTimer(dynamic featured) {
    final fid = featured?['_id']?.toString() ?? featured?['id']?.toString() ?? '';
    if (fid == _heroCycleFeaturedId) return;
    _heroCycleFeaturedId = fid;
    _heroTimer?.cancel();
    _heroTimer = null;
    _heroImgIndex = 0;
    if (featured == null) return;
    final urls = _heroUrls(featured);
    if (urls.length <= 1) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _heroTimer?.cancel();
      _heroTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (!mounted) return;
        setState(() => _heroImgIndex = (_heroImgIndex + 1) % urls.length);
      });
    });
  }

  Future<void> _submitInterest() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    if (name.isEmpty || phone.isEmpty || _projectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final user = ref.read(authProvider).user;
      final display = user?['firstName']?.toString() ??
          user?['companyName']?.toString() ??
          user?['phone']?.toString() ??
          'Partner';
      final api = ref.read(apiClientProvider);
      final res = await api.submitLead({
        'name': name,
        'phone': phone,
        'source': 'cp app',
        'projectId': _projectId,
        'userId': display,
        'notes': 'Submitted via Channel Partner Application',
      });
      if (!mounted) return;
      if (res.statusCode == 200 || res.statusCode == 201) {
        final ok = res.data['status'] == true;
        if (ok) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Interest registered. Our RM will contact you shortly.')),
          );
          _nameController.clear();
          _phoneController.clear();
          setState(() => _projectId = null);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res.data['message']?.toString() ?? 'Failed')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showFilterSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 16,
          bottom: MediaQuery.of(ctx).padding.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: Theme.of(ctx).colorScheme.outline.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'QUICK FILTERS',
              style: GoogleFonts.montserrat(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 16),
            Text(
              'PROPERTY TYPE',
              style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 2, color: Theme.of(ctx).hintColor),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['Residential', 'Commercial']
                  .map(
                    (t) => FilterChip(
                      label: Text(t, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                      selected: false,
                      onSelected: (_) {},
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('SHOW RESULTS'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(cpInquiryScrollTriggerProvider, (prev, next) {
      if (next > 0 && (prev == null || next > prev)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final ctx = _inquiryKey.currentContext;
          if (ctx != null) Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 450));
        });
      }
    });

    final projectsAsync = ref.watch(projectsProvider);
    final scheme = Theme.of(context).colorScheme;
    final primary = scheme.primary;

    return projectsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Failed to load: $e')),
      data: (projects) {
        dynamic featured;
        for (final p in projects) {
          if (p['featured'] == true) {
            featured = p;
            break;
          }
        }
        featured ??= projects.isNotEmpty ? projects.first : null;
        final filtered = _filtered(projects);
        final heroUrls = featured != null ? _heroUrls(featured) : <String>[];
        final heroImg = heroUrls.isNotEmpty ? heroUrls[_heroImgIndex % heroUrls.length] : '';

        _syncHeroTimer(featured);

        final currentFeatured = projects.isNotEmpty
            ? projects[_featuredPropIndex % projects.length]
            : null;

        return CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(48)),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.55,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (heroImg.isNotEmpty)
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 800),
                          child: CachedNetworkImage(
                            key: ValueKey(heroImg),
                            imageUrl: heroImg,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Container(color: Colors.grey.shade900),
                          ),
                        )
                      else
                        Container(color: Colors.grey.shade900),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.4),
                              Colors.transparent,
                              scheme.surface.withValues(alpha: 0.92),
                            ],
                            stops: const [0, 0.35, 1],
                          ),
                        ),
                      ),
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 8,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                          ),
                          child: Text(
                            'ARTISTIC IMPRESSION',
                            style: GoogleFonts.montserrat(
                              fontSize: 7,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 8,
                        left: 20,
                        right: 72,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  style: GoogleFonts.montserrat(
                                    fontSize: 34,
                                    fontWeight: FontWeight.w900,
                                    height: 1.05,
                                    color: scheme.onSurface,
                                  ),
                                  children: [
                                    const TextSpan(text: 'Living the\n'),
                                    TextSpan(
                                      text: 'M4 Life',
                                      style: TextStyle(color: primary, fontWeight: FontWeight.w900),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 8,
                        right: 8,
                        child: IconButton(
                          style: IconButton.styleFrom(
                            backgroundColor: scheme.surface.withValues(alpha: 0.12),
                            side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                          ),
                          onPressed: () => Scaffold.of(context).openDrawer(),
                          icon: Icon(LucideIcons.moreHorizontal, color: scheme.onSurface),
                        ),
                      ),
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 100,
                        left: 16,
                        right: 16,
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 56,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  color: scheme.surface.withValues(alpha: 0.12),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(LucideIcons.search, size: 20, color: scheme.outline),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TextField(
                                        onChanged: (v) => setState(() => _searchQuery = v),
                                        style: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w500),
                                        decoration: InputDecoration(
                                          border: InputBorder.none,
                                          hintText: 'Search residences...',
                                          hintStyle: TextStyle(color: scheme.outline),
                                          isDense: true,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Material(
                              color: scheme.surface.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(16),
                              child: InkWell(
                                onTap: _showFilterSheet,
                                borderRadius: BorderRadius.circular(16),
                                child: SizedBox(
                                  width: 56,
                                  height: 56,
                                  child: Icon(LucideIcons.slidersHorizontal, color: scheme.onSurface),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 172,
                        left: 0,
                        right: 0,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            children: _filters.map((chip) {
                              final sel = _selectedFilter == chip;
                              return Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: Material(
                                  color: sel ? scheme.onSurface : scheme.surface.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(999),
                                  child: InkWell(
                                    onTap: () => setState(() => _selectedFilter = chip),
                                    borderRadius: BorderRadius.circular(999),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                      child: Text(
                                        chip.toUpperCase(),
                                        style: GoogleFonts.montserrat(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 2,
                                          color: sel ? scheme.surface : scheme.onSurface.withValues(alpha: 0.65),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      if (featured != null)
                        Positioned(
                          left: 24,
                          right: 24,
                          bottom: 28,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: scheme.secondaryContainer.withValues(alpha: 0.9),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'FEATURED',
                                      style: GoogleFonts.montserrat(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0xFFA855F7),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                (featured['title'] ?? 'M4 Family').toString(),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.montserrat(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.5,
                                  color: scheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(LucideIcons.mapPin, size: 14, color: scheme.outline),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      _locLine(featured).toUpperCase(),
                                      style: GoogleFonts.montserrat(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 2,
                                        color: scheme.outline,
                                      ),
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
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedFilter == 'All' ? 'RECOMMENDED FOR YOU' : '${_selectedFilter.toUpperCase()} PROPERTIES',
                      style: GoogleFonts.montserrat(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 4,
                        color: scheme.onSurface.withValues(alpha: 0.65),
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push('/projects'),
                      child: Text(
                        'VIEW ALL',
                        style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 300,
                child: filtered.isEmpty
                    ? const Center(child: Text('No projects match'))
                    : ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 14),
                        itemBuilder: (context, i) {
                          final p = filtered[i];
                          final id = p['_id']?.toString() ?? p['id']?.toString() ?? '';
                          final status = (p['status'] ?? 'ONGOING').toString();
                          return GestureDetector(
                            onTap: () {
                              if (id.isNotEmpty) context.push('/projects/$id');
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(32),
                              child: SizedBox(
                                width: 240,
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    CachedNetworkImage(
                                      imageUrl: _heroUrl(p),
                                      fit: BoxFit.cover,
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.black.withValues(alpha: 0.1),
                                            Colors.black.withValues(alpha: 0.82),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 10,
                                      right: 10,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.45),
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: Colors.white24),
                                        ),
                                        child: Text(
                                          'ARTISTIC IMPRESSION',
                                          style: GoogleFonts.montserrat(fontSize: 6, fontWeight: FontWeight.w800, letterSpacing: 1, color: Colors.white70),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 10,
                                      left: 10,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.65),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          status.toUpperCase(),
                                          style: GoogleFonts.montserrat(fontSize: 8, fontWeight: FontWeight.w800),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      left: 16,
                                      right: 16,
                                      bottom: 16,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            (p['title'] ?? '').toString(),
                                            maxLines: 2,
                                            style: GoogleFonts.montserrat(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 17,
                                              height: 1.1,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              const Icon(LucideIcons.mapPin, size: 12, color: Colors.white70),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  _locLine(p).toUpperCase(),
                                                  style: GoogleFonts.montserrat(
                                                    fontSize: 9,
                                                    letterSpacing: 2,
                                                    color: Colors.white70,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white.withValues(alpha: 0.12),
                                                    borderRadius: BorderRadius.circular(10),
                                                    border: Border.all(color: Colors.white24),
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        'STARTING FROM',
                                                        style: GoogleFonts.montserrat(
                                                          fontSize: 8,
                                                          fontWeight: FontWeight.w700,
                                                          color: Colors.white60,
                                                        ),
                                                      ),
                                                      Text(
                                                        _starting(p).isEmpty ? '—' : _starting(p),
                                                        style: GoogleFonts.montserrat(
                                                          fontSize: 14,
                                                          fontWeight: FontWeight.w700,
                                                          fontStyle: FontStyle.italic,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                width: 40,
                                                height: 40,
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withValues(alpha: 0.15),
                                                  borderRadius: BorderRadius.circular(12),
                                                  border: Border.all(color: Colors.white24),
                                                ),
                                                child: const Icon(LucideIcons.chevronRight, color: Colors.white, size: 20),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Text(
                  'PROPERTY RENDERS & VIDEOS',
                  style: GoogleFonts.montserrat(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 4,
                    color: scheme.outline,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: projects.length > 3 ? 3 : projects.length,
                  itemBuilder: (context, i) {
                    final p = projects[i];
                    final id = p['_id']?.toString() ?? p['id']?.toString() ?? '';
                    return Padding(
                      padding: const EdgeInsets.only(right: 14),
                      child: GestureDetector(
                        onTap: () {
                          if (id.isNotEmpty) context.push('/projects/$id');
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: SizedBox(
                            width: 300,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                CachedNetworkImage(imageUrl: _secondImg(p), fit: BoxFit.cover),
                                Container(color: Colors.black.withValues(alpha: 0.35)),
                                const Center(
                                  child: Icon(LucideIcons.play, color: Colors.white, size: 44),
                                ),
                                Positioned(
                                  bottom: 14,
                                  left: 20,
                                  child: Text(
                                    (p['title'] ?? '').toString().toUpperCase(),
                                    style: GoogleFonts.montserrat(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 2,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: GoogleFonts.dmSerifDisplay(
                          fontSize: 26,
                          fontWeight: FontWeight.w300,
                          height: 1.1,
                          color: scheme.onSurface,
                        ),
                        children: [
                          TextSpan(text: 'O', style: TextStyle(color: primary)),
                          const TextSpan(text: 'ur Philosophy'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _philosophyBody,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.55,
                        color: scheme.onSurface.withValues(alpha: 0.65),
                      ),
                    ),
                    const SizedBox(height: 32),
                    RichText(
                      text: TextSpan(
                        style: GoogleFonts.dmSerifDisplay(
                          fontSize: 26,
                          fontWeight: FontWeight.w300,
                          color: scheme.onSurface,
                        ),
                        children: [
                          TextSpan(text: 'F', style: TextStyle(color: primary)),
                          const TextSpan(text: 'eatured Property'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            if (currentFeatured != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      AspectRatio(
                        aspectRatio: 3 / 4,
                        child: GestureDetector(
                          onTap: () {
                            final id = currentFeatured['_id']?.toString() ?? currentFeatured['id']?.toString() ?? '';
                            if (id.isNotEmpty) context.push('/projects/$id');
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(40),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                CachedNetworkImage(
                                  imageUrl: _heroUrl(currentFeatured),
                                  fit: BoxFit.cover,
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withValues(alpha: 0.75),
                                      ],
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 14,
                                  right: 14,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.45),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: Colors.white24),
                                    ),
                                    child: Text(
                                      'ARTISTIC IMPRESSION',
                                      style: GoogleFonts.montserrat(fontSize: 7, fontWeight: FontWeight.w800, letterSpacing: 2, color: Colors.white70),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: 24,
                                  right: 24,
                                  bottom: 32,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'FEATURED SELECTION',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 3,
                                          color: primary,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        (currentFeatured['title'] ?? '').toString(),
                                        style: GoogleFonts.dmSerifDisplay(
                                          fontSize: 30,
                                          fontWeight: FontWeight.w300,
                                          color: Colors.white,
                                          height: 1,
                                        ),
                                      ),
                                      if (_desc(currentFeatured).isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          _desc(currentFeatured),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.montserrat(
                                            fontSize: 10,
                                            height: 1.4,
                                            letterSpacing: 1,
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Material(
                            color: scheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(16),
                            child: InkWell(
                              onTap: () => setState(() {
                                _featuredPropIndex = (_featuredPropIndex - 1 + projects.length) % projects.length;
                              }),
                              borderRadius: BorderRadius.circular(16),
                              child: const SizedBox(width: 48, height: 52, child: Icon(LucideIcons.arrowLeft)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              onPressed: () {
                                final id = currentFeatured['_id']?.toString() ?? currentFeatured['id']?.toString() ?? '';
                                if (id.isNotEmpty) context.push('/projects/$id');
                              },
                              child: Text(
                                'EXPLORE NOW',
                                style: GoogleFonts.montserrat(fontWeight: FontWeight.w900, letterSpacing: 3, fontSize: 11),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Material(
                            color: scheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(16),
                            child: InkWell(
                              onTap: () => setState(() {
                                _featuredPropIndex = (_featuredPropIndex + 1) % projects.length;
                              }),
                              borderRadius: BorderRadius.circular(16),
                              child: const SizedBox(width: 48, height: 52, child: Icon(LucideIcons.arrowRight)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 28, 16, 0),
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 1.05,
                  children: [
                    _ActionTile(
                      icon: LucideIcons.layoutGrid,
                      title: 'EXPLORE',
                      subtitle: 'VIEW ALL PROJECTS',
                      onTap: () => context.push('/projects'),
                    ),
                    _ActionTile(
                      icon: LucideIcons.mapPin,
                      title: 'VISIT',
                      subtitle: 'BOOK A SITE TOUR',
                      onTap: () {
                        final ctx = _inquiryKey.currentContext;
                        if (ctx != null) Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 400));
                      },
                    ),
                    _ActionTile(
                      icon: LucideIcons.play,
                      title: 'VIDEO',
                      subtitle: 'WATCH WALKTHROUGHS',
                      onTap: () => context.push('/media'),
                    ),
                    _ActionTile(
                      icon: LucideIcons.userCheck,
                      title: 'REGISTER',
                      subtitle: 'PRIORITY ACCESS',
                      onTap: () {
                        final ctx = _inquiryKey.currentContext;
                        if (ctx != null) Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 400));
                      },
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 36, 20, 0),
                child: Column(
                  key: _inquiryKey,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: GoogleFonts.dmSerifDisplay(
                          fontSize: 32,
                          fontWeight: FontWeight.w300,
                          height: 1.05,
                          color: scheme.onSurface,
                        ),
                        children: [
                          const TextSpan(text: 'Partner '),
                          TextSpan(text: 'Inquiry', style: TextStyle(color: primary)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'CHANNEL PARTNER EXCLUSIVE',
                      style: GoogleFonts.montserrat(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 4,
                        color: scheme.outline,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: 'Client Full Name *',
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        hintText: 'Client Phone Number *',
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    InputDecorator(
                      decoration: InputDecoration(
                        hintText: 'Select Project',
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _projectId,
                          hint: Text('Select Project', style: TextStyle(color: scheme.outline)),
                          items: [
                            for (final p in projects)
                              if ((p['_id']?.toString() ?? p['id']?.toString() ?? '').isNotEmpty)
                                DropdownMenuItem<String>(
                                  value: p['_id']?.toString() ?? p['id']!.toString(),
                                  child: Text(
                                    p['title']?.toString() ?? 'Project',
                                    style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1),
                                  ),
                                ),
                          ],
                          onChanged: (v) => setState(() => _projectId = v),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: FilledButton(
                        onPressed: _submitting ? null : _submitInterest,
                        style: FilledButton.styleFrom(
                          backgroundColor: scheme.onSurface,
                          foregroundColor: scheme.surface,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: _submitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Text(
                                'SUBMIT INTEREST',
                                style: GoogleFonts.montserrat(fontWeight: FontWeight.w900, letterSpacing: 4, fontSize: 11),
                              ),
                      ),
                    ),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.primary.withValues(alpha: 0.18),
                ),
                child: Icon(icon, size: 22, color: scheme.primary),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: GoogleFonts.montserrat(
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                  color: scheme.outline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
