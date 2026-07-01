import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../services/firestore_service.dart';

class QuizScreen extends StatefulWidget {
  final String coupleId;
  final String currentUserId;
  const QuizScreen(
      {super.key, required this.coupleId, required this.currentUserId});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen>
    with SingleTickerProviderStateMixin {
  final _fs = FirestoreService();
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  void _showAddEditQuiz({QuizModel? editQuiz}) {
    final qCtrl = TextEditingController(text: editQuiz?.question ?? '');
    final aCtrl = TextEditingController(text: editQuiz?.answer ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                editQuiz == null ? 'پرسیاری نوێ ❓' : 'دەستکاریکردنی پرسیار ❓',
                style: AppTheme.headlineMedium,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: qCtrl,
                style: TextStyle(color: AppTheme.onSurface),
                decoration: const InputDecoration(hintText: 'پرسیارەکە بنووسە...'),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: aCtrl,
                style: TextStyle(color: AppTheme.onSurface),
                decoration: const InputDecoration(
                    hintText: 'وەڵامەکە (تا کاتی دیاریکردن نادرێت)'),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (qCtrl.text.trim().isEmpty ||
                            aCtrl.text.trim().isEmpty) {
                          return;
                        }
                        final quiz = QuizModel(
                          id: editQuiz?.id ?? '',
                          question: qCtrl.text.trim(),
                          answer: aCtrl.text.trim(),
                          createdBy: widget.currentUserId,
                          createdAt: editQuiz?.createdAt ?? DateTime.now(),
                          answeredBy: editQuiz?.answeredBy,
                          userAnswer: editQuiz?.userAnswer,
                          isCorrect: editQuiz?.isCorrect,
                        );
                        if (editQuiz != null) {
                          await _fs.updateQuiz(
                              widget.coupleId, editQuiz.id, quiz.toFirestore());
                        } else {
                          await _fs.addQuiz(widget.coupleId, quiz);
                        }
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: Text(editQuiz == null ? 'زیادکردن' : 'پاشەکەوتکردن'),
                    ),
                  ),
                  if (editQuiz != null) ...[
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppTheme.error),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: ctx,
                          builder: (c) => AlertDialog(
                            backgroundColor: AppTheme.surface,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20)),
                            title: Text('سڕینەوە', style: AppTheme.titleLarge),
                            content: Text('دڵنیایت لە سڕینەوەی ئەم پرسیارە؟',
                                style: AppTheme.bodyLarge),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(c, false),
                                  child: const Text('نەخێر',
                                      style: TextStyle(
                                          color: AppTheme.onSurfaceMuted))),
                              TextButton(
                                  onPressed: () => Navigator.pop(c, true),
                                  child: const Text('بەڵێ، بسڕەوە',
                                      style: TextStyle(color: AppTheme.error))),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await _fs.deleteQuiz(widget.coupleId, editQuiz.id);
                          if (ctx.mounted) Navigator.pop(ctx);
                        }
                      },
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAnswer(QuizModel quiz) {
    if (quiz.createdBy == widget.currentUserId) {
      if (quiz.answeredBy == null) {
        _showAddEditQuiz(editQuiz: quiz);
        return;
      }
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: AppTheme.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('وەڵامەکە', style: AppTheme.titleLarge),
          content: Text(quiz.answer,
              style: AppTheme.bodyLarge.copyWith(color: AppTheme.primary)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('داخستن',
                  style: TextStyle(color: AppTheme.primary)),
            ),
          ],
        ),
      );
    } else {
      final ansCtrl = TextEditingController();
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppTheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        builder: (ctx) => Padding(
          padding: EdgeInsets.fromLTRB(
              24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('وەڵامی پرسیار', style: AppTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(quiz.question, style: AppTheme.bodyLarge),
                const SizedBox(height: 20),
                TextField(
                  controller: ansCtrl,
                  style: TextStyle(color: AppTheme.onSurface),
                  decoration:
                      const InputDecoration(hintText: 'وەڵامەکەت بنووسە...'),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    if (ansCtrl.text.trim().isEmpty) return;
                    await _fs.answerQuiz(
                      coupleId: widget.coupleId,
                      quizId: quiz.id,
                      answeredBy: widget.currentUserId,
                      userAnswer: ansCtrl.text.trim(),
                      correctAnswer: quiz.answer,
                    );
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('ناردنی وەڵام'),
                ),
              ],
            ),
          ),
        ),
      );
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
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 12, 20, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new,
                          color: AppTheme.onSurface),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text('تاقیکردنەوە ❓', style: AppTheme.headlineMedium),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TabBar(
                  controller: _tab,
                  dividerColor: Colors.transparent,
                  indicator: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  labelStyle: AppTheme.labelLarge,
                  unselectedLabelColor: AppTheme.onSurfaceMuted,
                  tabs: const [
                    Tab(text: 'پرسیارەکانم'),
                    Tab(text: 'پرسیارەکانی هاوسەر'),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: StreamBuilder<List<QuizModel>>(
                  stream: _fs.streamQuiz(widget.coupleId),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                            color: AppTheme.primary),
                      );
                    }
                    final all = snap.data ?? [];
                    final mine = all
                        .where((q) => q.createdBy == widget.currentUserId)
                        .toList();
                    final theirs = all
                        .where((q) => q.createdBy != widget.currentUserId)
                        .toList();

                    return TabBarView(
                      controller: _tab,
                      children: [
                        _QuizList(
                          quizzes: mine,
                          isCreator: true,
                          coupleId: widget.coupleId,
                          fs: _fs,
                          onTap: _showAnswer,
                        ),
                        _QuizList(
                          quizzes: theirs,
                          isCreator: false,
                          coupleId: widget.coupleId,
                          fs: _fs,
                          onTap: _showAnswer,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditQuiz(),
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label:
            const Text('پرسیاری نوێ', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

class _QuizList extends StatelessWidget {
  final List<QuizModel> quizzes;
  final bool isCreator;
  final String coupleId;
  final FirestoreService fs;
  final void Function(QuizModel) onTap;

  const _QuizList({
    required this.quizzes,
    required this.isCreator,
    required this.coupleId,
    required this.fs,
    required this.onTap,
  });

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('سڕینەوە', style: AppTheme.titleLarge),
        content: Text('دڵنیایت لە سڕینەوەی ئەم پرسیارە؟',
            style: AppTheme.bodyLarge),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('نەخێر',
                style: TextStyle(color: AppTheme.onSurfaceMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('بەڵێ، بسڕەوە',
                style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (quizzes.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('❓', style: TextStyle(fontSize: 52)),
            const SizedBox(height: 12),
            Text(
              isCreator
                  ? 'هێشتا پرسیارێکت نەنووستووە'
                  : 'هاوسەرەکەت هێشتا پرسیارێک ننووستووە',
              style: AppTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      itemCount: quizzes.length,
      itemBuilder: (_, i) {
        final q = quizzes[i];
        final answered = q.answeredBy != null;
        final correct = q.isCorrect ?? false;

        Color statusColor = AppTheme.onSurfaceMuted;
        String statusLabel = 'چاوەڕوانی وەڵام';
        IconData statusIcon = Icons.hourglass_empty_rounded;

        if (answered) {
          statusColor = correct ? AppTheme.success : AppTheme.error;
          statusLabel = correct ? 'وەڵامی دروست ✓' : 'وەڵامی هەڵە ✗';
          statusIcon = correct
              ? Icons.check_circle_outline
              : Icons.cancel_outlined;
        }

        return Dismissible(
          key: ValueKey(q.id),
          direction: DismissDirection.endToStart,
          confirmDismiss: (_) => _confirmDelete(context),
          onDismissed: (_) => fs.deleteQuiz(coupleId, q.id),
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppTheme.error.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.delete_outline, color: AppTheme.error),
          ),
          child: GestureDetector(
            onTap: () => onTap(q),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppTheme.cardGradient,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: answered
                      ? statusColor.withValues(alpha: 0.4)
                      : const Color(0xFF2A2A40),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('❓', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(q.question,
                            style: AppTheme.bodyLarge.copyWith(
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  if (answered && !isCreator) ...[
                    const SizedBox(height: 8),
                    Text('وەڵامت: ${q.userAnswer}',
                        style: AppTheme.bodyMedium),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 6),
                      Text(statusLabel,
                          style: AppTheme.bodyMedium.copyWith(
                              color: statusColor, fontSize: 12)),
                      const Spacer(),
                      if (!answered && !isCreator)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: AppTheme.primary.withValues(alpha: 0.4)),
                          ),
                          child: Text('وەڵامبدەوە',
                              style: AppTheme.bodyMedium.copyWith(
                                color: AppTheme.primary,
                                fontSize: 12,
                              )),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
