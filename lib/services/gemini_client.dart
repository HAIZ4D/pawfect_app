import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
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

  /// Default reasoning depth for Gemini 3.x. Override with
  /// `GEMINI_THINKING_LEVEL` in `.env`; set it to `default` to hand the
  /// decision back to the model.
  static const String _defaultThinkingLevel = 'low';

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

  /// Reasoning depth sent with every generateContent call.
  ///
  /// Gemini 3.x bills thinking tokens as output and spends them from the
  /// same `maxOutputTokens` budget as the answer. Left on its default the
  /// model routinely burns 800 to 1000 tokens thinking, which both costs
  /// more and starves long structured replies until they truncate.
  /// Measured on the dermatology vision prompt: `low` returned identical
  /// conclusions using 717 total tokens against 1320 on the default.
  ///
  /// Returns null when the level is `default`, which skips injection.
  static String? thinkingLevel() {
    final raw = dotenv.env['GEMINI_THINKING_LEVEL']?.trim().toLowerCase();
    final level = (raw == null || raw.isEmpty) ? _defaultThinkingLevel : raw;
    if (level == 'default' || level == 'off') return null;
    return level;
  }

  /// Insert `thinkingConfig.thinkingLevel` into an encoded
  /// generateContent body.
  ///
  /// Pure and total: returns [body] unchanged for anything it does not
  /// recognise, so a surprise payload can never break a request. Split
  /// out from the interceptor so it can be tested without a socket.
  @visibleForTesting
  static String applyThinkingLevel(String body, String? level) {
    if (level == null || body.isEmpty) return body;
    try {
      final decoded = json.decode(body);
      if (decoded is! Map<String, dynamic>) return body;
      // Only generateContent payloads carry `contents`.
      if (!decoded.containsKey('contents')) return body;

      final config = decoded['generationConfig'];
      final Map<String, dynamic> generationConfig =
          config is Map<String, dynamic> ? config : <String, dynamic>{};
      // Never override a level someone set deliberately.
      if (generationConfig.containsKey('thinkingConfig')) return body;

      generationConfig['thinkingConfig'] = {'thinkingLevel': level};
      decoded['generationConfig'] = generationConfig;
      return json.encode(decoded);
    } catch (_) {
      return body;
    }
  }

  /// Shared HTTP client for Gemini requests. Reused across services to
  /// avoid spinning up a new TCP pool per call. Returns null on web so
  /// the package falls back to the default fetch-based transport.
  ///
  /// Note the asymmetry: on web this returns null, so [_GeminiClient]'s
  /// body rewrite does not run and web builds keep the model's default
  /// reasoning depth. That costs more per call but never breaks a scan.
  static http.Client? httpClient() {
    if (kIsWeb) return null;
    return _shared ??= _GeminiClient(http.Client(), referer(), thinkingLevel());
  }

  /// Convenience constructor that wires the right HTTP client and API
  /// key into a fresh [GenerativeModel]. Pass [generationConfig],
  /// [safetySettings], and [systemInstruction] through unchanged.
  static GenerativeModel buildModel({
    String model = 'gemini-3.7-flash',
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

/// Request interceptor for every non-web Gemini call.
///
/// Does two jobs the `google_generative_ai` package cannot do itself:
///
///  1. Injects a Referer header, so one referrer-restricted API key
///     works on Android, iOS, and desktop as well as on web.
///  2. Injects `generationConfig.thinkingConfig.thinkingLevel`. The
///     package is deprecated and its typed `GenerationConfig` predates
///     Gemini 3, so there is no field for this. Rewriting the encoded
///     body is the only way to reach it without swapping SDKs.
///
/// The rewrite is deliberately timid. Anything unexpected (a non-JSON
/// body, a payload that is not a generateContent call, a config the
/// caller already set) leaves the request exactly as it arrived.
class _GeminiClient extends http.BaseClient {
  _GeminiClient(this._inner, this._referer, this._thinkingLevel);

  final http.Client _inner;
  final String _referer;
  final String? _thinkingLevel;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Referer'] = _referer;
    _applyThinkingLevel(request);
    return _inner.send(request);
  }

  /// Rewrite an outgoing generateContent body to carry the thinking
  /// level.
  ///
  /// The SDK posts the payload as bytes through [http.BaseClient.post],
  /// so the request arriving here is an unfinalized [http.Request] whose
  /// `body` getter decodes those bytes. Assigning `body` re-encodes them
  /// and appends `charset=utf-8` to the content type, which the API
  /// accepts. Silent by design: a failure degrades to an unmodified
  /// request, never to a broken scan.
  void _applyThinkingLevel(http.BaseRequest request) {
    if (_thinkingLevel == null) return;
    if (request is! http.Request) return;
    if (request.finalized) return;

    try {
      final contentType = request.headers['content-type'] ?? '';
      if (!contentType.contains('json')) return;

      final original = request.body;
      final rewritten =
          GeminiClient.applyThinkingLevel(original, _thinkingLevel);
      if (!identical(rewritten, original) && rewritten != original) {
        request.body = rewritten;
      }
    } catch (_) {
      // Leave the request untouched.
    }
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}
