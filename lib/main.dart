import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m4_mobile/core/theme/app_theme.dart';
import 'package:go_router/go_router.dart';
import 'package:m4_mobile/presentation/screens/auth/login_screen.dart';
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
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:m4_mobile/presentation/screens/about/about_screen.dart';
import 'package:m4_mobile/presentation/screens/communities/community_list_screen.dart';
import 'package:m4_mobile/presentation/screens/projects/project_list_screen.dart';
import 'package:m4_mobile/presentation/screens/careers/careers_screen.dart';
import 'package:m4_mobile/presentation/screens/support/support_screen.dart';

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
        themeProvider.overrideWith((ref) => ThemeNotifier(initialTheme))
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
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const ConditionalHomeShell(),
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
      builder: (context, state) => const SupportScreen(),
    ),
    GoRoute(
      path: '/media',
      builder: (context, state) => const PlaceholderScreen(title: 'Media'),
    ),
    GoRoute(
      path: '/highlights',
      builder: (context, state) => const PlaceholderScreen(title: 'Highlights'),
    ),
    GoRoute(
      path: '/events',
      builder: (context, state) => const PlaceholderScreen(title: 'Events'),
    ),
    GoRoute(
      path: '/blog',
      builder: (context, state) => const PlaceholderScreen(title: 'Blog'),
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
            CircularProgressIndicator(color: M4Theme.premiumBlue),
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
    
    if (status == AuthStatus.authenticated) {
      return const MainShell();
    }
    
    return const GuestMainShell();
  }
}
