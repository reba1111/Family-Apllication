import 'package:google_generative_ai/google_generative_ai.dart';
import '../core/secrets.dart';

class AiResult {
  final String giftIdeas;
  final String dateIdeas;
  final String conversationIdeas;
  final String entertainmentIdeas;

  AiResult({
    required this.giftIdeas,
    required this.dateIdeas,
    required this.conversationIdeas,
    required this.entertainmentIdeas,
  });
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
  static Map<String, List<String>> _sanitize(Map<String, List<String>> items) {
    final _idPattern = RegExp(r'^[a-zA-Z0-9]{20,}$');
    final _emailPattern = RegExp(r'[\w.]+@[\w.]+\.\w+');
    final _phonePattern = RegExp(r'\b\d{7,}\b');

    final sanitized = <String, List<String>>{};
    for (final entry in items.entries) {
      final safeList = entry.value
          .where((s) => s.trim().isNotEmpty)
          .map((s) => s.trim())
          .where((s) =>
              !_idPattern.hasMatch(s) &&
              !_emailPattern.hasMatch(s) &&
              !_phonePattern.hasMatch(s))
          .toList();
      if (safeList.isNotEmpty) {
        sanitized[entry.key] = safeList;
      }
    }
    return sanitized;
  }

  /// Builds a privacy-safe prompt — zero personal identifiers.
  static String _buildPrompt({
    required Map<String, List<String>> likes,
    required Map<String, List<String>> dislikes,
    String? partnerMood,
  }) {
    final safeLikes = _sanitize(likes);
    final safeDislikes = _sanitize(dislikes);

    String formatMap(Map<String, List<String>> map) {
      if (map.isEmpty) return '(هیچ نەزیادکراوە)';
      return map.entries.map((e) => '[${e.key}]: ${e.value.join('، ')}').join('\n');
    }

    final likesPart = formatMap(safeLikes);
    final dislikesPart = formatMap(safeDislikes);
    final moodPart = partnerMood != null ? '\nباری دەروونی ئەمڕۆی هاوسەرەکە: $partnerMood (تکایە پێشنیارەکانت گونجاو بکە بۆ ئەوەی دڵخۆشی بکەیت یان بەپێی ئەم باری دەروونییە بێت)' : '';

    return '''
تۆ یاریدەدەری کوپڵەکانی. ئەرکەکەت پێشنیارکردنی دیاری و ئاکتیڤیتی و کات بەسەربردنە بۆ کوپڵەکان لەسەر بنەمای حەز و ناحەزەکانیان.

یادداشتی پارێزگاری: ئەم داواکارییە هیچ زانیارییەکی کەسی تێدا نییە. تەنها لیستی حەز و ناحەزەکان نێردراوە. تکایە زانیارییەکان پاشەکەوت مەکە.$moodPart

حەزەکانی هاوسەر:
$likesPart

ناحەزەکانی هاوسەر:
$dislikesPart

تکایە پێشنیارەکانت بە زمانی کوردی سۆرانی بنووسە. 
**زۆر گرنگ:** پێویستە هەموو پێشنیارەکانت ڕاستەوخۆ و بەتەواوی پەیوەندییان بەو "حەزانەی" سەرەوە هەبێت، وە بەتوندی خۆت بپارێزە لەو شتانەی لە "ناحەزەکان"دا هاتوون. شتی گشتی پێشنیار مەکە، بەڵکو زۆر تایبەتی بکە بەپێی داتاکانی سەرەوە.

بەم شێوازەی خوارەوە وەڵام بدەوە:

🎁 دیارییە پێشنیارکراوەکان:
١. ...
٢. ...
٣. ...

🌙 چالاکی و دەرچوون:
١. ...
٢. ...
٣. ...

💬 بابەتی گفتوگۆ:
١. ...
٢. ...
٣. ...

🎬 فیلم و کات بەسەربردن:
١. ...
٢. ...
٣. ...

تەنها ٣ بۆ ٤ پێشنیار بۆ هەر بەشێک بنووسە. کورت، سەرنجڕاکێش، و گونجاو بن.
''';
  }

  /// Returns [AiResult] with gift ideas and date night ideas.
  /// Throws [AiException] on API or key errors.
  Future<AiResult> getSuggestions({
    required Map<String, List<String>> partnerLikes,
    required Map<String, List<String>> partnerDislikes,
    String? partnerMood,
    String modelName = 'gemini-2.5-flash',
  }) async {
    if (kGeminiApiKey == 'YOUR_GEMINI_API_KEY_HERE' ||
        kGeminiApiKey.trim().isEmpty) {
      throw AiException(
          'API key دانەنراوە. تکایە secrets.dart بگشێ و کلیدەکەت تێبدە.');
    }

    final model = GenerativeModel(
      model: modelName,
      apiKey: kGeminiApiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        maxOutputTokens: 2500,
      ),
    );

    final prompt = _buildPrompt(
      likes: partnerLikes,
      dislikes: partnerDislikes,
      partnerMood: partnerMood,
    );

    try {
      final response = await model
          .generateContent([Content.text(prompt)])
          .timeout(const Duration(seconds: 120), onTimeout: () {
        throw AiException(
            'کاتی وەڵامدانەوەی سەرڤەرەکە تەواو بوو (Timeout). مۆدێلەکە زۆر کاتی برد، تکایە ئینتەرنێتەکەت بپشکنە و دووبارە هەوڵ بدەرەوە یان مۆدێلێکی تر هەڵبژێرە.');
      });
      final text = response.text ?? '';

      if (text.isEmpty) {
        throw AiException('وەڵامی بەتاڵ لە Gemini.');
      }

      return _parseResponse(text);
    } catch (e) {
      if (e.toString().contains('API key not valid') || e.toString().contains('400')) {
        throw AiException('API Keyـەکەت هەڵەیە. تکایە دڵنیابە لە فایلەی secrets.dart دانراوە و ڕاستە.');
      }
      rethrow;
    }
  }

  static AiResult _parseResponse(String raw) {
    String gifts = '';
    String dates = '';
    String convos = '';
    String entertainment = '';

    final parts = raw.split(RegExp(r'(?=🎁|🌙|💬|🎬)'));
    for (var part in parts) {
      if (part.startsWith('🎁')) {
        gifts = part.replaceFirst(RegExp(r'^🎁[^\n]*\n?'), '').trim();
      } else if (part.startsWith('🌙')) {
        dates = part.replaceFirst(RegExp(r'^🌙[^\n]*\n?'), '').trim();
      } else if (part.startsWith('💬')) {
        convos = part.replaceFirst(RegExp(r'^💬[^\n]*\n?'), '').trim();
      } else if (part.startsWith('🎬')) {
        entertainment = part.replaceFirst(RegExp(r'^🎬[^\n]*\n?'), '').trim();
      }
    }

    if (gifts.isEmpty && dates.isEmpty && convos.isEmpty && entertainment.isEmpty) {
      gifts = raw.trim();
    }

    return AiResult(
      giftIdeas: gifts,
      dateIdeas: dates,
      conversationIdeas: convos,
      entertainmentIdeas: entertainment,
    );
  }
}

class AiException implements Exception {
  final String message;
  const AiException(this.message);

  @override
  String toString() => message;
}
