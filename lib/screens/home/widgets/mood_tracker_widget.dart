import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../models/user_model.dart';
import '../../../services/firestore_service.dart';
import '../../ai/ai_suggestions_screen.dart';

class MoodTrackerWidget extends StatelessWidget {
  final String currentUserId;
  final String? partnerId;

  const MoodTrackerWidget({
    super.key,
    required this.currentUserId,
    this.partnerId,
  });

  @override
  Widget build(BuildContext context) {
    final fs = FirestoreService();

    return StreamBuilder<UserModel?>(
      stream: fs.streamUser(currentUserId),
      builder: (context, userSnap) {
        if (!userSnap.hasData) return const SizedBox();
        final me = userSnap.data!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('باری دەروونی ئەمڕۆ', style: AppTheme.headlineMedium),
            const SizedBox(height: 12),
            _MyMoodSelector(uid: currentUserId, currentMood: me.currentMood),
            const SizedBox(height: 16),
            if (partnerId != null)
              StreamBuilder<UserModel?>(
                stream: fs.streamUser(partnerId!),
                builder: (context, partnerSnap) {
                  if (!partnerSnap.hasData) return const SizedBox();
                  final partner = partnerSnap.data!;
                  return _PartnerMoodCard(
                    partnerName: partner.displayName,
                    partnerMood: partner.currentMood,
                    me: me,
                  );
                },
              ),
          ],
        );
      },
    );
  }
}

class _MyMoodSelector extends StatelessWidget {
  final String uid;
  final String? currentMood;

  const _MyMoodSelector({required this.uid, this.currentMood});

  @override
  Widget build(BuildContext context) {
    final fs = FirestoreService();
    final moodsList = [
      {'emoji': '✨', 'label': 'دڵخۆش'},
      {'emoji': '🌧️', 'label': 'خەمبار'},
      {'emoji': '🔋', 'label': 'ماندوو'},
      {'emoji': '🌩️', 'label': 'توڕە'},
      {'emoji': '🌹', 'label': 'ڕۆمانسی'},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2A2A40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('هەست بە چی دەکەیت؟', style: AppTheme.titleLarge),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: moodsList.map((m) {
                final isSelected = currentMood == m['label'];
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (isSelected) {
                      fs.updateMood(uid, null);
                    } else {
                      fs.updateMood(uid, m['label']!);
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(left: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primary.withValues(alpha: 0.2) : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? AppTheme.primary : const Color(0xFF2A2A40),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(m['emoji']!, style: const TextStyle(fontSize: 24)),
                        const SizedBox(height: 4),
                        Text(m['label']!, style: AppTheme.bodyMedium.copyWith(fontSize: 12, color: isSelected ? AppTheme.primary : null)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _PartnerMoodCard extends StatelessWidget {
  final String partnerName;
  final String? partnerMood;
  final UserModel me;

  const _PartnerMoodCard({required this.partnerName, this.partnerMood, required this.me});

  @override
  Widget build(BuildContext context) {
    if (partnerMood == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text('$partnerName هێشتا باری دەروونی دیاری نەکردووە.', style: AppTheme.bodyMedium),
      );
    }

    String emoji = '😶';
    if (partnerMood == 'دڵخۆش') emoji = '✨';
    if (partnerMood == 'خەمبار') emoji = '🌧️';
    if (partnerMood == 'ماندوو') emoji = '🔋';
    if (partnerMood == 'توڕە') emoji = '🌩️';
    if (partnerMood == 'ڕۆمانسی') emoji = '🌹';

    final needsCheeringUp = ['خەمبار', 'ماندوو', 'توڕە'].contains(partnerMood);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary.withValues(alpha: 0.1),
            AppTheme.accent.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 40)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ئەمڕۆ $partnerName:', style: AppTheme.bodyMedium),
                Text(partnerMood!, style: AppTheme.titleLarge.copyWith(color: AppTheme.primary)),
              ],
            ),
          ),
          if (needsCheeringUp)
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => AiSuggestionsScreen(me: me)),
                  );
                },
                icon: const Icon(Icons.psychology, size: 16),
                label: const Text('دڵخۆشی بکە'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 44), // Override the infinity width
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
        ],
      ),
    );
  }
}
