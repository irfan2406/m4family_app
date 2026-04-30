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

// State for Selected Project ID
final customViewsProjectProvider = StateProvider<String?>((ref) => null);

// State for Selected Unit Configuration
final customViewsUnitProvider = StateProvider<String>((ref) => '3 BHK');

// State for Selections (Key = Category ID or 'space', Value = Selected Option object)
final customViewsSelectionsProvider = StateProvider<Map<String, dynamic>>((ref) => {});

// State for Booking ID (if alloted)
final customViewsBookingIdProvider = StateProvider<String?>((ref) => null);

// State for Unit Number
final customViewsUnitNumberProvider = StateProvider<String?>((ref) => null);

// State for Edit Mode
final customViewsEditModeProvider = StateProvider<bool>((ref) => false);

