import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../models/user_model.dart';
import '../../ai/ai_suggestions_screen.dart';
import '../../couple_code/generate_code_screen.dart';
import '../../family/family_screen.dart';
import '../../quiz/quiz_screen.dart';
import '../../likes/likes_screen.dart';

import '../widgets/mood_tracker_widget.dart';

import '../../memories/memories_screen.dart';
import '../../notes/notes_screen.dart';

class DashboardTab extends StatelessWidget {
  final UserModel user;
  const DashboardTab({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final linked = user.coupleId != null;

    return Container(
      decoration:
          const BoxDecoration(gradient: AppTheme.backgroundGradient),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'بەخێربێیت، ${user.displayName} 👋',
                          style: AppTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          linked
                              ? 'تۆ و هاوسەرەکەت بەستراون ❤️'
                              : 'هێشتا هاوسەرەکەت بەستراو نییە',
                          style: AppTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        user.displayName.isNotEmpty
                            ? user.displayName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Mood Tracker
              MoodTrackerWidget(
                currentUserId: user.uid,
                partnerId: user.partnerId,
              ),
              const SizedBox(height: 28),

              // Not linked warning
              if (!linked)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primary.withOpacity(0.15),
                        AppTheme.primaryDark.withOpacity(0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppTheme.primary.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      const Text('💑',
                          style: TextStyle(fontSize: 40)),
                      const SizedBox(height: 12),
                      Text('بەستنی هاوسەر',
                          style: AppTheme.titleLarge),
                      const SizedBox(height: 6),
                      Text(
                        'کۆدی هاوسەرت بگر یان کۆدی هاوسەرەکەت داخڵ بکە',
                        style: AppTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) =>
                                  const GenerateCodeScreen()),
                        ),
                        child: const Text('بەستنی هاوسەر'),
                      ),
                    ],
                  ),
                ),

              if (linked) ...[
                // Feature grid
                Text('تایبەتمەندییەکان',
                    style: AppTheme.headlineMedium),
                const SizedBox(height: 16),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.1,
                  children: [
                    _FeatureCard(
                      emoji: '💌',
                      title: 'نامەی شاراوە',
                      subtitle: 'نامەی قفڵکراو بنێرە',
                      color: const Color(0xFFF44336),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => NotesScreen(me: user),
                        ),
                      ),
                    ),
                    _FeatureCard(
                      emoji: '📸',
                      title: 'یادگارییەکان',
                      subtitle: 'ئەلبوومی تایبەت',
                      color: const Color(0xFFFF9800),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => MemoriesScreen(me: user),
                        ),
                      ),
                    ),
                    _FeatureCard(
                      emoji: '❤️',
                      title: 'حەزەکانم',
                      subtitle: 'خوشیەکانت زیاد بکە',
                      color: const Color(0xFFE91E8C),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => LikesScreen(
                            userId: user.uid,
                            partnerId: user.partnerId ?? '',
                          ),
                        ),
                      ),
                    ),
                    _FeatureCard(
                      emoji: '👨‍👩‍👧',
                      title: 'خێزان',
                      subtitle: 'ئەندامانی خێزان',
                      color: const Color(0xFF9C27B0),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              FamilyScreen(coupleId: user.coupleId!),
                        ),
                      ),
                    ),
                    _FeatureCard(
                      emoji: '❓',
                      title: 'کوئیز',
                      subtitle: 'پرسیار لە یەکتر بکەن',
                      color: const Color(0xFF2196F3),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => QuizScreen(
                            coupleId: user.coupleId!,
                            currentUserId: user.uid,
                          ),
                        ),
                      ),
                    ),
                    _FeatureCard(
                      emoji: '✨',
                      title: 'پێشنیاری AI',
                      subtitle: 'دیاری و ئێوارەی ڕۆمانتیک',
                      color: const Color(0xFF9C27B0),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              AiSuggestionsScreen(me: user),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.15),
              color.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 32)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTheme.titleLarge),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTheme.bodyMedium.copyWith(fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
