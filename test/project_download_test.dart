import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:m4_mobile/core/network/api_client.dart';

/// Customer project detail > OVERVIEW > the resource cards' DOWNLOAD button.
///
/// It used to call launchUrl(externalApplication). The API serves these as
/// `Content-Type: application/pdf` with no `Content-Disposition`, so a browser
/// rendered the PDF inline instead of saving it.
///
/// On Android the URL now goes to the system DownloadManager, so the file lands
/// in the phone's Downloads folder with its own notification. These tests cover
/// the parts shared with that path — resolving a relative /uploads path into the
/// URL handed over — plus the iOS fallback, which still fetches through Dio.
///
/// The screen itself embeds a WebView (the location map), which has no
/// platform implementation under `flutter test`, so it cannot be pumped here.
/// What is pinned instead is the machinery the button depends on: that a
/// relative `/uploads/...` path resolves to the API host, and that the app's
/// configured Dio — auth interceptor and logger included — really does stream
/// a file to disk.
final _pdfBytes = Uint8List.fromList('%PDF-1.4\n%%EOF\n'.codeUnits);

class _PdfAdapter implements HttpClientAdapter {
  final List<String> requested = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requested.add(options.uri.toString());
    return ResponseBody.fromBytes(
      _pdfBytes,
      200,
      headers: {
        Headers.contentTypeHeader: ['application/pdf'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('m4_dl_test');
    addTearDown(() {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });
    // The auth interceptor reads the stored token on every request.
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (call) async => null,
    );
  });

  test('a relative /uploads path resolves to the API host', () {
    final api = ApiClient(baseUrl: 'https://api.example.test');
    final resolved = api.resolveUrl(
      '/uploads/media/med-1788420345989-820150170.pdf',
    );

    expect(resolved, startsWith('https://api.example.test'));
    expect(resolved, endsWith('med-1788420345989-820150170.pdf'));
  });

  test('an absolute URL is left alone', () {
    final api = ApiClient(baseUrl: 'https://api.example.test');
    const absolute = 'https://cdn.example.test/a.pdf';
    expect(api.resolveUrl(absolute), absolute);
  });

  test('the configured Dio streams the file to disk', () async {
    final api = ApiClient(baseUrl: 'https://api.example.test');
    final adapter = _PdfAdapter();
    api.dio.httpClientAdapter = adapter;

    final dir = Directory('${tempDir.path}/M4 Family');
    await dir.create(recursive: true);
    final target = File('${dir.path}/typical.pdf');

    final url = api.resolveUrl(
      '/uploads/media/med-1788420345989-820150170.pdf',
    );
    await api.dio.download(url, target.path);

    // It asked for the resolved URL...
    expect(adapter.requested, hasLength(1));
    expect(adapter.requested.single, contains('med-1788420345989'));
    // ...and the bytes are on disk, intact.
    expect(target.existsSync(), isTrue);
    expect(target.readAsBytesSync(), _pdfBytes);
  });

  test('the folder is created when it does not exist yet', () async {
    final api = ApiClient(baseUrl: 'https://api.example.test');
    api.dio.httpClientAdapter = _PdfAdapter();

    // Exactly what the screen does before saving: a named folder under the
    // directory path_provider hands back.
    final dir = Directory('${tempDir.path}/M4 Family');
    expect(dir.existsSync(), isFalse);
    if (!await dir.exists()) await dir.create(recursive: true);
    expect(dir.existsSync(), isTrue);

    final target = File('${dir.path}/Individual Floor plans.pdf');
    await api.dio.download(
      api.resolveUrl('/uploads/media/med-1788420475638-470474537.pdf'),
      target.path,
    );

    expect(target.existsSync(), isTrue);
    expect(target.lengthSync(), _pdfBytes.length);
  });

  test('a failed download surfaces as an error, leaving no partial file', () async {
    final api = ApiClient(baseUrl: 'https://api.example.test');
    api.dio.httpClientAdapter = _FailingAdapter();

    final dir = Directory('${tempDir.path}/M4 Family');
    await dir.create(recursive: true);
    final target = File('${dir.path}/missing.pdf');

    await expectLater(
      api.dio.download(api.resolveUrl('/uploads/media/nope.pdf'), target.path),
      throwsA(isA<DioException>()),
    );
    expect(target.existsSync(), isFalse);
  });
}

class _FailingAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromBytes(Uint8List(0), 404);

  @override
  void close({bool force = false}) {}
}
