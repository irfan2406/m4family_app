import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m4_mobile/core/theme/app_theme.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/presentation/screens/auth/login_screen.dart';
import 'package:m4_mobile/presentation/screens/auth/cp_login_screen.dart';
import 'package:m4_mobile/presentation/screens/auth/cp_signup_screen.dart';
import 'package:m4_mobile/presentation/screens/auth/cp_forgot_password_screen.dart';
import 'package:m4_mobile/presentation/screens/auth/onboarding_screen.dart';
import 'package:m4_mobile/presentation/screens/profile/profile_settings_screen.dart';
import 'package:m4_mobile/presentation/screens/profile/referral_screen.dart';
import 'package:m4_mobile/presentation/screens/support/schedule_visit_screen.dart';
import 'package:m4_mobile/presentation/screens/support/support_logs_screen.dart';
import 'package:m4_mobile/presentation/screens/support/support_screen.dart';
import 'package:m4_mobile/presentation/screens/support/contact_support_screen.dart';
import 'package:m4_mobile/presentation/screens/profile/my_property_screen.dart';
import 'package:m4_mobile/presentation/screens/profile/legal_vault_screen.dart';
import 'package:m4_mobile/presentation/screens/profile/deactivate_account_screen.dart';
import 'package:m4_mobile/presentation/widgets/main_shell.dart';
import 'package:m4_mobile/presentation/widgets/guest_main_shell.dart';
import 'package:m4_mobile/presentation/widgets/cp_main_shell.dart';
import 'package:m4_mobile/presentation/screens/notifications/notification_list_screen.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:m4_mobile/presentation/screens/about/about_screen.dart';
import 'package:m4_mobile/presentation/screens/communities/community_list_screen.dart';
import 'package:m4_mobile/presentation/screens/projects/project_list_screen.dart';
import 'package:m4_mobile/presentation/screens/careers/careers_screen.dart';
import 'package:m4_mobile/presentation/screens/communities/community_detail_screen.dart';
import 'package:m4_mobile/presentation/screens/projects/guest_project_detail_screen.dart';
import 'package:m4_mobile/presentation/screens/custom_views/custom_views_screen.dart';
import 'package:m4_mobile/presentation/screens/custom_views/guest_custom_views_screen.dart';
import 'package:m4_mobile/presentation/screens/support/contact_screen.dart';
import 'package:m4_mobile/presentation/screens/content_hub/content_hub_screen.dart';
import 'package:m4_mobile/presentation/screens/cp/cp_dashboard_screen.dart';
import 'package:m4_mobile/presentation/screens/cp/cp_referral_screen.dart';
import 'package:m4_mobile/presentation/screens/cp/cp_payments_screen.dart';
import 'package:m4_mobile/presentation/screens/cp/cp_tracker_screen.dart';
import 'package:m4_mobile/presentation/screens/cp/cp_hub_calculator_screen.dart';
import 'package:m4_mobile/presentation/screens/cp/cp_hub_analytics_screen.dart';
import 'package:m4_mobile/presentation/screens/cp/cp_hub_network_screen.dart';
import 'package:m4_mobile/presentation/screens/cp/cp_updates_screen.dart';
import 'package:m4_mobile/presentation/screens/cp/cp_hub_reports_screen.dart';
import 'package:m4_mobile/presentation/screens/cp/cp_hub_insights_screen.dart';
import 'package:m4_mobile/presentation/screens/cp/cp_my_bookings_screen.dart';
import 'package:m4_mobile/presentation/screens/cp/cp_site_visit_screen.dart';
import 'package:m4_mobile/presentation/screens/cp/cp_inquiry_screen.dart';
import 'package:m4_mobile/presentation/screens/cp/cp_profile_settings_screen.dart';
import 'package:m4_mobile/presentation/screens/cp/cp_elite_cp_connect_screen.dart';
import 'package:m4_mobile/presentation/screens/cp/cp_elite_investor_connect_screen.dart';
import 'package:m4_mobile/presentation/screens/cp/cp_tax_reports_screen.dart';
import 'package:m4_mobile/presentation/screens/cp/cp_visits_screen.dart';
import 'package:m4_mobile/presentation/screens/cp/cp_hub_screen.dart';
import 'package:m4_mobile/presentation/screens/cp/cp_project_detail_screen.dart';
import 'package:m4_mobile/presentation/screens/cp/cp_blog_screen.dart';
import 'package:m4_mobile/presentation/screens/cp/cp_shell_entry_screen.dart';
import 'package:m4_mobile/presentation/screens/selection_logs/selection_logs_screen.dart';
import 'package:m4_mobile/presentation/screens/custom_views/my_custom_views_screen.dart';
import 'package:m4_mobile/presentation/widgets/navigation_pill.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:m4_mobile/core/providers/theme_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() async {
  debugPaintSizeEnabled = false;
  debugPaintBaselinesEnabled = false;
  debugPaintPointersEnabled = false;
  debugPaintLayerBordersEnabled = false;
  debugRepaintRainbowEnabled = false;
  
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  
  const storage = FlutterSecureStorage();
  final themeStr = await storage.read(key: 'app_theme');
  final initialTheme = themeStr == 'light' ? ThemeMode.light : ThemeMode.dark;

  runApp(
    ProviderScope(
      overrides: [
        themeProvider.overrideWith((ref) => ThemeNotifier(ref, initialTheme))
      ],
      child: const M4FamilyApp(),
    ),
  );
}

class M4FamilyApp extends ConsumerWidget {
  const M4FamilyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    
    return MaterialApp.router(
      title: 'M4 Family',
      debugShowCheckedModeBanner: false,
      theme: M4Theme.lightTheme,
      darkTheme: M4Theme.darkTheme,
      themeMode: themeMode,
      routerConfig: _router,
    );
  }
}


// Basic router configuration
final GoRouter _router = GoRouter(
  initialLocation: '/onboarding',
  routes: [
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/auth/cp/login',
      builder: (context, state) => const CpLoginScreen(),
    ),
    GoRoute(
      path: '/auth/cp/signup',
      builder: (context, state) => const CpSignupScreen(),
    ),
    GoRoute(
      path: '/auth/cp/forgot-password',
      builder: (context, state) => const CpForgotPasswordScreen(),
    ),
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const ConditionalHomeShell(),
    ),
    GoRoute(
      path: '/cp/dashboard',
      builder: (context, state) => const CpDashboardScreen(),
    ),
    GoRoute(
      path: '/cp/referral',
      builder: (context, state) => const CpReferralScreen(),
    ),
    GoRoute(
      path: '/cp/payments',
      builder: (context, state) => const CpPaymentsScreen(),
    ),
    GoRoute(
      path: '/cp/tracker',
      builder: (context, state) => const CpTrackerScreen(),
    ),
    GoRoute(
      path: '/cp/hub/analytics',
      builder: (context, state) => const CpHubAnalyticsScreen(),
    ),
    GoRoute(
      path: '/cp/hub/calculator',
      builder: (context, state) => const CpHubCalculatorScreen(),
    ),
    GoRoute(
      path: '/cp/hub/network',
      builder: (context, state) => const CpHubNetworkScreen(),
    ),
    GoRoute(
      path: '/cp/hub/reports',
      builder: (context, state) => const CpHubReportsScreen(),
    ),
    GoRoute(
      path: '/cp/hub/insights',
      builder: (context, state) => const CpHubInsightsScreen(),
    ),
    GoRoute(
      path: '/cp/booking/my-bookings',
      builder: (context, state) => const CpMyBookingsScreen(),
    ),
    GoRoute(
      path: '/cp/booking/site-visit',
      builder: (context, state) => const CpSiteVisitScreen(),
    ),
    GoRoute(
      path: '/cp/booking/schedule-visit',
      builder: (context, state) => const CpSiteVisitScreen(),
    ),
    GoRoute(
      path: '/cp/booking/inquiry',
      builder: (context, state) => const CpInquiryScreen(),
    ),
    GoRoute(
      path: '/cp/settings',
      builder: (context, state) => const CpProfileSettingsScreen(),
    ),
    GoRoute(
      path: '/cp/profile/settings',
      builder: (context, state) => const CpProfileSettingsScreen(),
    ),
    GoRoute(
      path: '/cp/profile/ticket-logs',
      builder: (context, state) => const SupportLogsScreen(),
    ),
    GoRoute(
      path: '/cp/elite/cp-connect',
      builder: (context, state) => const CpEliteCpConnectScreen(),
    ),
    GoRoute(
      path: '/cp/elite/investor-connect',
      builder: (context, state) => const CpEliteInvestorConnectScreen(),
    ),
    GoRoute(
      path: '/cp/tax-reports',
      builder: (context, state) => const CpTaxReportsScreen(),
    ),
    GoRoute(
      path: '/cp/hub',
      builder: (context, state) => const CpHubScreen(),
    ),
    GoRoute(
      path: '/cp/updates',
      builder: (context, state) => const CpUpdatesScreen(),
    ),
    GoRoute(
      path: '/cp/visits',
      builder: (context, state) => const CpVisitsScreen(),
    ),
    GoRoute(
      path: '/cp/blog',
      builder: (context, state) => const CpBlogScreen(),
    ),
    GoRoute(
      path: '/cp/contact',
      builder: (context, state) => const ContactSupportScreen(),
    ),
    GoRoute(
      path: '/cp/support',
      builder: (context, state) => const CpShellEntryScreen(index: 4),
    ),
    GoRoute(
      path: '/cp/projects',
      builder: (context, state) => const CpShellEntryScreen(index: 3),
    ),
    GoRoute(
      path: '/cp/projects/:id',
      builder: (context, state) => CpProjectDetailScreen(
        projectId: state.pathParameters['id']!,
        projectData: state.extra as Map<String, dynamic>?,
      ),
    ),
    GoRoute(
      path: '/profile/settings',
      builder: (context, state) => const ProfileSettingsScreen(),
    ),
    GoRoute(
      path: '/profile/referral',
      builder: (context, state) => const ReferralScreen(),
    ),
    GoRoute(
      path: '/my-custom-views',
      builder: (context, state) => MyCustomViewsScreen(),
    ),
    GoRoute(
      path: '/profile/custom-requests',
      builder: (context, state) => SelectionLogsScreen(),
    ),
    GoRoute(
      path: '/support/schedule-visit',
      builder: (context, state) => const ScheduleVisitScreen(),
    ),
    GoRoute(
      path: '/support/logs',
      builder: (context, state) => const SupportLogsScreen(),
    ),
    GoRoute(
      path: '/support/documents',
      builder: (context, state) => const LegalVaultScreen(),
    ),
    GoRoute(
      path: '/profile/my-property',
      builder: (context, state) => const MyPropertyScreen(),
    ),
    GoRoute(
      path: '/profile/legal-vault',
      builder: (context, state) => LegalVaultScreen(),
    ),
    GoRoute(
      path: '/profile/deactivate',
      builder: (context, state) => DeactivateAccountScreen(),
    ),
    GoRoute(
      path: '/support',
      builder: (context, state) => SupportScreen(),
    ),
    GoRoute(
      path: '/support/contact',
      builder: (context, state) => const ContactSupportScreen(),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => NotificationListScreen(),
    ),
    GoRoute(
      path: '/media',
      builder: (context, state) => GuestContentHubScreen(
        title: 'MEDIA\nGALLERY',
        subtitle: 'Stay updated with our latest multimedia releases.',
        typeIcon: LucideIcons.play,
        emptyMessage: 'No media posts found',
        contentType: 'media',
      ),
    ),
    GoRoute(
      path: '/highlights',
      builder: (context, state) => const GuestContentHubScreen(
        title: 'PROJECT\nHIGHLIGHTS',
        subtitle: 'Stay updated with our latest achievements and milestones.',
        typeIcon: LucideIcons.zap,
        emptyMessage: 'No highlights posts found',
        contentType: 'highlight',
      ),
    ),
    GoRoute(
      path: '/events',
      builder: (context, state) => const GuestContentHubScreen(
        title: 'M4 EVENTS',
        subtitle: 'Stay updated with our latest upcoming events.',
        typeIcon: LucideIcons.calendar,
        emptyMessage: 'No event posts found',
        contentType: 'event',
      ),
    ),
    GoRoute(
      path: '/blog',
      builder: (context, state) => const GuestContentHubScreen(
        title: 'M4 BLOG',
        subtitle: 'Stay updated with our latest insights and news.',
        typeIcon: LucideIcons.fileText,
        emptyMessage: 'No blog posts found',
        contentType: 'blog',
      ),
    ),
    GoRoute(
      path: '/about',
      builder: (context, state) => const AboutScreen(),
    ),
    GoRoute(
      path: '/communities',
      builder: (context, state) => const CommunityListScreen(),
    ),
    GoRoute(
      path: '/projects',
      builder: (context, state) => const ProjectListScreen(),
    ),
    GoRoute(
      path: '/careers',
      builder: (context, state) => const CareersScreen(),
    ),
    GoRoute(
      path: '/contact',
      builder: (context, state) => const ContactSupportScreen(),
    ),
    GoRoute(
      path: '/communities/:id',
      builder: (context, state) => CommunityDetailScreen(
        community: state.extra ?? {'_id': state.pathParameters['id']!},
      ),
    ),
    GoRoute(
      path: '/projects/:id',
      builder: (context, state) => GuestProjectDetailScreen(
        projectId: state.pathParameters['id']!,
        projectData: state.extra as Map<String, dynamic>?,
      ),
    ),
    GoRoute(
      path: '/custom-views',
      builder: (context, state) {
        final authState = ProviderScope.containerOf(context).read(authProvider);
        if (authState.status == AuthStatus.authenticated) {
          return const CustomViewsScreen();
        }
        return const GuestCustomViewsScreen();
      },
    ),
  ],
);

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Main Logo
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Image.asset(
                  'assets/m4_family_logo.png',
                  color: const Color(0xFFFFD700),
                  colorBlendMode: BlendMode.srcIn,
                ),
              ),
            ).animate().scale(duration: 500.ms, curve: Curves.easeOut),
            const SizedBox(height: 24),
            const CircularProgressIndicator(color: Colors.black),
          ],
        ),
      ),
    );
  }
}

class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('Coming Soon: $title')),
    );
  }
}

class ConditionalHomeShell extends ConsumerWidget {
  const ConditionalHomeShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(authProvider.select((s) => s.status));
    final user = ref.watch(authProvider.select((s) => s.user));

    if (status == AuthStatus.authenticated) {
      final role = user?['role']?.toString().toLowerCase();
      if (role == 'cp') {
        return const CpMainShell();
      }
      return const MainShell();
    }

    return const GuestMainShell();
  }
}
