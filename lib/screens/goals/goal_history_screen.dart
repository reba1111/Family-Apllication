import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';

class GoalHistoryScreen extends StatelessWidget {
  final String coupleId;
  final GoalModel goal;
  final String currentUserId;

  const GoalHistoryScreen({
    super.key,
    required this.coupleId,
    required this.goal,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final fs = FirestoreService();
    final formatCurrency = NumberFormat.decimalPattern();
    final currencyPrefix = goal.currency == '\$' ? '\$' : '';
    final currencySuffix = goal.currency == 'IQD' ? ' دینار' : '';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('${goal.icon} ${goal.title}'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Goal Summary Header
          Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('کۆکراوەی ئێستا', style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 4),
                    Text(
                      '$currencyPrefix${formatCurrency.format(goal.currentAmount)}$currencySuffix',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('ئامانج', style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 4),
                    Text(
                      '$currencyPrefix${formatCurrency.format(goal.targetAmount)}$currencySuffix',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.history, color: AppTheme.primary),
                const SizedBox(width: 8),
                Text('مێژووی زیادکردنی پارە', style: AppTheme.titleLarge),
              ],
            ),
          ),

          Expanded(
            child: StreamBuilder<List<GoalTransactionModel>>(
              stream: fs.streamGoalTransactions(coupleId, goal.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  // If Firestore index is missing, error message will contain a link to create it
                  final err = snapshot.error.toString();
                  final indexLink = err.contains('https://') 
                      ? err.substring(err.indexOf('https://')) 
                      : null;
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                          const SizedBox(height: 12),
                          const Text('هەڵەیەک ڕوویدا', style: TextStyle(color: Colors.white, fontSize: 16)),
                          if (indexLink != null) ...[
                            const SizedBox(height: 8),
                            const Text('پێویستە لە فایرستۆر ئیندێکس دروست بکەیت.\nبۆ ئەوەی ئیندێکسەکە دروست بکەیت، لینکی ئەرۆری کنسۆڵەکە بدەرۆ و کلیکی بکە.',
                              style: TextStyle(color: Colors.white54, fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }

                final transactions = snapshot.data ?? [];
                if (transactions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.receipt_long, size: 60, color: Colors.white24),
                        const SizedBox(height: 16),
                        Text('هیچ مێژوویەک نییە', style: AppTheme.bodyMedium.copyWith(color: Colors.white54)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final tx = transactions[index];
                    return StreamBuilder<UserModel?>(
                      stream: fs.streamUser(tx.userId),
                      builder: (context, userSnap) {
                        final user = userSnap.data;
                        final userName = user?.displayName ?? 'بەکارهێنەر';
                        final isMe = tx.userId == currentUserId;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.1)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isMe ? AppTheme.primary.withValues(alpha: 0.2) : AppTheme.accent.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.add, color: isMe ? AppTheme.primary : AppTheme.accent),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isMe ? 'تۆ زایادتکرد' : '$userName زیادی کرد',
                                      style: AppTheme.bodyLarge,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      DateFormat('yyyy/MM/dd hh:mm a').format(tx.createdAt),
                                      style: AppTheme.bodyMedium.copyWith(fontSize: 12, color: Colors.white54),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '+$currencyPrefix${formatCurrency.format(tx.amount)}$currencySuffix',
                                style: const TextStyle(
                                  color: AppTheme.success,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
