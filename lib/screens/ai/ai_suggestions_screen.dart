import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/user_model.dart';
import '../../services/ai_service.dart';
import '../../services/firestore_service.dart';

class AiSuggestionsScreen extends StatefulWidget {
  final UserModel me;

  const AiSuggestionsScreen({super.key, required this.me});

  @override
  State<AiSuggestionsScreen> createState() => _AiSuggestionsScreenState();
}

class _AiSuggestionsScreenState extends State<AiSuggestionsScreen> {
  final _ai = AiService();
  final _fs = FirestoreService();

  bool _loading = false;
  AiResult? _result;
  String? _error;
  UserModel? _partner;

  @override
  void initState() {
    super.initState();
    _loadPartner();
  }

  Future<void> _loadPartner() async {
    if (widget.me.partnerId == null) return;
    final p = await _fs.getUser(widget.me.partnerId!);
    if (mounted) setState(() => _partner = p);
  }

  Future<void> _generate() async {
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });

    try {
      final likes = _partner?.likes ?? [];
      final dislikes = _partner?.dislikes ?? [];

      if (likes.isEmpty && dislikes.isEmpty) {
        setState(() {
          _error =
              'هاوسەرەکەت هێشتا لیستی حەز و ناحەزەکانی تۆمار نەکردووە.\nتکایە یەکەم لیستی ١ "حەز و ناحەزەکان" داخڵ بکە.';
          _loading = false;
        });
        return;
      }

      final result = await _ai.getSuggestions(
        partnerLikes: likes,
        partnerDislikes: dislikes,
      );
      if (mounted) setState(() => _result = result);
    } on AiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'هەڵەیەک ڕووی دا. تکایە دووبارە هەوڵ بدە.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration:
            const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              // AppBar
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 12, 20, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new,
                          color: AppTheme.onSurface),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text('✨', style: TextStyle(fontSize: 22)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('پێشنیاری زیرەک',
                          style: AppTheme.headlineMedium),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Privacy badge
                      _PrivacyBadge(),
                      const SizedBox(height: 20),

                      // Partner info (anonymous preview)
                      if (_partner != null) ...[
                        _AnonymousPreview(partner: _partner!),
                        const SizedBox(height: 20),
                      ],

                      // Generate button
                      _GenerateButton(
                        loading: _loading,
                        hasPartner: widget.me.partnerId != null,
                        onPressed: _generate,
                      ),

                      // Error
                      if (_error != null) ...[
                        const SizedBox(height: 20),
                        _ErrorCard(message: _error!),
                      ],

                      // Results
                      if (_result != null) ...[
                        const SizedBox(height: 24),
                        _ResultSection(
                          emoji: '🎁',
                          title: 'پێشنیاری دیاری',
                          content: _result!.giftIdeas,
                          color: AppTheme.primary,
                        ),
                        if (_result!.dateIdeas.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _ResultSection(
                            emoji: '🌙',
                            title: 'ئێوارەی ڕۆمانتیک',
                            content: _result!.dateIdeas,
                            color: const Color(0xFF9C27B0),
                          ),
                        ],
                        const SizedBox(height: 16),
                        Center(
                          child: TextButton.icon(
                            onPressed: _loading ? null : _generate,
                            icon: const Icon(Icons.refresh,
                                color: AppTheme.primary),
                            label: Text('پێشنیاری تازە',
                                style: TextStyle(color: AppTheme.primary)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _PrivacyBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: AppTheme.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.shield_outlined,
              color: AppTheme.success, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'پارێزگاری: ناو و ID بەخۆکاری سڕاوەتەوە پێش ناردن بۆ AI',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.success,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnonymousPreview extends StatelessWidget {
  final UserModel partner;
  const _AnonymousPreview({required this.partner});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_outline,
                  color: AppTheme.onSurfaceMuted, size: 18),
              const SizedBox(width: 8),
              Text('داتای دەنێردرێت بۆ AI',
                  style: AppTheme.bodyMedium
                      .copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          _PreviewRow(
            label: 'حەزەکانی هاوسەر:',
            items: partner.likes,
            color: AppTheme.primary,
          ),
          if (partner.dislikes.isNotEmpty) ...[
            const SizedBox(height: 8),
            _PreviewRow(
              label: 'ناحەزەکانی هاوسەر:',
              items: partner.dislikes,
              color: AppTheme.error,
            ),
          ],
          const Divider(
              height: 20, color: Color(0xFF2A2A40)),
          Row(
            children: [
              const Icon(Icons.block, size: 14, color: AppTheme.error),
              const SizedBox(width: 6),
              Text(
                'ناو، UID، ئیمەیڵ — هەموو سڕاوەتەوە',
                style: AppTheme.bodyMedium.copyWith(fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  final String label;
  final List<String> items;
  final Color color;

  const _PreviewRow({
    required this.label,
    required this.items,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTheme.bodyMedium.copyWith(fontSize: 12)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: items
              .take(6)
              .map((item) => Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: color.withValues(alpha: 0.3)),
                    ),
                    child: Text(item,
                        style: AppTheme.bodyMedium.copyWith(
                            fontSize: 12, color: color)),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

class _GenerateButton extends StatelessWidget {
  final bool loading;
  final bool hasPartner;
  final VoidCallback onPressed;

  const _GenerateButton({
    required this.loading,
    required this.hasPartner,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (loading || !hasPartner) ? null : onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 60,
        decoration: BoxDecoration(
          gradient: (loading || !hasPartner)
              ? LinearGradient(colors: [
                  AppTheme.onSurfaceMuted.withValues(alpha: 0.3),
                  AppTheme.onSurfaceMuted.withValues(alpha: 0.2),
                ])
              : AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(18),
          boxShadow: loading || !hasPartner
              ? []
              : [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Center(
          child: loading
              ? const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text('Gemini دەپرسێت...',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600)),
                  ],
                )
              : const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('✨', style: TextStyle(fontSize: 20)),
                    SizedBox(width: 10),
                    Text(
                      'پێشنیار وەربگرە',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _ResultSection extends StatelessWidget {
  final String emoji;
  final String title;
  final String content;
  final Color color;

  const _ResultSection({
    required this.emoji,
    required this.title,
    required this.content,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Text(title,
                  style: AppTheme.titleLarge.copyWith(color: color)),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            content,
            style: AppTheme.bodyLarge.copyWith(height: 1.7),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline,
              color: AppTheme.error, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: AppTheme.bodyMedium
                    .copyWith(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }
}
