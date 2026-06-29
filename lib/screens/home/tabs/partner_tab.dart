import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../models/user_model.dart';
import '../../../services/firestore_service.dart';

class PartnerTab extends StatelessWidget {
  final String coupleId;
  final String partnerId;
  const PartnerTab(
      {super.key, required this.coupleId, required this.partnerId});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration:
          const BoxDecoration(gradient: AppTheme.backgroundGradient),
      child: SafeArea(
        child: StreamBuilder<UserModel?>(
          stream: FirestoreService().streamUser(partnerId),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppTheme.primary),
              );
            }
            final partner = snap.data;
            if (partner == null) {
              return Center(
                child: Text('هاوسەرەکەت بوجود نییە',
                    style: AppTheme.bodyMedium),
              );
            }

            return SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                children: [
                  // Partner avatar
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF9C27B0), Color(0xFFE91E8C)],
                      ),
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
                        partner.displayName.isNotEmpty
                            ? partner.displayName[0].toUpperCase()
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
                  Text(partner.displayName,
                      style: AppTheme.headlineMedium),
                  const SizedBox(height: 4),
                  Text('هاوسەرەکەت ❤️',
                      style: AppTheme.bodyMedium
                          .copyWith(color: AppTheme.primary)),
                  const SizedBox(height: 36),

                  // Partner likes
                  _InfoCard(
                    title: '❤️ حەزەکانی',
                    items: partner.likes,
                    color: AppTheme.primary,
                    emptyMsg: 'هێشتا هیچی نەنووستووە',
                  ),
                  const SizedBox(height: 14),
                  _InfoCard(
                    title: '💔 حەزی پێی نییە',
                    items: partner.dislikes,
                    color: AppTheme.error,
                    emptyMsg: 'هێشتا هیچی نەنووستووە',
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<String> items;
  final Color color;
  final String emptyMsg;

  const _InfoCard({
    required this.title,
    required this.items,
    required this.color,
    required this.emptyMsg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Text(title, style: AppTheme.titleLarge),
          const SizedBox(height: 12),
          items.isEmpty
              ? Text(emptyMsg, style: AppTheme.bodyMedium)
              : Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: items
                      .map((item) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border:
                                  Border.all(color: color.withOpacity(0.4)),
                            ),
                            child: Text(item,
                                style: AppTheme.bodyMedium.copyWith(
                                    color: color, fontSize: 13)),
                          ))
                      .toList(),
                ),
        ],
      ),
    );
  }
}
