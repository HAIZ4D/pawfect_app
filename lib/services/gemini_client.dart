import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;

/// Central factory for Gemini clients.
///
/// The project's Gemini API key is restricted to a set of HTTP
/// referrers (the deployed Firebase Hosting origin). Browsers attach
/// a Referer header automatically, so the web build works out of the
/// box. On Android, iOS, and desktop the platform HTTP stack sends an
/// empty Referer, which trips the restriction and Google returns:
///
///   "Requests from referer (empty) are blocked."
///
/// To keep a single restricted key working everywhere, every non-web
/// request goes through [_RefererClient], a [http.BaseClient] that
/// injects a Referer header matching a registered origin. The default
/// origin is the production web build; override with `GEMINI_REFERER`
/// in `.env` if your key is restricted to a different domain.
///
/// Web build: returns `null` so the underlying browser fetch sets the
/// Referer itself. Browsers reject manual Referer overrides anyway.
class GeminiClient {
  GeminiClient._();

  static const String _defaultReferer = 'https://pawfect-ed0a1.web.app/';

  static http.Client? _shared;

  /// API key loaded from `.env`. Throws [StateError] if missing so
  /// callers fail loud rather than waste a network round trip on an
  /// empty key.
  static String apiKey() {
    final key = dotenv.env['GEMINI_API_KEY']?.trim() ?? '';
    if (key.isEmpty) {
      throw StateError(
        'GEMINI_API_KEY missing from .env. Add the key and reload the app.',
      );
    }
    return key;
  }

  /// Referer string used to bypass the API key's HTTP referrer
  /// restriction on mobile and desktop. Override via `GEMINI_REFERER`
  /// in `.env`.
  static String referer() {
    final override = dotenv.env['GEMINI_REFERER']?.trim();
    if (override != null && override.isNotEmpty) return override;
    return _defaultReferer;
  }

  /// Shared HTTP client for Gemini requests. Reused across services to
  /// avoid spinning up a new TCP pool per call. Returns null on web so
  /// the package falls back to the default fetch-based transport.
  static http.Client? httpClient() {
    if (kIsWeb) return null;
    return _shared ??= _RefererClient(http.Client(), referer());
  }

  /// Convenience constructor that wires the right HTTP client and API
  /// key into a fresh [GenerativeModel]. Pass [generationConfig],
  /// [safetySettings], and [systemInstruction] through unchanged.
  static GenerativeModel buildModel({
    String model = 'gemini-2.5-flash',
    GenerationConfig? generationConfig,
    List<SafetySetting> safetySettings = const [],
    Content? systemInstruction,
  }) {
    return GenerativeModel(
      model: model,
      apiKey: apiKey(),
      generationConfig: generationConfig,
      safetySettings: safetySettings,
      systemInstruction: systemInstruction,
      httpClient: httpClient(),
    );
  }
}

class _RefererClient extends http.BaseClient {
  _RefererClient(this._inner, this._referer);

  final http.Client _inner;
  final String _referer;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Referer'] = _referer;
    return _inner.send(request);
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}
