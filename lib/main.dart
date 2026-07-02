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
import 'package:m4_mobile/presentation/screens/profile/guest_profile_screen.dart';
import 'package:m4_mobile/presentation/screens/profile/family_members_screen.dart';
import 'package:m4_mobile/presentation/screens/profile/app_settings_screen.dart';
import 'package:m4_mobile/presentation/screens/profile/portfolio_screen.dart';
import 'package:m4_mobile/presentation/screens/support/ticket_detail_screen.dart';
import 'package:m4_mobile/presentation/screens/search/search_screen.dart';
import 'package:m4_mobile/presentation/screens/projects/premium_upsell_screen.dart';
import 'package:m4_mobile/presentation/screens/projects/premium_checkout_screen.dart';
import 'package:m4_mobile/presentation/screens/profile/referral_screen.dart';
import 'package:m4_mobile/presentation/screens/support/schedule_visit_screen.dart';
import 'package:m4_mobile/presentation/screens/support/support_logs_screen.dart';
import 'package:m4_mobile/presentation/screens/support/support_screen.dart';
import 'package:m4_mobile/presentation/screens/support/help_center_screen.dart';
import 'package:m4_mobile/presentation/screens/support/support_tickets_screen.dart';
import 'package:m4_mobile/presentation/screens/support/create_ticket_screen.dart';
import 'package:m4_mobile/presentation/screens/support/contact_support_screen.dart';
import 'package:m4_mobile/presentation/screens/profile/my_property_screen.dart';
import 'package:m4_mobile/presentation/screens/booking/booking_start_screen.dart';
import 'package:m4_mobile/presentation/screens/booking/inquiry_screen.dart';
import 'package:m4_mobile/presentation/screens/booking/site_visit_screen.dart';
import 'package:m4_mobile/presentation/screens/booking/payment_plan_screen.dart';
import 'package:m4_mobile/presentation/screens/booking/token_payment_screen.dart';
import 'package:m4_mobile/presentation/screens/booking/booking_confirmation_screen.dart';
import 'package:m4_mobile/presentation/screens/profile/legal_vault_screen.dart';
import 'package:m4_mobile/presentation/screens/profile/deactivate_account_screen.dart';
import 'package:m4_mobile/presentation/widgets/main_shell.dart';
import 'package:m4_mobile/presentation/widgets/guest_main_shell.dart';
import 'package:m4_mobile/presentation/widgets/cp_main_shell.dart';
import 'package:m4_mobile/presentation/widgets/investor_main_shell.dart';
import 'package:m4_mobile/presentation/providers/investor_shell_provider.dart';
import 'package:m4_mobile/presentation/screens/investor/investor_login_screen.dart';
import 'package:m4_mobile/presentation/screens/investor/investor_portfolio_screen.dart';
import 'package:m4_mobile/presentation/screens/investor/investor_payments_screen.dart';
import 'package:m4_mobile/presentation/screens/investor/investor_payment_detail_screen.dart';
import 'package:m4_mobile/presentation/screens/investor/investor_installments_screen.dart';
import 'package:m4_mobile/presentation/screens/investor/investor_tax_reports_screen.dart';
import 'package:m4_mobile/presentation/screens/investor/investor_tax_report_detail_screen.dart';
import 'package:m4_mobile/presentation/screens/investor/investor_documents_screen.dart';
import 'package:m4_mobile/presentation/screens/investor/investor_document_detail_screen.dart';
import 'package:m4_mobile/presentation/screens/investor/investor_project_detail_screen.dart';
import 'package:m4_mobile/presentation/screens/investor/investor_elite_screen.dart';
import 'package:m4_mobile/presentation/screens/investor/investor_elite_cp_connect_screen.dart';
import 'package:m4_mobile/presentation/screens/investor/investor_elite_investor_connect_screen.dart';
import 'package:m4_mobile/presentation/screens/investor/investor_referral_screen.dart';
import 'package:m4_mobile/presentation/screens/investor/investor_referral_active_screen.dart';
import 'package:m4_mobile/presentation/screens/investor/investor_referral_closed_screen.dart';
import 'package:m4_mobile/presentation/screens/investor/investor_cp_screen.dart';
import 'package:m4_mobile/presentation/screens/investor/investor_settings_screen.dart';
import 'package:m4_mobile/presentation/screens/investor/investor_security_screen.dart';
import 'package:m4_mobile/presentation/screens/investor/investor_change_password_screen.dart';
import 'package:m4_mobile/presentation/screens/investor/investor_profile_details_screen.dart';
import 'package:m4_mobile/presentation/screens/investor/investor_profile_change_password_screen.dart';
import 'package:m4_mobile/presentation/screens/investor/investor_delete_account_screen.dart';
import 'package:m4_mobile/presentation/screens/investor/investor_purge_cache_screen.dart';
import 'package:m4_mobile/presentation/screens/notifications/notification_list_screen.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:m4_mobile/presentation/screens/about/about_screen.dart';
import 'package:m4_mobile/presentation/screens/communities/community_list_screen.dart';
import 'package:m4_mobile/presentation/screens/projects/project_list_screen.dart';
import 'package:m4_mobile/presentation/screens/careers/careers_screen.dart';
import 'package:m4_mobile/presentation/screens/communities/community_detail_screen.dart';
import 'package:m4_mobile/presentation/screens/communities/community_projects_screen.dart';
import 'package:m4_mobile/presentation/screens/pages/page_detail_screen.dart';
import 'package:m4_mobile/presentation/screens/projects/guest_project_detail_screen.dart';
import 'package:m4_mobile/presentation/screens/custom_views/custom_views_screen.dart';
import 'package:m4_mobile/presentation/screens/custom_views/guest_custom_views_screen.dart';
import 'package:m4_mobile/presentation/screens/support/contact_screen.dart';
import 'package:m4_mobile/presentation/screens/content_hub/content_hub_screen.dart';
import 'package:m4_mobile/presentation/screens/cp/cp_dashboard_screen.dart';
import 'package:m4_mobile/presentation/screens/cp/cp_booking_start_screen.dart';
import 'package:m4_mobile/presentation/screens/cp/cp_payment_plan_screen.dart';
import 'package:m4_mobile/presentation/screens/cp/cp_booking_confirmation_screen.dart';
import 'package:m4_mobile/presentation/screens/cp/cp_token_payment_screen.dart';
import 'package:m4_mobile/presentation/screens/cp/cp_referral_redeem_screen.dart';
import 'package:m4_mobile/presentation/screens/cp/cp_payment_detail_screen.dart';
import 'package:m4_mobile/presentation/screens/cp/cp_elite_screen.dart';
import 'package:m4_mobile/presentation/screens/cp/cp_residential_connect_screen.dart';
import 'package:m4_mobile/presentation/screens/cp/cp_security_screen.dart';
import 'package:m4_mobile/presentation/screens/cp/cp_change_password_screen.dart';
import 'package:m4_mobile/presentation/screens/cp/cp_tax_report_detail_screen.dart';
import 'package:m4_mobile/presentation/screens/cp/cp_profile_details_screen.dart';
import 'package:m4_mobile/presentation/screens/cp/cp_delete_account_screen.dart';
import 'package:m4_mobile/presentation/screens/cp/cp_employees_screen.dart';
import 'package:m4_mobile/presentation/screens/cp/cp_purge_cache_screen.dart';
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
        themeProvider.overrideWith((ref) => ThemeNotifier(ref, initialTheme)),
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
      builder: (context, state) {
        final step =
            int.tryParse(state.uri.queryParameters['step'] ?? '0') ?? 0;
        final role = state.uri.queryParameters['role'] ?? 'CUSTOMER';
        return LoginScreen(initialStep: step, initialRole: role);
      },
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
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
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
      path: '/cp/elite',
      builder: (context, state) => const CpEliteScreen(),
    ),
    GoRoute(
      path: '/cp/elite/residential-connect',
      builder: (context, state) => const CpResidentialConnectScreen(),
    ),
    GoRoute(
      path: '/cp/booking/start',
      builder: (context, state) => const CpBookingStartScreen(),
    ),
    GoRoute(
      path: '/cp/booking/payment-plan',
      builder: (context, state) => CpPaymentPlanScreen(
        projectId: state.uri.queryParameters['projectId'] ?? '',
        project: state.extra,
      ),
    ),
    GoRoute(
      path: '/cp/booking/confirmation',
      builder: (context, state) => CpBookingConfirmationScreen(
        projectId: state.uri.queryParameters['projectId'] ?? '',
        bookingId: state.uri.queryParameters['bookingId'],
        amount: state.uri.queryParameters['amount'],
        project: state.extra as Map<String, dynamic>?,
      ),
    ),
    GoRoute(
      path: '/cp/booking/token-payment',
      builder: (context, state) => CpTokenPaymentScreen(
        projectId: state.uri.queryParameters['projectId'] ?? '',
      ),
    ),
    GoRoute(
      path: '/cp/referral/redeem',
      builder: (context, state) => const CpReferralRedeemScreen(),
    ),
    GoRoute(
      path: '/cp/payments/:id',
      builder: (context, state) => CpPaymentDetailScreen(
        commissionId: state.pathParameters['id']!,
        initialData: state.extra as Map<String, dynamic>?,
      ),
    ),
    // --- CP breadth (reuse existing screens + new CP profile/security screens) ---
    GoRoute(
      path: '/cp/notifications',
      builder: (context, state) => NotificationListScreen(),
    ),
    GoRoute(
      path: '/cp/communities',
      builder: (context, state) => const CommunityListScreen(),
    ),
    GoRoute(
      path: '/cp/communities/:slug',
      builder: (context, state) => CommunityDetailScreen(
        community: state.extra ?? {'_id': state.pathParameters['slug']!},
      ),
    ),
    GoRoute(
      path: '/cp/communities/:slug/projects',
      builder: (context, state) =>
          CommunityProjectsListScreen(slug: state.pathParameters['slug']!),
    ),
    GoRoute(
      path: '/cp/events',
      builder: (context, state) => const GuestContentHubScreen(
        title: 'M4 EVENTS',
        subtitle: 'Stay updated with our latest upcoming events.',
        typeIcon: LucideIcons.calendar,
        emptyMessage: 'No event posts found',
        contentType: 'event',
      ),
    ),
    GoRoute(
      path: '/cp/highlights',
      builder: (context, state) => const GuestContentHubScreen(
        title: 'PROJECT\nHIGHLIGHTS',
        subtitle: 'Stay updated with our latest achievements and milestones.',
        typeIcon: LucideIcons.zap,
        emptyMessage: 'No highlights posts found',
        contentType: 'highlight',
      ),
    ),
    GoRoute(
      path: '/cp/media',
      builder: (context, state) => const GuestContentHubScreen(
        title: 'MEDIA\nGALLERY',
        subtitle: 'Stay updated with our latest multimedia releases.',
        typeIcon: LucideIcons.play,
        emptyMessage: 'No media posts found',
        contentType: 'media',
      ),
    ),
    GoRoute(
      path: '/cp/support/help-center',
      builder: (context, state) => const HelpCenterScreen(),
    ),
    GoRoute(
      path: '/cp/help',
      builder: (context, state) => const HelpCenterScreen(),
    ),
    GoRoute(
      path: '/cp/support/tickets',
      builder: (context, state) => const SupportTicketsScreen(),
    ),
    GoRoute(
      path: '/cp/support/tickets/:id',
      builder: (context, state) => TicketDetailScreen(
        ticketId: state.pathParameters['id']!,
        initialTicket: state.extra as Map<String, dynamic>?,
      ),
    ),
    GoRoute(
      path: '/cp/support/new-ticket',
      builder: (context, state) => const CreateTicketScreen(),
    ),
    GoRoute(
      path: '/cp/support/logs',
      builder: (context, state) => const SupportLogsScreen(),
    ),
    GoRoute(
      path: '/cp/documents',
      builder: (context, state) => const LegalVaultScreen(),
    ),
    GoRoute(
      path: '/cp/documents/:id',
      builder: (context, state) => const LegalVaultScreen(),
    ),
    GoRoute(
      path: '/cp/customization',
      builder: (context, state) => MyCustomViewsScreen(),
    ),
    GoRoute(
      path: '/cp/customization/detail',
      builder: (context, state) => MyCustomViewsScreen(),
    ),
    GoRoute(
      // Web parity: CP custom-views renders the "Interactive Living /
      // Design Your Destiny" showcase (CustomViewsContent treats portal="cp"
      // as isGuest), not the personalisation-suite portfolio.
      path: '/cp/custom-views',
      builder: (context, state) => const GuestCustomViewsScreen(),
    ),
    GoRoute(
      path: '/cp/search',
      builder: (context, state) => const SearchScreen(),
    ),
    GoRoute(
      path: '/cp/about',
      builder: (context, state) => const AboutScreen(),
    ),
    GoRoute(
      path: '/cp/careers',
      builder: (context, state) => const CareersScreen(),
    ),
    GoRoute(
      path: '/cp/privacy-policy',
      builder: (context, state) =>
          const PageDetailScreen(slug: 'privacy-policy'),
    ),
    GoRoute(
      path: '/cp/projects/premium-upsell',
      builder: (context, state) => const PremiumUpsellScreen(),
    ),
    GoRoute(
      path: '/cp/projects/premium-upsell/checkout',
      builder: (context, state) => const PremiumCheckoutScreen(),
    ),
    GoRoute(
      path: '/cp/profile/app-settings',
      builder: (context, state) => const AppSettingsScreen(),
    ),
    GoRoute(
      path: '/cp/profile/portfolio',
      builder: (context, state) => const PortfolioScreen(),
    ),
    GoRoute(
      path: '/cp/security',
      builder: (context, state) => const CpSecurityScreen(),
    ),
    GoRoute(
      path: '/cp/change-password',
      builder: (context, state) => const CpChangePasswordScreen(),
    ),
    GoRoute(
      path: '/cp/tax-reports/:id',
      builder: (context, state) => CpTaxReportDetailScreen(
        reportId: state.pathParameters['id']!,
        initialData: state.extra as Map<String, dynamic>?,
      ),
    ),
    GoRoute(
      path: '/cp/profile/details',
      builder: (context, state) => const CpProfileDetailsScreen(),
    ),
    GoRoute(
      path: '/cp/profile/delete-account',
      builder: (context, state) => const CpDeleteAccountScreen(),
    ),
    GoRoute(
      path: '/cp/profile/employees',
      builder: (context, state) => const CpEmployeesScreen(),
    ),
    GoRoute(
      path: '/cp/profile/purge-cache',
      builder: (context, state) => const CpPurgeCacheScreen(),
    ),
    // --- Investor portal ---
    GoRoute(
      path: '/investor/login',
      builder: (context, state) => const InvestorLoginScreen(),
    ),
    GoRoute(
      path: '/investor/home',
      builder: (context, state) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => ProviderScope.containerOf(
            context,
          ).read(investorNavigationIndexProvider.notifier).state = 0,
        );
        return const InvestorMainShell();
      },
    ),
    GoRoute(
      path: '/investor/projects',
      builder: (context, state) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => ProviderScope.containerOf(
            context,
          ).read(investorNavigationIndexProvider.notifier).state = 1,
        );
        return const InvestorMainShell();
      },
    ),
    GoRoute(
      path: '/investor/support',
      builder: (context, state) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => ProviderScope.containerOf(
            context,
          ).read(investorNavigationIndexProvider.notifier).state = 2,
        );
        return const InvestorMainShell();
      },
    ),
    GoRoute(
      path: '/investor/profile',
      builder: (context, state) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => ProviderScope.containerOf(
            context,
          ).read(investorNavigationIndexProvider.notifier).state = 3,
        );
        return const InvestorMainShell();
      },
    ),
    // Investor money / portfolio (new investor-specific screens)
    GoRoute(
      path: '/investor/portfolio',
      builder: (context, state) => const InvestorPortfolioScreen(),
    ),
    GoRoute(
      path: '/investor/profile/portfolio',
      builder: (context, state) => const InvestorPortfolioScreen(),
    ),
    GoRoute(
      path: '/investor/payments',
      builder: (context, state) => const InvestorPaymentsScreen(),
    ),
    GoRoute(
      path: '/investor/payments/:id',
      builder: (context, state) => InvestorPaymentDetailScreen(
        paymentId: state.pathParameters['id']!,
        initialData: state.extra as Map<String, dynamic>?,
      ),
    ),
    GoRoute(
      path: '/investor/installments',
      builder: (context, state) => const InvestorInstallmentsScreen(),
    ),
    GoRoute(
      path: '/investor/tax-reports',
      builder: (context, state) => const InvestorTaxReportsScreen(),
    ),
    GoRoute(
      path: '/investor/tax-reports/:id',
      builder: (context, state) => InvestorTaxReportDetailScreen(
        reportId: state.pathParameters['id']!,
        initialData: state.extra as Map<String, dynamic>?,
      ),
    ),
    GoRoute(
      path: '/investor/documents',
      builder: (context, state) => const InvestorDocumentsScreen(),
    ),
    GoRoute(
      path: '/investor/documents/:id',
      builder: (context, state) =>
          InvestorDocumentDetailScreen(documentId: state.pathParameters['id']!),
    ),
    // Investor projects — premium-upsell BEFORE :id so it isn't captured as a param
    GoRoute(
      path: '/investor/projects/premium-upsell',
      builder: (context, state) => const PremiumUpsellScreen(),
    ),
    GoRoute(
      path: '/investor/projects/premium-upsell/checkout',
      builder: (context, state) => const PremiumCheckoutScreen(),
    ),
    GoRoute(
      path: '/investor/projects/:id',
      builder: (context, state) =>
          InvestorProjectDetailScreen(projectId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/investor/projects/:id/3d-view',
      builder: (context, state) =>
          InvestorProjectDetailScreen(projectId: state.pathParameters['id']!),
    ),
    // Investor elite
    GoRoute(
      path: '/investor/elite',
      builder: (context, state) => const InvestorEliteScreen(),
    ),
    GoRoute(
      path: '/investor/elite/cp-connect',
      builder: (context, state) => const InvestorEliteCpConnectScreen(),
    ),
    GoRoute(
      path: '/investor/elite/investor-connect',
      builder: (context, state) => const InvestorEliteInvestorConnectScreen(),
    ),
    GoRoute(
      path: '/investor/elite/residential-connect',
      builder: (context, state) => const CpResidentialConnectScreen(),
    ),
    // Investor referral
    GoRoute(
      path: '/investor/referral',
      builder: (context, state) => const InvestorReferralScreen(),
    ),
    GoRoute(
      path: '/investor/referral/active',
      builder: (context, state) => const InvestorReferralActiveScreen(),
    ),
    GoRoute(
      path: '/investor/referral/closed',
      builder: (context, state) => const InvestorReferralClosedScreen(),
    ),
    // Investor settings / security / profile subroutes
    GoRoute(
      path: '/investor/cp',
      builder: (context, state) => const InvestorCpScreen(),
    ),
    GoRoute(
      path: '/investor/settings',
      builder: (context, state) => const InvestorSettingsScreen(),
    ),
    GoRoute(
      path: '/investor/security',
      builder: (context, state) => const InvestorSecurityScreen(),
    ),
    GoRoute(
      path: '/investor/change-password',
      builder: (context, state) => const InvestorChangePasswordScreen(),
    ),
    GoRoute(
      path: '/investor/profile/details',
      builder: (context, state) => const InvestorProfileDetailsScreen(),
    ),
    GoRoute(
      path: '/investor/profile/change-password',
      builder: (context, state) => const InvestorProfileChangePasswordScreen(),
    ),
    GoRoute(
      path: '/investor/profile/delete-account',
      builder: (context, state) => const InvestorDeleteAccountScreen(),
    ),
    GoRoute(
      path: '/investor/profile/purge-cache',
      builder: (context, state) => const InvestorPurgeCacheScreen(),
    ),
    GoRoute(
      path: '/investor/profile/family',
      builder: (context, state) => const FamilyMembersScreen(),
    ),
    GoRoute(
      path: '/investor/profile/app-settings',
      builder: (context, state) => const AppSettingsScreen(),
    ),
    GoRoute(
      path: '/investor/profile/ticket-logs',
      builder: (context, state) => const SupportLogsScreen(),
    ),
    GoRoute(
      path: '/investor/profile/ticket-logs/new',
      builder: (context, state) => const CreateTicketScreen(),
    ),
    // Investor reuse routes (existing screens)
    GoRoute(
      path: '/investor/communities',
      builder: (context, state) => const CommunityListScreen(),
    ),
    GoRoute(
      path: '/investor/communities/:slug',
      builder: (context, state) => CommunityDetailScreen(
        community: state.extra ?? {'_id': state.pathParameters['slug']!},
      ),
    ),
    GoRoute(
      path: '/investor/communities/:slug/projects',
      builder: (context, state) =>
          CommunityProjectsListScreen(slug: state.pathParameters['slug']!),
    ),
    GoRoute(
      path: '/investor/notifications',
      builder: (context, state) => NotificationListScreen(),
    ),
    GoRoute(
      path: '/investor/search',
      builder: (context, state) => const SearchScreen(),
    ),
    GoRoute(
      path: '/investor/custom-views',
      builder: (context, state) => MyCustomViewsScreen(),
    ),
    GoRoute(
      path: '/investor/my-custom-views',
      builder: (context, state) => MyCustomViewsScreen(),
    ),
    GoRoute(
      path: '/investor/about',
      builder: (context, state) => const AboutScreen(),
    ),
    GoRoute(
      path: '/investor/careers',
      builder: (context, state) => const CareersScreen(),
    ),
    GoRoute(
      path: '/investor/contact',
      builder: (context, state) => const ContactScreen(),
    ),
    GoRoute(
      path: '/investor/privacy-policy',
      builder: (context, state) =>
          const PageDetailScreen(slug: 'privacy-policy'),
    ),
    GoRoute(
      path: '/investor/help',
      builder: (context, state) => const HelpCenterScreen(),
    ),
    GoRoute(
      path: '/investor/events',
      builder: (context, state) => const GuestContentHubScreen(
        title: 'M4 EVENTS',
        subtitle: 'Stay updated with our latest upcoming events.',
        typeIcon: LucideIcons.calendar,
        emptyMessage: 'No event posts found',
        contentType: 'event',
      ),
    ),
    GoRoute(
      path: '/investor/highlights',
      builder: (context, state) => const GuestContentHubScreen(
        title: 'PROJECT\nHIGHLIGHTS',
        subtitle: 'Stay updated with our latest achievements and milestones.',
        typeIcon: LucideIcons.zap,
        emptyMessage: 'No highlights posts found',
        contentType: 'highlight',
      ),
    ),
    GoRoute(
      path: '/investor/media',
      builder: (context, state) => const GuestContentHubScreen(
        title: 'MEDIA\nGALLERY',
        subtitle: 'Stay updated with our latest multimedia releases.',
        typeIcon: LucideIcons.play,
        emptyMessage: 'No media posts found',
        contentType: 'media',
      ),
    ),
    GoRoute(
      path: '/investor/blog',
      builder: (context, state) => const GuestContentHubScreen(
        title: 'M4 BLOG',
        subtitle: 'Stay updated with our latest insights and news.',
        typeIcon: LucideIcons.fileText,
        emptyMessage: 'No blog posts found',
        contentType: 'blog',
      ),
    ),
    GoRoute(
      path: '/investor/support/help-center',
      builder: (context, state) => const HelpCenterScreen(),
    ),
    GoRoute(
      path: '/investor/support/logs',
      builder: (context, state) => const SupportLogsScreen(),
    ),
    GoRoute(
      path: '/investor/support/new-ticket',
      builder: (context, state) => const CreateTicketScreen(),
    ),
    GoRoute(
      path: '/investor/support/tickets',
      builder: (context, state) => const SupportTicketsScreen(),
    ),
    GoRoute(
      path: '/investor/support/tickets/:id',
      builder: (context, state) => TicketDetailScreen(
        ticketId: state.pathParameters['id']!,
        initialTicket: state.extra as Map<String, dynamic>?,
      ),
    ),
    // Investor booking flow (reuse user booking screens, projectId via query)
    GoRoute(
      path: '/investor/booking/start',
      builder: (context, state) => BookingStartScreen(
        projectId: state.uri.queryParameters['projectId'] ?? '',
        project: state.extra,
      ),
    ),
    GoRoute(
      path: '/investor/booking/inquiry',
      builder: (context, state) => InquiryScreen(
        projectId: state.uri.queryParameters['projectId'] ?? '',
        project: state.extra,
      ),
    ),
    GoRoute(
      path: '/investor/booking/site-visit',
      builder: (context, state) => SiteVisitScreen(
        projectId: state.uri.queryParameters['projectId'] ?? '',
        project: state.extra,
      ),
    ),
    GoRoute(
      path: '/investor/booking/payment-plan',
      builder: (context, state) => PaymentPlanScreen(
        projectId: state.uri.queryParameters['projectId'] ?? '',
        project: state.extra,
      ),
    ),
    GoRoute(
      path: '/investor/booking/token-payment',
      builder: (context, state) => TokenPaymentScreen(
        projectId: state.uri.queryParameters['projectId'] ?? '',
        project: state.extra,
      ),
    ),
    GoRoute(
      path: '/investor/booking/confirmation',
      builder: (context, state) => BookingConfirmationScreen(
        projectId: state.uri.queryParameters['projectId'] ?? '',
        project: state.extra,
        bookingId: state.uri.queryParameters['bookingId'],
        amount: state.uri.queryParameters['amount'],
      ),
    ),
    GoRoute(
      path: '/investor/booking/my-bookings',
      builder: (context, state) => const MyPropertyScreen(),
    ),
    GoRoute(
      path: '/cp/tax-reports',
      builder: (context, state) => const CpTaxReportsScreen(),
    ),
    GoRoute(path: '/cp/hub', builder: (context, state) => const CpHubScreen()),
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
      builder: (context, state) => const ContactScreen(),
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
      path: '/guest/profile',
      builder: (context, state) => const GuestProfileScreen(),
    ),
    GoRoute(
      path: '/profile/family',
      builder: (context, state) => const FamilyMembersScreen(),
    ),
    GoRoute(
      path: '/profile/app-settings',
      builder: (context, state) => const AppSettingsScreen(),
    ),
    GoRoute(
      path: '/profile/portfolio',
      builder: (context, state) => const PortfolioScreen(),
    ),
    GoRoute(
      path: '/support/tickets/:id',
      builder: (context, state) => TicketDetailScreen(
        ticketId: state.pathParameters['id']!,
        initialTicket: state.extra as Map<String, dynamic>?,
      ),
    ),
    GoRoute(path: '/search', builder: (context, state) => const SearchScreen()),
    GoRoute(
      path: '/projects/premium-upsell',
      builder: (context, state) => const PremiumUpsellScreen(),
    ),
    GoRoute(
      path: '/projects/premium-checkout',
      builder: (context, state) => const PremiumCheckoutScreen(),
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
    GoRoute(path: '/support', builder: (context, state) => SupportScreen()),
    GoRoute(
      path: '/support/contact',
      builder: (context, state) => const ContactScreen(),
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
    GoRoute(path: '/about', builder: (context, state) => const AboutScreen()),
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
      path: '/communities/:slug/projects',
      builder: (context, state) =>
          CommunityProjectsListScreen(slug: state.pathParameters['slug']!),
    ),
    GoRoute(
      path: '/guest/privacy-policy',
      builder: (context, state) =>
          const PageDetailScreen(slug: 'privacy-policy'),
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
    // Matches the onboarding splash (black bg + white M4 logo) so the brief
    // hand-off from onboarding to this screen (while the session resolves) is
    // seamless with no color flash.
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/m4_family_logo.png',
              width: 200,
              fit: BoxFit.contain,
              color: Colors.white,
            ).animate().fadeIn(duration: 400.ms, curve: Curves.easeOut),
            const SizedBox(height: 32),
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                color: Colors.white24,
                strokeWidth: 2,
              ),
            ),
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
    final bootstrapped = ref.watch(authProvider.select((s) => s.bootstrapped));

    // Cold start: show the splash (not the guest shell) until the stored
    // session resolves, then route straight to the correct portal.
    if (!bootstrapped) return const SplashScreen();

    if (status == AuthStatus.authenticated) {
      final role = user?['role']?.toString().toLowerCase();
      if (role == 'cp') {
        return const CpMainShell();
      }
      if (role == 'investor') {
        return const InvestorMainShell();
      }
      return const MainShell();
    }

    return const GuestMainShell();
  }
}
