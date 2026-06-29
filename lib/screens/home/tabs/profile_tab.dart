import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../models/user_model.dart';
import '../../../services/auth_service.dart';
import '../../auth/login_screen.dart';
import '../../likes/likes_screen.dart';

class ProfileTab extends StatelessWidget {
  final UserModel user;
  const ProfileTab({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration:
          const BoxDecoration(gradient: AppTheme.backgroundGradient),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            children: [
              // Avatar
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.4),
                      blurRadius: 24,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    user.displayName.isNotEmpty
                        ? user.displayName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(user.displayName, style: AppTheme.headlineMedium),
              const SizedBox(height: 4),
              Text(user.email, style: AppTheme.bodyMedium),
              if (user.coupleId != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppTheme.primary.withOpacity(0.4)),
                  ),
                  child: Text(
                    '❤️ بەستراوە',
                    style: AppTheme.labelLarge
                        .copyWith(color: AppTheme.primary),
                  ),
                ),
              ],
              const SizedBox(height: 36),

              // Likes/Dislikes preview
              _SectionCard(
                title: '❤️ حەزەکانم',
                onTap: user.coupleId != null
                    ? () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => LikesScreen(
                            userId: user.uid,
                            partnerId: user.partnerId ?? '',
                          ),
                        ))
                    : null,
                child: user.likes.isEmpty
                    ? Text('هێشتا هیچ نەزیادکراوە',
                        style: AppTheme.bodyMedium)
                    : Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: user.likes
                            .take(5)
                            .map((l) => _Tag(l, AppTheme.primary))
                            .toList(),
                      ),
              ),
              const SizedBox(height: 14),
              _SectionCard(
                title: '💔 حەزم پێی نییە',
                onTap: user.coupleId != null
                    ? () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => LikesScreen(
                            userId: user.uid,
                            partnerId: user.partnerId ?? '',
                          ),
                        ))
                    : null,
                child: user.dislikes.isEmpty
                    ? Text('هێشتا هیچ نەزیادکراوە',
                        style: AppTheme.bodyMedium)
                    : Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: user.dislikes
                            .take(5)
                            .map((d) => _Tag(d, AppTheme.error))
                            .toList(),
                      ),
              ),
              const SizedBox(height: 32),

              // Sign out
              OutlinedButton.icon(
                onPressed: () async {
                  await AuthService().signOut();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                          builder: (_) => const LoginScreen()),
                      (_) => false,
                    );
                  }
                },
                icon: const Icon(Icons.logout_rounded,
                    color: AppTheme.error),
                label: const Text('چوونەدەرەوە',
                    style: TextStyle(color: AppTheme.error)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.error),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final VoidCallback? onTap;
  const _SectionCard(
      {required this.title, required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: AppTheme.cardGradient,
          borderRadius: BorderRadius.circular(18),
          border: const Border.fromBorderSide(
            BorderSide(color: Color(0xFF2A2A40)),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(title, style: AppTheme.titleLarge),
                const Spacer(),
                if (onTap != null)
                  const Icon(Icons.chevron_right,
                      color: AppTheme.onSurfaceMuted),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final Color color;
  const _Tag(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(text,
          style: AppTheme.bodyMedium.copyWith(color: color, fontSize: 13)),
    );
  }
}
