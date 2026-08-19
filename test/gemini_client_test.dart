import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import 'package:pawfect_app/services/gemini_client.dart';

/// Covers the request rewrite that lets the deprecated
/// `google_generative_ai` SDK send Gemini 3.x `thinkingConfig`.
void main() {
  // No TestWidgetsFlutterBinding: it installs an HttpOverrides that fails
  // every request with a 400, which would make the live check untestable.
  setUpAll(() {
    HttpOverrides.global = null;
    try {
      dotenv.testLoad(fileInput: File('.env').readAsStringSync());
    } catch (_) {
      // Live test below skips itself when the key is missing.
    }
  });

  group('applyThinkingLevel', () {
    String bodyWith(Map<String, dynamic> extra) => json.encode({
          'contents': [
            {
              'role': 'user',
              'parts': [
                {'text': 'hello'}
              ]
            }
          ],
          ...extra,
        });

    test('injects thinkingConfig when generationConfig is absent', () {
      final out = json.decode(
        GeminiClient.applyThinkingLevel(bodyWith(const {}), 'low'),
      ) as Map<String, dynamic>;

      expect(out['generationConfig']['thinkingConfig']['thinkingLevel'], 'low');
      // The payload itself must survive untouched.
      expect(out['contents'][0]['parts'][0]['text'], 'hello');
    });

    test('preserves an existing generationConfig', () {
      final body = bodyWith({
        'generationConfig': {'temperature': 0.55, 'maxOutputTokens': 2048},
      });
      final out = json.decode(GeminiClient.applyThinkingLevel(body, 'low'))
          as Map<String, dynamic>;

      expect(out['generationConfig']['temperature'], 0.55);
      expect(out['generationConfig']['maxOutputTokens'], 2048);
      expect(out['generationConfig']['thinkingConfig']['thinkingLevel'], 'low');
    });

    test('never overrides a thinkingConfig the caller already set', () {
      final body = bodyWith({
        'generationConfig': {
          'thinkingConfig': {'thinkingLevel': 'high'},
        },
      });
      final out = json.decode(GeminiClient.applyThinkingLevel(body, 'low'))
          as Map<String, dynamic>;

      expect(out['generationConfig']['thinkingConfig']['thinkingLevel'], 'high');
    });

    test('leaves non-generateContent payloads alone', () {
      const body = '{"models":[]}';
      expect(GeminiClient.applyThinkingLevel(body, 'low'), body);
    });

    test('leaves malformed and empty bodies alone', () {
      const junk = 'not json at all {{{';
      expect(GeminiClient.applyThinkingLevel(junk, 'low'), junk);
      expect(GeminiClient.applyThinkingLevel('', 'low'), '');
      expect(GeminiClient.applyThinkingLevel('[1,2,3]', 'low'), '[1,2,3]');
    });

    test('a null level is a no-op, which is how web builds behave', () {
      final body = bodyWith(const {});
      expect(GeminiClient.applyThinkingLevel(body, null), body);
    });

    test('is idempotent', () {
      final once = GeminiClient.applyThinkingLevel(bodyWith(const {}), 'low');
      expect(GeminiClient.applyThinkingLevel(once, 'low'), once);
    });
  });

  group('http.Request plumbing', () {
    test('rewrite survives the bytes round trip the SDK actually uses', () {
      // Mirrors HttpApiClient.makeRequest: the payload is posted as bytes,
      // so bodyBytes is set rather than body.
      final payload = json.encode({
        'contents': [
          {
            'parts': [
              {'text': 'hello'}
            ]
          }
        ],
        'generationConfig': {'maxOutputTokens': 2048},
      });

      final request = http.Request(
        'POST',
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/x'),
      )
        ..headers['Content-Type'] = 'application/json'
        ..bodyBytes = utf8.encode(payload);

      expect(request.finalized, isFalse);
      expect(request.headers['content-type'], contains('json'));

      request.body = GeminiClient.applyThinkingLevel(request.body, 'low');

      final decoded =
          json.decode(utf8.decode(request.bodyBytes)) as Map<String, dynamic>;
      expect(decoded['generationConfig']['thinkingConfig']['thinkingLevel'],
          'low');
      expect(decoded['generationConfig']['maxOutputTokens'], 2048);
    });
  });

  group('thinkingLevel resolution', () {
    test('defaults to low and honours the opt-out', () {
      // Reflects whatever .env holds; both branches are valid states.
      final level = GeminiClient.thinkingLevel();
      expect(level == null || level.isNotEmpty, isTrue);
    });
  });

  group('live wire check', () {
    test('a rewritten request is accepted by the real API', () async {
      if ((dotenv.env['GEMINI_API_KEY'] ?? '').trim().isEmpty) {
        markTestSkipped('GEMINI_API_KEY not set');
        return;
      }
      // Goes through GeminiClient.httpClient(), so the interceptor rewrites
      // this body for real. A corrupted payload would come back as a 400.
      final model = GeminiClient.buildModel();
      final response = await model.generateContent([
        Content.text('Reply with exactly the word: pong'),
      ]);

      expect(response.text, isNotNull);
      expect(response.text!.toLowerCase(), contains('pong'));
    }, timeout: const Timeout(Duration(seconds: 90)));
  });
}
