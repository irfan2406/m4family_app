import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m4_mobile/core/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'package:m4_mobile/presentation/widgets/guest_sidebar_menu.dart';
import 'package:m4_mobile/core/network/api_client.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:m4_mobile/presentation/screens/projects/guest_project_detail_screen.dart';
import 'package:m4_mobile/presentation/screens/projects/project_list_screen.dart';
import 'package:m4_mobile/presentation/screens/communities/community_detail_screen.dart';
import 'package:m4_mobile/presentation/screens/communities/community_list_screen.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class GuestDashboardScreen extends ConsumerStatefulWidget {
  const GuestDashboardScreen({super.key});

  @override
  ConsumerState<GuestDashboardScreen> createState() => _GuestDashboardScreenState();
}

class _GuestDashboardScreenState extends ConsumerState<GuestDashboardScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _interestFormKey = GlobalKey();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  int _heroIndex = 0;
  List<dynamic> _projects = [];
  List<dynamic> _communities = [];
  bool _loading = true;
  String _activeTab = 'Communities';
  int _featuredIndex = 0;

  // 📝 Interest Form Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  bool _submitting = false;
  bool _agreedToTerms = false;

  Timer? _heroTimer;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _heroTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        setState(() => _heroIndex = (_heroIndex + 1) % 3);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _messageController.dispose();
    _heroTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchData() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final results = await Future.wait([
        apiClient.getProjects(),
        apiClient.getCommunities(),
      ]);

      if (mounted) {
        setState(() {
          _projects = results[0].data['data'] ?? [];
          _communities = results[1].data['data'] ?? [];
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _scrollToInterestForm() {
    final context = _interestFormKey.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(context, duration: const Duration(seconds: 1), curve: Curves.easeInOut);
    }
  }

  Future<void> _submitInterest() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty || _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields (*)')));
      return;
    }
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please agree to the Privacy Policy')));
      return;
    }

    setState(() => _submitting = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.submitLead({
        'name': _nameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'message': _messageController.text,
        'interest': 'Guest Interest',
        'source': 'Mobile Guest Portal',
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Interest registered successfully!'), backgroundColor: Colors.green));
        _nameController.clear();
        _emailController.clear();
        _phoneController.clear();
        _messageController.clear();
        setState(() => _agreedToTerms = false);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Submission failed: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return Scaffold(body: Center(child: CircularProgressIndicator(color: M4Theme.premiumBlue)));

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.black,
      drawer: const GuestSidebarMenu(),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildHeroHeader(),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildTabsSection(),
                const SizedBox(height: 48),
                _buildPhilosophy(),
                const SizedBox(height: 48),
                _buildFeaturedProperty(),
                const SizedBox(height: 48),
                _buildInteractionGrid(),
                const SizedBox(height: 48),
                _buildInterestForm(),
                const SizedBox(height: 120),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroHeader() {
    return SliverToBoxAdapter(
      child: Stack(
        children: [
          Container(
            height: 500,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: NetworkImage('https://images.unsplash.com/photo-1613545325278-f24b0cae1224?auto=format&fit=crop&q=80'),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.6), Colors.transparent, Colors.black],
                  stops: const [0, 0.5, 1],
                ),
              ),
            ),
          ),
          Positioned(
            top: 60,
            left: 24,
            right: 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('M4 FAMILY', style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -1)),
                    Text('DEVELOPMENTS', style: GoogleFonts.montserrat(color: Colors.white60, fontWeight: FontWeight.w800, fontSize: 8, letterSpacing: 3)),
                  ],
                ),
                GestureDetector(
                  onTap: () => _scaffoldKey.currentState?.openDrawer(),
                  child: Container(
                    width: 50,
                    height: 40,
                    decoration: BoxDecoration(color: M4Theme.premiumBlue, borderRadius: BorderRadius.circular(14)),
                    child: const Icon(LucideIcons.moreHorizontal, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 60,
            left: 24,
            right: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Living the', style: GoogleFonts.lora(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w300)),
                Text('M4 Life', style: GoogleFonts.lora(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhilosophy() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('O', style: GoogleFonts.lora(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w400)),
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text('UR PHILOSOPHY', style: GoogleFonts.lora(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w300, letterSpacing: 1)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        RichText(
          text: TextSpan(
            style: GoogleFonts.montserrat(color: Colors.white70, fontSize: 14, height: 1.6),
            children: [
              const TextSpan(text: 'To redefine modern luxury living by crafting homes with cutting edge design, enduring quality and thoughtful amenities delivered with trust, transparency, timeliness, and a human touch that creates lasting value for every homeowner. '),
              WidgetSpan(
                child: GestureDetector(
                  onTap: () => context.push('/about'),
                  child: Text('Who We Are', style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabsSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: ['communities', 'properties', 'media'].map((tab) {
                    final isSelected = _activeTab.toLowerCase() == tab;
                    return GestureDetector(
                      onTap: () => setState(() => _activeTab = tab[0].toUpperCase() + tab.substring(1)),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 20),
                        child: Column(
                          children: [
                            Text(tab.toUpperCase(), style: GoogleFonts.montserrat(color: isSelected ? Colors.white : Colors.white24, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
                            const SizedBox(height: 8),
                            if (isSelected) Container(width: 20, height: 2, color: Colors.white),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () {
                if (_activeTab == 'Communities') context.push('/communities');
                else if (_activeTab == 'Properties') {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const ProjectListScreen()));
                }
                else context.push('/media');
              },
              child: Text('VIEW ALL', style: GoogleFonts.montserrat(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
            ),
          ],
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 380,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _activeTab == 'Communities' ? _communities.length : _projects.length,
            itemBuilder: (context, index) {
              final item = _activeTab == 'Communities' ? _communities[index] : _projects[index];
              return _buildTabCard(item);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTabCard(dynamic item) {
    final isCommunity = _activeTab == 'Communities';
    final apiClient = ref.read(apiClientProvider);
    final imageUrl = apiClient.resolveUrl(isCommunity 
        ? (item['image'] ?? 'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?auto=format&fit=crop&q=80')
        : (item['heroImage'] ?? 'https://images.unsplash.com/photo-1613545325278-f24b0cae1224?auto=format&fit=crop&q=80'));

    return GestureDetector(
      onTap: () {
        if (isCommunity) {
          context.push('/communities/${item['_id']}', extra: item);
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GuestProjectDetailScreen(
                projectId: item['_id']?.toString() ?? '',
                projectData: item,
              ),
            ),
          );
        }
      },
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              child: Image.network(
                imageUrl, 
                height: 200, 
                width: double.infinity, 
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 200,
                  color: const Color(0xFF1A1A1A),
                  child: Center(child: Icon(LucideIcons.image, color: Colors.white10, size: 40)),
                ),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 200,
                    color: const Color(0xFF1A1A1A),
                    child: Center(child: CircularProgressIndicator(value: loadingProgress.expectedTotalBytes != null ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes! : null, color: Colors.white10)),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['title']?.toString().toUpperCase() ?? '', style: GoogleFonts.lora(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text(isCommunity ? (item['overview'] ?? '') : (item['location']?['name'] ?? ''), 
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(color: Colors.white54, fontSize: 11, height: 1.5)),
                  if (!isCommunity) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      height: 44,
                      decoration: BoxDecoration(color: M4Theme.premiumBlue, borderRadius: BorderRadius.circular(12)),
                      child: Center(child: Text('EXPLORE NOW', style: GoogleFonts.montserrat(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1))),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedProperty() {
    if (_projects.isEmpty) return const SizedBox.shrink();
    final item = _projects[_featuredIndex % _projects.length];
    final apiClient = ref.read(apiClientProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('F', style: GoogleFonts.lora(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w400)),
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text('EATURED PROPERTY', style: GoogleFonts.lora(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w300, letterSpacing: 1)),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          height: 400,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            image: DecorationImage(
              image: NetworkImage(apiClient.resolveUrl(item['heroImage'] ?? '')),
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(40),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black.withOpacity(0.2), Colors.black],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('FEATURED PROPERTY', style: GoogleFonts.montserrat(color: const Color(0xFFC4A484), fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 2)),
                const SizedBox(height: 12),
                Text(item['title'] ?? '', style: GoogleFonts.lora(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w400)),
                const SizedBox(height: 8),
                Text('Experience ultimate luxury in the heart of the city.', style: GoogleFonts.montserrat(color: Colors.white54, fontSize: 11, letterSpacing: 1)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildFeatureIcon(LucideIcons.building2, 'FULLY\nFURNISHED'),
            _buildFeatureIcon(LucideIcons.mapPin, 'PRIME\nLOCATION'),
            _buildFeatureIcon(LucideIcons.smartphone, 'SMART\nHOMES'),
          ],
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            _buildCircularNavButton(LucideIcons.arrowLeft, () => setState(() => _featuredIndex = (_featuredIndex - 1 + _projects.length) % _projects.length)),
            const SizedBox(width: 16),
            Expanded(
              child: SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(backgroundColor: M4Theme.premiumBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  child: Text('READ MORE', style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2)),
                ),
              ),
            ),
            const SizedBox(width: 16),
            _buildCircularNavButton(LucideIcons.arrowRight, () => setState(() => _featuredIndex = (_featuredIndex + 1) % _projects.length)),
          ],
        ),
      ],
    );
  }

  Widget _buildFeatureIcon(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white38, size: 24),
        const SizedBox(height: 8),
        Text(label, textAlign: TextAlign.center, style: GoogleFonts.montserrat(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
      ],
    );
  }

  Widget _buildCircularNavButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(color: const Color(0xFF111111), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.05))),
        child: Icon(icon, color: Colors.white70, size: 20),
      ),
    );
  }

  Widget _buildInteractionGrid() {
    final items = [
      {'title': 'EXPLORE PROJECTS', 'desc': 'Browse our portfolio of properties', 'icon': LucideIcons.building2, 'route': '/projects'},
      {'title': 'BOOK A VIEWING', 'desc': 'Schedule a visit to our show apartment', 'icon': LucideIcons.layoutGrid, 'action': _scrollToInterestForm},
      {'title': 'SALES VIDEO CALL', 'desc': 'Talk to one of our sales expert', 'icon': LucideIcons.play, 'link': 'https://wa.me/912246018844'},
      {'title': 'REGISTER INTEREST', 'desc': 'Register your interest in our properties', 'icon': LucideIcons.user, 'action': _scrollToInterestForm},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('EXPLORE, CONNECT', style: GoogleFonts.lora(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w300)),
        Text('AND ENGAGE WITH US', style: GoogleFonts.lora(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w600)),
        const SizedBox(height: 32),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24), 
            border: Border.all(color: Colors.white.withOpacity(0.05)), 
          ),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, 
              crossAxisSpacing: 1, 
              mainAxisSpacing: 1, 
              childAspectRatio: 1.2
            ),
            itemCount: 4,
            itemBuilder: (context, i) => Material(
              color: const Color(0xFF111111),
              child: InkWell(
                onTap: () {
                  final item = items[i];
                  if (item['action'] != null) {
                    (item['action'] as Function)();
                  } else if (item['link'] != null) {
                    launchUrl(Uri.parse(item['link'] as String));
                  } else if (item['route'] == '/projects') {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const ProjectListScreen()));
                  } else if (item['route'] != null) {
                    context.push(item['route'] as String);
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle, 
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                          color: Colors.white.withOpacity(0.02),
                        ),
                        child: Icon(items[i]['icon'] as IconData, color: Colors.white, size: 18),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        items[i]['title'] as String, 
                        textAlign: TextAlign.center, 
                        style: GoogleFonts.montserrat(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)
                      ),
                      const SizedBox(height: 4),
                      Text(
                        items[i]['desc'] as String, 
                        textAlign: TextAlign.center, 
                        style: GoogleFonts.montserrat(color: Colors.white54, fontSize: 8)
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInterestForm() {
    return Column(
      key: _interestFormKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('R', style: GoogleFonts.lora(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w400)),
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text('EGISTER INTEREST', style: GoogleFonts.lora(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w300, letterSpacing: 1)),
            ),
          ],
        ),
        const SizedBox(height: 32),
        _buildLuxuryInput('Full Name *', _nameController),
        const SizedBox(height: 16),
        _buildLuxuryInput('Email *', _emailController),
        const SizedBox(height: 16),
        _buildLuxuryInput('Phone Number *', _phoneController),
        const SizedBox(height: 16),
        _buildLuxuryInput('Message', _messageController, isLong: true),
        const SizedBox(height: 24),
        Row(
          children: [
            Checkbox(
              value: _agreedToTerms,
              onChanged: (val) => setState(() => _agreedToTerms = val ?? false),
              activeColor: Colors.white,
              checkColor: Colors.black,
              side: const BorderSide(color: Colors.white24),
            ),
            Expanded(
              child: Text("I've read and agree to the Privacy Policy", style: GoogleFonts.montserrat(color: Colors.white54, fontSize: 10, letterSpacing: 1)),
            ),
          ],
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 64,
          child: ElevatedButton(
            onPressed: _submitting ? null : _submitInterest,
            style: ElevatedButton.styleFrom(backgroundColor: M4Theme.premiumBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            child: _submitting 
                ? const CircularProgressIndicator(color: Colors.white)
                : Text('SUBMIT INTEREST', style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2)),
          ),
        ),
      ],
    );
  }

  Widget _buildLuxuryInput(String hint, TextEditingController controller, {bool isLong = false}) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFF111111), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.05))),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        maxLines: isLong ? 5 : 1,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.montserrat(color: Colors.white24, fontSize: 13),
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
