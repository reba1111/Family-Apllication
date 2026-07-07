import 'dart:ui';
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
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primary,
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AddGoalScreen(
              coupleId: coupleId,
              currentUserId: currentUserId,
            ),
          ),
        ),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('ئامانجی نوێ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<List<GoalModel>>(
        stream: fs.streamGoals(coupleId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
          }
          if (snapshot.hasError) {
            return Center(child: Text('هەڵەیەک ڕوویدا: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
          }

          final goals = snapshot.data ?? [];
          
          // Calculate total target and current amounts
          double totalTarget = 0;
          double totalCurrent = 0;
          for (var g in goals) {
            totalTarget += g.targetAmount;
            totalCurrent += g.currentAmount;
          }
          
          double overallProgress = totalTarget > 0 ? (totalCurrent / totalTarget) : 0.0;
          if (overallProgress > 1.0) overallProgress = 1.0;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              // Modern Sliver AppBar
              SliverAppBar(
                expandedHeight: 260.0,
                pinned: true,
                backgroundColor: AppTheme.background,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Gradient Background
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppTheme.primary.withOpacity(0.4),
                              AppTheme.background,
                            ],
                          ),
                        ),
                      ),
                      // Content
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 56, 24, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                'پاشەکەوتی هاوبەش',
                                style: AppTheme.bodyMedium.copyWith(color: Colors.white70),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${NumberFormat.decimalPattern().format(totalCurrent)} \$',
                                style: AppTheme.headlineMedium.copyWith(fontSize: 30, fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(height: 12),
                              // Overall Progress Bar
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value: overallProgress,
                                  backgroundColor: Colors.black26,
                                  color: AppTheme.primary,
                                  minHeight: 8,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('لە کۆی ${NumberFormat.compact().format(totalTarget)} \$', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                  Text('%${(overallProgress * 100).toStringAsFixed(0)}', style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              
              // Empty State or List
              if (goals.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.primary.withOpacity(0.1),
                          ),
                          child: const Icon(Icons.savings_rounded, size: 64, color: AppTheme.primary),
                        ),
                        const SizedBox(height: 24),
                        Text('هیچ ئامانجێک نییە', style: AppTheme.headlineMedium),
                        const SizedBox(height: 8),
                        Text('با پێکەوە دەست بکەین بە پاشەکەوتکردن!', style: AppTheme.bodyMedium.copyWith(color: Colors.white54)),
                        const SizedBox(height: 60), // Space for FAB
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 100), // Bottom padding for FAB
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return _GoalCard(
                          goal: goals[index],
                          currentUserId: currentUserId,
                          coupleId: coupleId,
                          fs: fs,
                        );
                      },
                      childCount: goals.length,
                    ),
                  ),
                ),
            ],
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
    final currencyPrefix = goal.currency == '\$' ? '\$' : '';
    final currencySuffix = goal.currency == 'IQD' ? ' دینار' : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.surface.withOpacity(0.8),
            AppTheme.surface.withOpacity(0.4),
          ],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: InkWell(
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(goal.icon, style: const TextStyle(fontSize: 32)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(goal.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                            const SizedBox(height: 4),
                            Text(
                              '$currencyPrefix${formatCurrency.format(goal.currentAmount)}$currencySuffix / $currencyPrefix${formatCurrency.format(goal.targetAmount)}$currencySuffix',
                              style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      if (isMine)
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_horiz, color: Colors.white54),
                          color: const Color(0xFF2A2A40),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                            const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, color: Colors.white, size: 20), SizedBox(width: 8), Text('دەستکاریکردن', style: TextStyle(color: Colors.white))])),
                            const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, color: Colors.redAccent, size: 20), SizedBox(width: 8), Text('سڕینەوە', style: TextStyle(color: Colors.redAccent))])),
                          ],
                        ),
                    ],
                  ),
                ),
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('%$percentage', style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
                          Text(
                            'ماوە: $currencyPrefix${formatCurrency.format(goal.targetAmount - goal.currentAmount)}$currencySuffix', 
                            style: const TextStyle(color: Colors.white30, fontSize: 12)
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: LinearProgressIndicator(
                          value: goal.progress,
                          backgroundColor: Colors.white.withOpacity(0.05),
                          color: goal.isCompleted ? AppTheme.success : AppTheme.primary,
                          minHeight: 12,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
                
                // Add Funds Button Area
                if (!goal.isCompleted)
                  InkWell(
                    onTap: () => _showAddFundsDialog(context),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.1),
                        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add, color: AppTheme.primary.withOpacity(0.8), size: 20),
                          const SizedBox(width: 8),
                          Text('پارە زیادکردن', style: TextStyle(color: AppTheme.primary.withOpacity(0.9), fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.success.withOpacity(0.1),
                      border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline, color: AppTheme.success, size: 20),
                        SizedBox(width: 8),
                        Text('ئامانجەکە تەواوبوو! 🎉', style: TextStyle(color: AppTheme.success, fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showAddFundsDialog(BuildContext context) async {
    final controller = TextEditingController();
    final formatCurrency = NumberFormat.decimalPattern();
    final remaining = goal.targetAmount - goal.currentAmount;
    final currencyPrefix = goal.currency == '\$' ? '\$' : '';
    final currencySuffix = goal.currency == 'IQD' ? ' دینار' : '';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E2E),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 20,
                spreadRadius: 5,
              )
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Text(goal.icon, style: const TextStyle(fontSize: 32)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('پارە زیادکردن', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                          Text('بۆ ${goal.title}', style: const TextStyle(color: Colors.white54, fontSize: 14)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('بڕی ماوە', style: TextStyle(color: Colors.white70)),
                      Text('$currencyPrefix${formatCurrency.format(remaining)}$currencySuffix', style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 18)),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  autofocus: true,
                  decoration: InputDecoration(
                    prefixText: '$currencyPrefix ',
                    suffixText: currencySuffix,
                    prefixStyle: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 24),
                    suffixStyle: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 16),
                    hintText: '0',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
                    filled: true,
                    fillColor: Colors.black26,
                    contentPadding: const EdgeInsets.all(24),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 5,
                      shadowColor: AppTheme.primary.withOpacity(0.5),
                    ),
                    onPressed: () async {
                      String text = controller.text.trim().replaceAll(',', '');
                      const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
                      const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
                      const persian = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
                      for (int i = 0; i < 10; i++) {
                        text = text.replaceAll(arabic[i], english[i]);
                        text = text.replaceAll(persian[i], english[i]);
                      }
                      text = text.replaceAll(RegExp(r'[^0-9.]'), '');
                      if (text.split('.').length > 2 || RegExp(r'\.\d{3}$').hasMatch(text)) {
                        text = text.replaceAll('.', '');
                      }

                      final amount = double.tryParse(text);
                      if (amount != null && amount > 0) {
                        Navigator.pop(context);
                        try {
                          await fs.addFundsToGoal(coupleId, goal.id, amount, currentUserId);
                          // Notify partner
                          fs.notifyPartner(
                            coupleId: coupleId,
                            currentUserId: currentUserId,
                            title: 'ئامانجی پاشەکەوت',
                            body: '${goal.icon} بڕی $text زیادکرا بۆ ${goal.title}',
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('پارەکە بە سەرکەوتوویی زیادکرا! 🎉'), backgroundColor: AppTheme.success, behavior: SnackBarBehavior.floating),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('هەڵەیەک ڕوویدا: $e'), backgroundColor: AppTheme.error, behavior: SnackBarBehavior.floating),
                            );
                          }
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('تکایە بڕێکی دروست بنووسە'), backgroundColor: AppTheme.error, behavior: SnackBarBehavior.floating),
                        );
                      }
                    },
                    child: const Text('زیادکردن', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
            SizedBox(width: 12),
            Text('سڕینەوەی ئامانج', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Text('دڵنیایت دەتەوێت ئەم ئامانجە بسڕیتەوە؟ گەڕاندنەوەی نییە.', style: TextStyle(color: Colors.white70, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('نەخێر', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('سڕینەوە', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await fs.deleteGoal(coupleId, goal.id);
    }
  }
}
