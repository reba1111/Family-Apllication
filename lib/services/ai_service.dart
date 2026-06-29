import 'package:google_generative_ai/google_generative_ai.dart';
import '../core/secrets.dart';

/// Result from the AI service.
class AiResult {
  final String giftIdeas;
  final String dateIdeas;
  AiResult({required this.giftIdeas, required this.dateIdeas});
}

class AiService {
  static final AiService _instance = AiService._();
  factory AiService() => _instance;
  AiService._();

  /// Strips any token that looks like a personal identifier:
  /// - Firestore document IDs (long alphanumeric strings)
  /// - Email addresses
  /// - Phone numbers
  /// - Anything that is purely numeric and long
  static List<String> _sanitize(List<String> items) {
    final _idPattern = RegExp(r'^[a-zA-Z0-9]{20,}$');
    final _emailPattern = RegExp(r'[\w.]+@[\w.]+\.\w+');
    final _phonePattern = RegExp(r'\b\d{7,}\b');

    return items
        .where((s) => s.trim().isNotEmpty)
        .map((s) => s.trim())
        .where((s) =>
            !_idPattern.hasMatch(s) &&
            !_emailPattern.hasMatch(s) &&
            !_phonePattern.hasMatch(s))
        .toList();
  }

  /// Builds a privacy-safe prompt — zero personal identifiers.
  static String _buildPrompt({
    required List<String> likes,
    required List<String> dislikes,
  }) {
    final safeLikes = _sanitize(likes);
    final safeDislikes = _sanitize(dislikes);

    final likesPart = safeLikes.isEmpty
        ? '(هیچ نەزیادکراوە)'
        : safeLikes.join('، ');
    final dislikesPart = safeDislikes.isEmpty
        ? '(هیچ نەزیادکراوە)'
        : safeDislikes.join('، ');

    return '''
تۆ یاریدەدەری کوپڵەکانی. ئەرکەکەت پێشنیارکردنی دیاری و ئاکتیڤیتی ڕۆمانتیکی بۆ کوپڵەکانە.

یادداشتی پارێزگاری: ئەم داواکارییە هیچ زانیارییەکی کەسی تێدا نییە. تەنها لیستی گەنەرالی حەز و ناحەزەکان نێردراوە. تکایە زانیارییەکان پاشەکەوت مەکە.

حەزەکانی هاوسەر: $likesPart
ناحەزەکانی هاوسەر: $dislikesPart

تکایە پێشنیارەکانت بە زمانی کوردی سۆرانی بنووسە و بە ئەم شێوازە:

🎁 پێشنیاری دیاری:
١. ...
٢. ...
٣. ...
٤. ...
٥. ...

🌙 ئێوارەی ڕۆمانتیک:
١. ...
٢. ...
٣. ...
٤. ...
٥. ...

تەنها پێنج پێشنیار بۆ هەر بەشێک بنووسە. کورت و کار بێت.
''';
  }

  /// Returns [AiResult] with gift ideas and date night ideas.
  /// Throws [AiException] on API or key errors.
  Future<AiResult> getSuggestions({
    required List<String> partnerLikes,
    required List<String> partnerDislikes,
  }) async {
    if (kGeminiApiKey == 'YOUR_GEMINI_API_KEY_HERE' ||
        kGeminiApiKey.trim().isEmpty) {
      throw AiException(
          'API key دانەنراوە. تکایە secrets.dart بگشێ و کلیدەکەت تێبدە.');
    }

    final model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: kGeminiApiKey,
      generationConfig: GenerationConfig(
        temperature: 0.8,
        maxOutputTokens: 600,
      ),
    );

    final prompt = _buildPrompt(
      likes: partnerLikes,
      dislikes: partnerDislikes,
    );

    final response =
        await model.generateContent([Content.text(prompt)]);
    final text = response.text ?? '';

    if (text.isEmpty) {
      throw AiException('وەڵامی بەتاڵ لە Gemini.');
    }

    return _parseResponse(text);
  }

  /// Splits the raw Gemini response into two sections.
  static AiResult _parseResponse(String raw) {
    const giftMarker = '🎁';
    const dateMarker = '🌙';

    final giftIdx = raw.indexOf(giftMarker);
    final dateIdx = raw.indexOf(dateMarker);

    if (giftIdx == -1 || dateIdx == -1) {
      // If markers not found, return the whole text as gifts
      return AiResult(giftIdeas: raw.trim(), dateIdeas: '');
    }

    final giftSection = raw
        .substring(giftIdx, dateIdx)
        .replaceFirst('🎁 پێشنیاری دیاری:', '')
        .trim();

    final dateSection = raw
        .substring(dateIdx)
        .replaceFirst('🌙 ئێوارەی ڕۆمانتیک:', '')
        .trim();

    return AiResult(giftIdeas: giftSection, dateIdeas: dateSection);
  }
}

class AiException implements Exception {
  final String message;
  const AiException(this.message);

  @override
  String toString() => message;
}
