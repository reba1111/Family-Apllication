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
        title: const Text('مێژووی پاشەکەوت'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // GOAL SUMMARY CARD (Bank Card Style)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.primary,
                          AppTheme.primary.withOpacity(0.6),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(goal.icon, style: const TextStyle(fontSize: 32)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                goal.isCompleted ? 'تەواوبوو' : 'بەردەوامە',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Text('کۆکراوەی ئێستا', style: TextStyle(color: Colors.white70, fontSize: 14)),
                        const SizedBox(height: 4),
                        Text(
                          '$currencyPrefix${formatCurrency.format(goal.currentAmount)}$currencySuffix',
                          style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('ئامانجی کۆتایی', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                const SizedBox(height: 4),
                                Text(
                                  '$currencyPrefix${formatCurrency.format(goal.targetAmount)}$currencySuffix',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text('بەروار', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat('yyyy/MM/dd').format(goal.targetDate),
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.receipt_long_rounded, color: Colors.white70, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text('مێژووی زیادکردنی پارە', style: AppTheme.titleLarge),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          StreamBuilder<List<GoalTransactionModel>>(
            stream: fs.streamGoalTransactions(coupleId, goal.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
                );
              }
              if (snapshot.hasError) {
                return SliverFillRemaining(
                  child: Center(child: Text('هەڵەیەک ڕوویدا!', style: const TextStyle(color: AppTheme.error))),
                );
              }

              final transactions = snapshot.data ?? [];
              if (transactions.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history_rounded, size: 64, color: Colors.white.withOpacity(0.1)),
                        const SizedBox(height: 16),
                        const Text('هیچ مێژوویەک نییە', style: TextStyle(color: Colors.white54, fontSize: 16)),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final tx = transactions[index];
                      return StreamBuilder<UserModel?>(
                        stream: fs.streamUser(tx.userId),
                        builder: (context, userSnap) {
                          final user = userSnap.data;
                          final userName = user?.displayName ?? 'بەکارهێنەر';
                          final isMe = tx.userId == currentUserId;
                          
                          // Format date nicely
                          final txDate = tx.createdAt;
                          final now = DateTime.now();
                          final isToday = txDate.year == now.year && txDate.month == now.month && txDate.day == now.day;
                          final isYesterday = txDate.year == now.year && txDate.month == now.month && txDate.day == now.day - 1;
                          
                          String dateStr;
                          if (isToday) {
                            dateStr = 'ئەمڕۆ, ${DateFormat('hh:mm a').format(txDate)}';
                          } else if (isYesterday) {
                            dateStr = 'دوێنێ, ${DateFormat('hh:mm a').format(txDate)}';
                          } else {
                            dateStr = DateFormat('yyyy/MM/dd, hh:mm a').format(txDate);
                          }

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withOpacity(0.05)),
                            ),
                            child: Row(
                              children: [
                                // Initial or icon
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: isMe 
                                        ? [AppTheme.primary.withOpacity(0.8), AppTheme.primary.withOpacity(0.4)]
                                        : [Colors.purpleAccent.withOpacity(0.8), Colors.purpleAccent.withOpacity(0.4)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isMe ? 'تۆ زیادکرد' : '$userName زیادی کرد',
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        dateStr,
                                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '+$currencyPrefix${formatCurrency.format(tx.amount)}',
                                      style: const TextStyle(
                                        color: AppTheme.success,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    Text(
                                      currencySuffix.trim(),
                                      style: const TextStyle(color: AppTheme.success, fontSize: 12),
                                    )
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                    childCount: transactions.length,
                  ),
                ),
              );
            },
          ),
          
          // Bottom padding
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}
