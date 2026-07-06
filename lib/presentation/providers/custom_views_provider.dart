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
