import 'dart:convert';
import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';

/// Shared utilities for running an agent step in an orchestrated AI
/// pipeline. Every agent:
///   1. Builds a focused prompt with explicit role + JSON schema.
///   2. Calls Gemini with that prompt (optionally with vision data).
///   3. Parses a JSON object or array out of the response, surviving
///      code fences, leading prose, and trailing commentary.
///   4. Returns a typed result, or a documented fallback.
///
/// This file holds only the I/O plumbing. Each concrete agent lives in
/// its own file and uses these helpers.
class AgentRunner {
  AgentRunner._();

  /// Run a text-only agent that returns a JSON object.
  static Future<Map<String, dynamic>> runJsonObject({
    required GenerativeModel model,
    required String prompt,
    Map<String, dynamic> fallback = const {},
  }) async {
    try {
      final response = await model.generateContent([Content.text(prompt)]);
      return parseJsonObject(response.text ?? '', fallback: fallback);
    } catch (_) {
      return Map<String, dynamic>.from(fallback);
    }
  }

  /// Run a text-only agent that returns a JSON array.
  static Future<List<dynamic>> runJsonArray({
    required GenerativeModel model,
    required String prompt,
    List<dynamic> fallback = const [],
  }) async {
    try {
      final response = await model.generateContent([Content.text(prompt)]);
      return parseJsonArray(response.text ?? '', fallback: fallback);
    } catch (_) {
      return List<dynamic>.from(fallback);
    }
  }

  /// Run a vision agent that takes raw image bytes + a prompt and
  /// returns a JSON object. The image is sent inline as a `image/jpeg`
  /// data part — Gemini Flash handles common encodings regardless of
  /// the declared MIME for small payloads.
  static Future<Map<String, dynamic>> runVisionJsonObject({
    required GenerativeModel model,
    required String prompt,
    required List<int> imageBytes,
    String mimeType = 'image/jpeg',
    Map<String, dynamic> fallback = const {},
  }) async {
    try {
      final bytes = imageBytes is Uint8List
          ? imageBytes
          : Uint8List.fromList(imageBytes);
      final response = await model.generateContent([
        Content.multi([
          TextPart(prompt),
          DataPart(mimeType, bytes),
        ]),
      ]);
      return parseJsonObject(response.text ?? '', fallback: fallback);
    } catch (_) {
      return Map<String, dynamic>.from(fallback);
    }
  }

  /// Extract the first JSON object from a model response. Survives:
  ///   • ```json fenced blocks
  ///   • bare fenced blocks (```)
  ///   • prose before the object
  ///   • trailing commentary after the object
  /// Returns the [fallback] on any parse failure rather than throwing,
  /// because pipeline stages should degrade gracefully.
  static Map<String, dynamic> parseJsonObject(
    String raw, {
    Map<String, dynamic> fallback = const {},
  }) {
    try {
      var text = raw.trim();
      if (text.contains('```json')) {
        text = text.split('```json').skip(1).join('```json');
        text = text.split('```').first;
      } else if (text.contains('```')) {
        final parts = text.split('```');
        if (parts.length >= 2) text = parts[1];
      }
      final firstBrace = text.indexOf('{');
      final lastBrace = text.lastIndexOf('}');
      if (firstBrace < 0 || lastBrace <= firstBrace) {
        return Map<String, dynamic>.from(fallback);
      }
      text = text.substring(firstBrace, lastBrace + 1);
      final decoded = json.decode(text);
      if (decoded is Map<String, dynamic>) return decoded;
      return Map<String, dynamic>.from(fallback);
    } catch (_) {
      return Map<String, dynamic>.from(fallback);
    }
  }

  /// Extract the first JSON array from a model response. Same survival
  /// rules as [parseJsonObject].
  static List<dynamic> parseJsonArray(
    String raw, {
    List<dynamic> fallback = const [],
  }) {
    try {
      var text = raw.trim();
      if (text.contains('```json')) {
        text = text.split('```json').skip(1).join('```json');
        text = text.split('```').first;
      } else if (text.contains('```')) {
        final parts = text.split('```');
        if (parts.length >= 2) text = parts[1];
      }
      final firstBracket = text.indexOf('[');
      final lastBracket = text.lastIndexOf(']');
      if (firstBracket < 0 || lastBracket <= firstBracket) {
        return List<dynamic>.from(fallback);
      }
      text = text.substring(firstBracket, lastBracket + 1);
      final decoded = json.decode(text);
      if (decoded is List) return decoded;
      return List<dynamic>.from(fallback);
    } catch (_) {
      return List<dynamic>.from(fallback);
    }
  }

}
