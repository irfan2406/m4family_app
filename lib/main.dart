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
import 'package:m4_mobile/presentation/screens/cp/cp_hub_reports_screen.dart';
import 'package:m4_mobile/presentation/screens/cp/cp_hub_insights_screen.dart';
import 'package:m4_mobile/presentation/screens/cp/cp_my_bookings_screen.dart';
import 'package:m4_mobile/presentation/screens/cp/cp_site_visit_screen.dart';
import 'package:m4_mobile/presentation/screens/cp/cp_inquiry_screen.dart';
import 'package:m4_mobile/presentation/screens/cp/cp_profile_settings_screen.dart';
import 'package:m4_mobile/presentation/screens/cp/cp_elite_cp_connect_screen.dart';
import 'package:m4_mobile/presentation/screens/cp/cp_elite_investor_connect_screen.dart';
import 'package:m4_mobile/presentation/screens/cp/cp_tax_reports_screen.dart';

import 'package:m4_mobile/core/providers/theme_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
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
      path: '/profile/settings',
      builder: (context, state) => const ProfileSettingsScreen(),
    ),
    GoRoute(
      path: '/profile/referral',
      builder: (context, state) => const ReferralScreen(),
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
      builder: (context, state) => const LegalVaultScreen(),
    ),
    GoRoute(
      path: '/profile/deactivate',
      builder: (context, state) => const DeactivateAccountScreen(),
    ),
    GoRoute(
      path: '/support',
      builder: (context, state) => const SupportScreen(),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationListScreen(),
    ),
    GoRoute(
      path: '/media',
      builder: (context, state) => const GuestContentHubScreen(
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
        typeIcon: LucideIcons.calendarDays,
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
      builder: (context, state) => const ContactScreen(),
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
            // Luxury Logo Placeholder
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: M4Theme.premiumBlue, width: 2),
              ),
              child: const Text(
                'M4',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: M4Theme.premiumBlue,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(color: M4Theme.premiumBlue),
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
