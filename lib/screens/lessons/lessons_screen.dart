import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../services/firestore_service.dart';
import '../../services/notification_service.dart';

class LessonsScreen extends StatefulWidget {
  final String coupleId;
  const LessonsScreen({super.key, required this.coupleId});

  @override
  State<LessonsScreen> createState() => _LessonsScreenState();
}

class _LessonsScreenState extends State<LessonsScreen> {
  final _fs = FirestoreService();
  final _notif = NotificationService();
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Rebuild every minute to update countdowns
    _ticker =
        Timer.periodic(const Duration(minutes: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _showAddDialog() {
    final titleCtrl = TextEditingController();
    final subjectCtrl = TextEditingController();
    DateTime? selectedDate;
    TimeOfDay? selectedTime;
    int notifyBefore = 15;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.fromLTRB(
              24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('زیادکردنی وانە 📚', style: AppTheme.headlineMedium),
                const SizedBox(height: 20),

                TextField(
                  controller: titleCtrl,
                  autofocus: true,
                  style: TextStyle(color: AppTheme.onSurface),
                  decoration: const InputDecoration(hintText: 'ناوی وانەکە'),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: subjectCtrl,
                  style: TextStyle(color: AppTheme.onSurface),
                  decoration: const InputDecoration(
                      hintText: 'بابەتەکە (بیرکاری، کیمیا...)'),
                ),
                const SizedBox(height: 14),

                _PickerRow(
                  icon: Icons.calendar_today_outlined,
                  label: selectedDate != null
                      ? DateFormat('yyyy/MM/dd').format(selectedDate!)
                      : 'بەروار هەڵبژێرە',
                  onTap: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate:
                          DateTime.now().add(const Duration(days: 365)),
                      builder: (_, child) => Theme(
                        data: ThemeData.dark().copyWith(
                          colorScheme: const ColorScheme.dark(
                              primary: AppTheme.primary),
                        ),
                        child: child!,
                      ),
                    );
                    if (d != null) setModal(() => selectedDate = d);
                  },
                ),
                const SizedBox(height: 10),

                _PickerRow(
                  icon: Icons.access_time_rounded,
                  label: selectedTime != null
                      ? selectedTime!.format(ctx)
                      : 'کات هەڵبژێرە',
                  onTap: () async {
                    final t = await showTimePicker(
                      context: ctx,
                      initialTime: TimeOfDay.now(),
                      builder: (_, child) => Theme(
                        data: ThemeData.dark().copyWith(
                          colorScheme: const ColorScheme.dark(
                              primary: AppTheme.primary),
                        ),
                        child: child!,
                      ),
                    );
                    if (t != null) setModal(() => selectedTime = t);
                  },
                ),
                const SizedBox(height: 14),

                // Notify before
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(14),
                    border: const Border.fromBorderSide(
                        BorderSide(color: Color(0xFF33334A))),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.notifications_outlined,
                          color: AppTheme.onSurfaceMuted, size: 20),
                      const SizedBox(width: 12),
                      Text('ئاگادارکردن پێش:',
                          style: AppTheme.bodyMedium),
                      const Spacer(),
                      DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: notifyBefore,
                          dropdownColor: AppTheme.surface,
                          style: TextStyle(color: AppTheme.onSurface),
                          items: [5, 10, 15, 30, 60]
                              .map((v) => DropdownMenuItem(
                                  value: v, child: Text('$v خولەک')))
                              .toList(),
                          onChanged: (v) =>
                              setModal(() => notifyBefore = v ?? 15),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    if (titleCtrl.text.trim().isEmpty ||
                        selectedDate == null ||
                        selectedTime == null) return;
                    final dt = DateTime(
                      selectedDate!.year,
                      selectedDate!.month,
                      selectedDate!.day,
                      selectedTime!.hour,
                      selectedTime!.minute,
                    );
                    final lesson = LessonModel(
                      id: '',
                      title: titleCtrl.text.trim(),
                      subject: subjectCtrl.text.trim(),
                      dateTime: dt,
                      notifyMinutesBefore: notifyBefore,
                      createdBy:
                          FirebaseAuth.instance.currentUser?.uid ?? '',
                    );
                    final id =
                        await _fs.addLesson(widget.coupleId, lesson);
                    await _notif.scheduleLesson(
                      id: id.hashCode,
                      title: lesson.title,
                      subject: lesson.subject,
                      dateTime: dt,
                      minutesBefore: notifyBefore,
                    );
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('زیادکردن و دامەزراندنی ئاگادارکردن'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration:
            const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Text('وانەکان 📚', style: AppTheme.headlineMedium),
              ),

              Expanded(
                child: StreamBuilder<List<LessonModel>>(
                  stream: _fs.streamLessons(widget.coupleId),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                            color: AppTheme.primary),
                      );
                    }
                    final now = DateTime.now();
                    final lessons = snap.data ?? [];
                    final upcoming = lessons
                        .where((l) => l.dateTime.isAfter(now))
                        .toList();
                    final past = lessons
                        .where((l) => !l.dateTime.isAfter(now))
                        .toList();

                    if (lessons.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('📚',
                                style: TextStyle(fontSize: 56)),
                            const SizedBox(height: 12),
                            Text('هێشتا هیچ وانەیەک نەزیادکراوە',
                                style: AppTheme.bodyMedium),
                            const SizedBox(height: 8),
                            Text(
                              'دووگمەی + بکە تا وانەیەک زیاد بکەیت\nئاگادارکردنەکەش بەخۆکاری دادەنرێت',
                              style: AppTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    return CustomScrollView(
                      slivers: [
                        // Next lesson banner
                        if (upcoming.isNotEmpty)
                          SliverToBoxAdapter(
                            child: _NextLessonBanner(
                                lesson: upcoming.first),
                          ),

                        // Upcoming
                        if (upcoming.isNotEmpty) ...[
                          SliverToBoxAdapter(
                            child: _SectionLabel(
                                label: 'داهاتوو (${upcoming.length})'),
                          ),
                          SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (_, i) => _LessonCard(
                                lesson: upcoming[i],
                                coupleId: widget.coupleId,
                                isPast: false,
                                fs: _fs,
                                notif: _notif,
                              ),
                              childCount: upcoming.length,
                            ),
                          ),
                        ],

                        // Past
                        if (past.isNotEmpty) ...[
                          SliverToBoxAdapter(
                            child: _SectionLabel(
                                label: 'تێپەڕیوە (${past.length})'),
                          ),
                          SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (_, i) => _LessonCard(
                                lesson: past[i],
                                coupleId: widget.coupleId,
                                isPast: true,
                                fs: _fs,
                                notif: _notif,
                              ),
                              childCount: past.length,
                            ),
                          ),
                        ],

                        const SliverToBoxAdapter(
                            child: SizedBox(height: 100)),
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
        onPressed: _showAddDialog,
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('وانەی نوێ',
            style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

// ── Next lesson banner ────────────────────────────────────────────────────────

class _NextLessonBanner extends StatelessWidget {
  final LessonModel lesson;
  const _NextLessonBanner({required this.lesson});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final diff = lesson.dateTime.difference(now);
    final countdown = _formatCountdown(diff);

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
                child: Text('📖', style: TextStyle(fontSize: 24))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('نزیکترین وانە',
                    style: TextStyle(
                        color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 2),
                Text(lesson.title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16)),
                if (lesson.subject.isNotEmpty)
                  Text(lesson.subject,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(countdown,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 18)),
              Text(DateFormat('HH:mm').format(lesson.dateTime),
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  String _formatCountdown(Duration d) {
    if (d.inDays > 0) return '${d.inDays}ر';
    if (d.inHours > 0) return '${d.inHours}س';
    return '${d.inMinutes}خ';
  }
}

// ── Lesson card ───────────────────────────────────────────────────────────────

class _LessonCard extends StatelessWidget {
  final LessonModel lesson;
  final String coupleId;
  final bool isPast;
  final FirestoreService fs;
  final NotificationService notif;

  const _LessonCard({
    required this.lesson,
    required this.coupleId,
    required this.isPast,
    required this.fs,
    required this.notif,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(lesson.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        fs.deleteLesson(coupleId, lesson.id);
        notif.cancelLesson(lesson.id.hashCode);
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        decoration: BoxDecoration(
          color: AppTheme.error.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.delete_outline, color: AppTheme.error),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: AppTheme.cardGradient,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isPast
                ? AppTheme.onSurfaceMuted.withValues(alpha: 0.15)
                : AppTheme.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isPast
                    ? AppTheme.onSurfaceMuted.withValues(alpha: 0.1)
                    : AppTheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(isPast ? '✅' : '📖',
                    style: const TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lesson.title,
                    style: AppTheme.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isPast
                          ? AppTheme.onSurfaceMuted
                          : AppTheme.onSurface,
                    ),
                  ),
                  if (lesson.subject.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(lesson.subject, style: AppTheme.bodyMedium),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded,
                          size: 13,
                          color: isPast
                              ? AppTheme.onSurfaceMuted
                              : AppTheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('yyyy/MM/dd  HH:mm')
                            .format(lesson.dateTime),
                        style: AppTheme.bodyMedium.copyWith(
                          fontSize: 12,
                          color: isPast
                              ? AppTheme.onSurfaceMuted
                              : AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (!isPast)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.notifications_active_outlined,
                        size: 13, color: AppTheme.primary),
                    const SizedBox(width: 4),
                    Text('${lesson.notifyMinutesBefore}خ',
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Small widgets ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(label,
          style: AppTheme.bodyMedium
              .copyWith(fontWeight: FontWeight.w600)),
    );
  }
}

class _PickerRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _PickerRow(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(14),
          border: const Border.fromBorderSide(
              BorderSide(color: Color(0xFF33334A))),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.onSurfaceMuted, size: 20),
            const SizedBox(width: 12),
            Text(label, style: AppTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
