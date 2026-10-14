import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';

// Provider for fetching Customization Options
final customizationOptionsProvider = FutureProvider<List<dynamic>>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  final response = await apiClient.getCustomizationOptions();
  if (response.statusCode == 200 || response.statusCode == 201) {
    return response.data['data'] ?? [];
  } else {
    throw Exception('Failed to load customization options');
  }
});

/// Admin Panel > Custom Views page copy, read from `GET /api/config`:
/// `customization_hero_title`, `customization_description` and
/// `customization_hero_image` (an `/uploads/...` path, resolved against the
/// API host, which redirects to the media bucket the website uses).
///
/// Empty fields mean "nothing set": the screens then keep their built-in copy
/// and banner rather than showing a blank.
class CustomizationPageContent {
  final String title;
  final String subtitle;
  final String description;
  final String heroImage;
  final String ctaText;
  final String ctaLink;

  /// On/off switches from the Admin Panel. The server's rule is "missing = ON,
  /// `false` or `"false"` = OFF", so each defaults to true.
  final bool isEnabledGlobal;
  final bool allowCpAccess;
  final bool allowInvestorAccess;
  final bool isVisible;

  const CustomizationPageContent({
    this.title = '',
    this.subtitle = '',
    this.description = '',
    this.heroImage = '',
    this.ctaText = '',
    this.ctaLink = '',
    this.isEnabledGlobal = true,
    this.allowCpAccess = true,
    this.allowInvestorAccess = true,
    this.isVisible = true,
  });

  static const empty = CustomizationPageContent();

  /// Whether Custom Views is switched OFF for a user with this (lowercase)
  /// [role]: globally off, or off for that partner/investor account.
  bool closedForRole(String role) {
    if (!isEnabledGlobal) return true;
    if (role == 'cp' && !allowCpAccess) return true;
    if (role == 'investor' && !allowInvestorAccess) return true;
    return false;
  }
}

CustomizationPageContent parseCustomizationPage(
  dynamic payload,
  String Function(String?) resolveUrl,
) {
  final data = payload is Map ? payload['data'] : null;
  if (data is! Map) return CustomizationPageContent.empty;
  String text(String key) => (data[key] ?? '').toString().trim();
  // Server rule: a missing key is ON; a literal false / "false" is OFF.
  bool sw(String key) {
    if (!data.containsKey(key)) return true;
    final v = data[key];
    if (v == false) return false;
    if (v is String && v.trim().toLowerCase() == 'false') return false;
    return true;
  }

  final image = text('customization_hero_image');
  return CustomizationPageContent(
    title: text('customization_hero_title'),
    subtitle: text('customization_hero_subtitle'),
    description: text('customization_description'),
    heroImage: image.isEmpty ? '' : resolveUrl(image),
    ctaText: text('customization_cta_text'),
    ctaLink: text('customization_cta_link'),
    isEnabledGlobal: sw('customization_is_enabled_global'),
    allowCpAccess: sw('customization_allow_cp_access'),
    allowInvestorAccess: sw('customization_allow_investor_access'),
    isVisible: sw('customization_is_visible'),
  );
}

/// True when Custom Views is switched off for the signed-in user's role.
///
/// Drives hiding the Custom Views menu item and showing the "not available"
/// state. Defaults to OPEN while the config is still loading or if it fails,
/// so a network blip never locks anyone out — the server's 403 is the backstop.
final customViewsClosedProvider = Provider<bool>((ref) {
  final page =
      ref.watch(customizationPageProvider).valueOrNull ??
      CustomizationPageContent.empty;
  final role = (ref.watch(authProvider).user?['role'] ?? '')
      .toString()
      .toLowerCase();
  return page.closedForRole(role);
});

final customizationPageProvider = FutureProvider<CustomizationPageContent>((
  ref,
) async {
  final apiClient = ref.watch(apiClientProvider);
  try {
    final response = await apiClient.getPublicConfig();
    return parseCustomizationPage(response.data, apiClient.resolveUrl);
  } catch (_) {
    return CustomizationPageContent.empty;
  }
});

/// Re-reads everything the Custom Views screens show from the server: the page
/// copy, the categories with their finish options, and the project/unit setup.
///
/// The backend asks for a fresh load on every open (most options carry no
/// `updatedAt`, so there is nothing reliable to cache against). Without this
/// the providers kept the first copy for the whole session, so Admin Panel
/// edits never reached an open app. The returned future completes once the
/// new data is in, for pull-to-refresh.
Future<void> reloadCustomViewsData(WidgetRef ref) async {
  ref.invalidate(customizationPageProvider);
  ref.invalidate(customizationOptionsProvider);
  ref.invalidate(customViewsConfigProvider);
  try {
    await Future.wait([
      ref.read(customizationPageProvider.future),
      ref.read(customizationOptionsProvider.future),
      ref.read(customViewsConfigProvider.future),
    ]);
  } catch (_) {
    // A failed reload leaves each screen on its own error/fallback state.
  }
}

// State for Tracking Wizard Steps (0 to 3)
final customViewsStepProvider = StateProvider<int>((ref) => 0);

// Web parity: fetch the project/unit-specific config (spaces + per-space options).
// Returns null when no specific config exists (frontend falls back to defaults).
final customViewsConfigProvider = FutureProvider<Map<String, dynamic>?>((
  ref,
) async {
  final projectId = ref.watch(customViewsProjectProvider);
  final unit = ref.watch(customViewsUnitProvider);
  if (projectId == null || projectId.isEmpty) return null;
  final apiClient = ref.watch(apiClientProvider);
  try {
    final response = await apiClient.getCustomViewsConfig(projectId, unit);
    final data = response.data;
    if (response.statusCode == 200 &&
        data['status'] == true &&
        data['data'] != null &&
        data['data']['categories'] != null) {
      return Map<String, dynamic>.from(data['data']);
    }
  } catch (_) {
    // Fall back to defaults on any error.
  }
  return null;
});

// State for Selected Project ID
final customViewsProjectProvider = StateProvider<String?>((ref) => null);

// State for Selected Unit Configuration
final customViewsUnitProvider = StateProvider<String>((ref) => '3 BHK');

// State for Selections (Key = Category ID or 'space', Value = Selected Option object)
final customViewsSelectionsProvider = StateProvider<Map<String, dynamic>>(
  (ref) => {},
);

// State for Booking ID (if alloted)
final customViewsBookingIdProvider = StateProvider<String?>((ref) => null);

// State for Unit Number
final customViewsUnitNumberProvider = StateProvider<String?>((ref) => null);

// State for Block / Tower (web parity)
final customViewsBlockProvider = StateProvider<String?>((ref) => null);

// State for Wing (web parity)
final customViewsWingProvider = StateProvider<String?>((ref) => null);

// State for the active space tab in the materials step (web parity)
final customViewsActiveSpaceProvider = StateProvider<String?>((ref) => null);

// State for Edit Mode
final customViewsEditModeProvider = StateProvider<bool>((ref) => false);
