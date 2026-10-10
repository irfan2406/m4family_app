/// Turning a link the admin typed into one a browser will actually open.
library;

/// Hosts/paths that are already addressable, i.e. carry their own scheme.
final RegExp _hasScheme = RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*:');

/// Normalises [raw] into a launchable [Uri], or null when there is nothing
/// to open.
///
/// Admin-entered links routinely omit the scheme: SKAI's walkthrough is stored
/// as `youtube.com/watch?...`. `Uri.parse` turns that into a *relative* URI
/// with no scheme, `canLaunchUrl` answers false, and the button fails with an
/// error the user can do nothing about. A bare host or a protocol-relative
/// `//host/path` is therefore promoted to https; anything that already names a
/// scheme — http, https, mailto, tel — is left exactly as it is.
Uri? externalUri(String? raw) {
  final value = (raw ?? '').trim();
  if (value.isEmpty) return null;

  if (_hasScheme.hasMatch(value)) return Uri.tryParse(value);
  if (value.startsWith('//')) return Uri.tryParse('https:$value');

  // A site-relative path ("/360-view") is not an external link; it belongs to
  // the backend and the caller resolves it against the API host instead.
  if (value.startsWith('/')) return null;

  return Uri.tryParse('https://$value');
}

/// Whether [raw] names an external site rather than a path on the backend.
bool isExternalLink(String? raw) => externalUri(raw) != null;
