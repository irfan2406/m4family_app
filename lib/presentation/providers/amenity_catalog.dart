import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m4_mobile/core/network/api_client.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:m4_mobile/presentation/providers/live_sync_provider.dart';
import 'package:m4_mobile/presentation/widgets/luxury_amenity_icon.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Every amenity the backend knows (`/api/catalog/amenities`), by id.
///
/// The projects LIST sends a project's amenities as bare ids
/// (`"6a9a75ff6916b80947fba11d"`); only the project DETAILS request sends them
/// as `{name, icon, …}`. A project page opens on the list's copy, so until its
/// details arrived the Amenities grid had only ids — no names, no icons — and
/// drew stand-in glyphs that then turned into the real icons. With this
/// catalogue the ids resolve at once, and the grid's very first frame shows the
/// real icons (already downloaded and decoded, see [AmenityCatalogScope]).
class AmenityCatalog {
  AmenityCatalog._();

  static final Map<String, Map<String, dynamic>> _byId = {};
  static const _prefsKey = 'amenity_catalog_v1';

  static final _idPattern = RegExp(r'^[0-9a-fA-F]{24}$');

  /// A Mongo id rather than an amenity name.
  static bool isId(dynamic v) => v is String && _idPattern.hasMatch(v.trim());

  /// The amenity for [id], or null when the catalogue does not know it (yet).
  static Map<String, dynamic>? byId(String id) => _byId[id.trim()];

  /// Adds full amenity records seen elsewhere (a project's details) so later
  /// pages resolve them too.
  static void remember(Iterable<dynamic>? amenities) {
    for (final a in amenities ?? const []) {
      if (a is Map && a['_id'] != null) {
        _byId[a['_id'].toString()] = Map<String, dynamic>.from(a);
      }
    }
  }

  /// [raw] with every id swapped for its full amenity record. Records and
  /// plain names pass through; an id the catalogue does not know yet is left
  /// out, so the grid never shows a raw id or a stand-in glyph for it.
  static List<dynamic> resolve(List<dynamic>? raw) => [
    for (final a in raw ?? const [])
      if (a is Map)
        a
      else if (isId(a))
        ?_byId[(a as String).trim()]
      else if (a != null && a.toString().trim().isNotEmpty)
        a,
  ];

  /// Whether [raw] still holds ids the catalogue cannot resolve — the grid is
  /// then waiting for the project's details rather than truly empty.
  static bool hasUnresolved(List<dynamic>? raw) =>
      (raw ?? const []).any((a) => isId(a) && !_byId.containsKey(a.trim()));

  /// Every known amenity icon, made absolute.
  static List<String> iconUrls(ApiClient api) => [
    for (final a in _byId.values)
      if (amenityIconUrl(a) case final icon?) api.resolveUrl(icon),
  ];

  /// The saved copy from the last run — instant, before any network.
  static Future<void> loadSaved() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefsKey);
      if (saved == null) return;
      final list = jsonDecode(saved);
      if (list is List) remember(list);
    } catch (_) {}
  }

  /// The current catalogue from the server, saved for the next launch.
  static Future<void> refresh(ApiClient api) async {
    try {
      final res = await api.dio.get('/api/catalog/amenities');
      final body = res.data;
      final list = body is Map ? body['data'] : body;
      if (list is! List) return;
      remember(list);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, jsonEncode(list));
    } catch (_) {}
  }
}

/// Loads [AmenityCatalog] when the app starts (saved copy first, then the
/// server) and downloads + decodes every amenity icon into memory, so a
/// project's Amenities grid draws its real icons in its first frame. It
/// reloads when the admin edits amenities (live sync).
class AmenityCatalogScope extends ConsumerStatefulWidget {
  const AmenityCatalogScope({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AmenityCatalogScope> createState() =>
      _AmenityCatalogScopeState();
}

class _AmenityCatalogScopeState extends ConsumerState<AmenityCatalogScope> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _warm());
  }

  Future<void> _warm() async {
    final api = ref.read(apiClientProvider);
    await AmenityCatalog.loadSaved();
    _precache(api);
    await AmenityCatalog.refresh(api);
    _precache(api);
  }

  void _precache(ApiClient api) {
    if (!mounted) return;
    precacheAmenityIcons(context, AmenityCatalog.iconUrls(api));
  }

  @override
  Widget build(BuildContext context) {
    listenForAdminChanges(ref, const {SyncTopic.amenities}, () async {
      final api = ref.read(apiClientProvider);
      await AmenityCatalog.refresh(api);
      _precache(api);
    });
    return widget.child;
  }
}
