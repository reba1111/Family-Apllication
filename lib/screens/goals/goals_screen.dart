import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../services/firestore_service.dart';
import 'add_goal_screen.dart';
import 'goal_history_screen.dart';

class GoalsScreen extends StatelessWidget {
  final String currentUserId;
  final String coupleId;

  const GoalsScreen({
    super.key,
    required this.currentUserId,
    required this.coupleId,
  });

  @override
  Widget build(BuildContext context) {
    final fs = FirestoreService();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('ئامانجە هاوبەشەکان'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primary,
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AddGoalScreen(
              coupleId: coupleId,
              currentUserId: currentUserId,
            ),
          ),
        ),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<List<GoalModel>>(
        stream: fs.streamGoals(coupleId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('هەڵەیەک ڕوویدا: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
          }

          final goals = snapshot.data ?? [];
          if (goals.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.savings_outlined, size: 80, color: Colors.white54),
                  const SizedBox(height: 16),
                  Text('هیچ ئامانجێک نەدۆزرایەوە', style: AppTheme.headlineMedium),
                  const SizedBox(height: 8),
                  Text('یەکەمین ئامانجی هاوبەشتان دابنێن!', style: AppTheme.bodyMedium),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: goals.length,
            itemBuilder: (context, index) {
              return _GoalCard(
                goal: goals[index],
                currentUserId: currentUserId,
                coupleId: coupleId,
                fs: fs,
              );
            },
          );
        },
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final GoalModel goal;
  final String currentUserId;
  final String coupleId;
  final FirestoreService fs;

  const _GoalCard({
    required this.goal,
    required this.currentUserId,
    required this.coupleId,
    required this.fs,
  });

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat.decimalPattern();
    final percentage = (goal.progress * 100).toStringAsFixed(1);
    final isMine = goal.createdBy == currentUserId;
    final currencySymbol = goal.currency == 'IQD' ? ' دینار' : '\$';
    final currencyPrefix = goal.currency == '\$' ? '\$' : '';
    final currencySuffix = goal.currency == 'IQD' ? ' دینار' : '';

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => GoalHistoryScreen(
              coupleId: coupleId,
              goal: goal,
              currentUserId: currentUserId,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF2A2A40)),
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Text(goal.icon, style: const TextStyle(fontSize: 40)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(goal.title, style: AppTheme.titleLarge),
                      const SizedBox(height: 4),
                      Text(
                        'ئامانج: $currencyPrefix${formatCurrency.format(goal.targetAmount)}$currencySuffix',
                        style: AppTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                if (isMine)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.white54),
                    color: AppTheme.surface,
                    onSelected: (val) {
                      if (val == 'edit') {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AddGoalScreen(
                              coupleId: coupleId,
                              currentUserId: currentUserId,
                              goal: goal,
                            ),
                          ),
                        );
                      } else if (val == 'delete') {
                        _confirmDelete(context);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('دەستکاریکردن', style: TextStyle(color: Colors.white))),
                      const PopupMenuItem(value: 'delete', child: Text('سڕینەوە', style: TextStyle(color: Colors.redAccent))),
                    ],
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('کۆکراوە: $currencyPrefix${formatCurrency.format(goal.currentAmount)}$currencySuffix', style: const TextStyle(color: AppTheme.success, fontWeight: FontWeight.bold)),
                    Text('%$percentage', style: const TextStyle(color: Colors.white54)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: goal.progress,
                    backgroundColor: Colors.black26,
                    color: goal.isCompleted ? AppTheme.success : AppTheme.primary,
                    minHeight: 10,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'بەروار: ${DateFormat('yyyy/MM/dd').format(goal.targetDate)}',
                      style: AppTheme.bodyMedium.copyWith(fontSize: 12),
                    ),
                    if (goal.isCompleted)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.success.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('تەواوبوو! 🎉', style: TextStyle(color: AppTheme.success, fontSize: 12, fontWeight: FontWeight.bold)),
                      )
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (!goal.isCompleted)
            InkWell(
              onTap: () => _showAddFundsDialog(context),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                  border: const Border(top: BorderSide(color: Color(0xFF2A2A40))),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_circle_outline, color: AppTheme.primary),
                    SizedBox(width: 8),
                    Text('پارە زیادکردن', style: TextStyle(color: AppTheme.primary, fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
        ],
      ),
    ));
  }

  Future<void> _showAddFundsDialog(BuildContext context) async {
    final controller = TextEditingController();
    final formatCurrency = NumberFormat.decimalPattern();
    final remaining = goal.targetAmount - goal.currentAmount;
    final currencyPrefix = goal.currency == '\$' ? '\$' : '';
    final currencySuffix = goal.currency == 'IQD' ? ' دینار' : '';

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          title: const Text('پارە زیادکردن', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ئامانج: ${goal.title}', style: const TextStyle(color: Colors.white70)),
              Text('ماوە: $currencyPrefix${formatCurrency.format(remaining)}$currencySuffix', style: const TextStyle(color: AppTheme.primary)),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  prefixText: '$currencyPrefix ',
                  suffixText: currencySuffix,
                  prefixStyle: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
                  suffixStyle: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
                  hintText: 'بڕی پارەکە بنووسە',
                  hintStyle: const TextStyle(color: Colors.white30),
                  filled: true,
                  fillColor: AppTheme.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('پاشگەزبوونەوە', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
              onPressed: () async {
                final amount = double.tryParse(controller.text.trim());
                if (amount != null && amount > 0) {
                  Navigator.pop(context);
                  await fs.addFundsToGoal(coupleId, goal.id, amount, currentUserId);
                }
              },
              child: const Text('زیادکردن', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('سڕینەوەی ئامانج', style: TextStyle(color: Colors.white)),
        content: const Text('دڵنیایت دەتەوێت ئەم ئامانجە بسڕیتەوە؟', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('نەخێر', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('بەڵی', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await fs.deleteGoal(coupleId, goal.id);
    }
  }
}
