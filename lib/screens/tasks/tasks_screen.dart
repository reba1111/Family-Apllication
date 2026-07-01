import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../services/firestore_service.dart';
import '../../services/notification_service.dart';

class TasksScreen extends StatefulWidget {
  final String coupleId;
  final String currentUserId;
  final String partnerName;

  const TasksScreen({
    super.key,
    required this.coupleId,
    required this.currentUserId,
    this.partnerName = 'هاوسەر',
  });

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen>
    with SingleTickerProviderStateMixin {
  final _fs = FirestoreService();
  final _notif = NotificationService();
  late TabController _tab;
  String? _partnerId;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _loadPartner();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _loadPartner() async {
    final me = await _fs.getUser(widget.currentUserId);
    if (mounted) setState(() => _partnerId = me?.partnerId);
  }

  void _showAddEditDialog({TaskModel? editTask}) {
    final titleCtrl = TextEditingController(text: editTask?.title ?? '');
    final descCtrl = TextEditingController(text: editTask?.description ?? '');
    DateTime dueDate = editTask?.dueDate ?? DateTime.now().add(const Duration(days: 1));
    bool assignToPartner = editTask != null ? editTask.assignedTo != editTask.assignedBy : false;
    TaskPriority priority = editTask?.priority ?? TaskPriority.normal;

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
                Text(editTask == null ? 'تاسکی نوێ ✅' : 'دەستکاریکردنی تاسک ✅', style: AppTheme.headlineMedium),
                const SizedBox(height: 20),

                TextField(
                  controller: titleCtrl,
                  autofocus: true,
                  style: TextStyle(color: AppTheme.onSurface),
                  decoration: const InputDecoration(hintText: 'ناوی تاسک'),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: descCtrl,
                  style: TextStyle(color: AppTheme.onSurface),
                  maxLines: 2,
                  decoration: const InputDecoration(
                      hintText: 'وردەکاری (ئارەزووی)'),
                ),
                const SizedBox(height: 14),

                // Priority
                Text('گرنگی:', style: AppTheme.bodyMedium),
                const SizedBox(height: 8),
                Row(
                  children: TaskPriority.values.map((p) {
                    final selected = priority == p;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setModal(() => priority = p),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: selected
                                ? _priorityColor(p).withValues(alpha: 0.2)
                                : AppTheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selected
                                  ? _priorityColor(p)
                                  : const Color(0xFF33334A),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_priorityEmoji(p),
                                  style: const TextStyle(fontSize: 14)),
                              const SizedBox(width: 6),
                              Text(_priorityLabel(p),
                                  style: AppTheme.bodyMedium.copyWith(
                                    color: selected
                                        ? _priorityColor(p)
                                        : AppTheme.onSurfaceMuted,
                                    fontWeight: selected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  )),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

                // Due date
                GestureDetector(
                  onTap: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: dueDate,
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
                    if (d != null) setModal(() => dueDate = d);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(14),
                      border: const Border.fromBorderSide(
                          BorderSide(color: Color(0xFF33334A))),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined,
                            color: AppTheme.onSurfaceMuted, size: 20),
                        const SizedBox(width: 12),
                        Text(
                            'کاتی تواوبوون: ${DateFormat('yyyy/MM/dd').format(dueDate)}',
                            style: AppTheme.bodyMedium),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                if (_partnerId != null)
                  GestureDetector(
                    onTap: () =>
                        setModal(() => assignToPartner = !assignToPartner),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: assignToPartner
                            ? AppTheme.primary.withValues(alpha: 0.1)
                            : AppTheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: assignToPartner
                              ? AppTheme.primary
                              : const Color(0xFF33334A),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            assignToPartner
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: assignToPartner
                                ? AppTheme.primary
                                : AppTheme.onSurfaceMuted,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'بسپێرە بە ${widget.partnerName}',
                            style: AppTheme.bodyLarge.copyWith(
                              color: assignToPartner
                                  ? AppTheme.primary
                                  : AppTheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            if (titleCtrl.text.trim().isEmpty) return;
                            final uid = widget.currentUserId;
                            final assignedTo =
                                assignToPartner && _partnerId != null
                                    ? _partnerId!
                                    : uid;
                            final task = TaskModel(
                              id: editTask?.id ?? '',
                              title: titleCtrl.text.trim(),
                              description: descCtrl.text.trim(),
                              assignedTo: assignedTo,
                              assignedBy: editTask?.assignedBy ?? uid,
                              dueDate: dueDate,
                              createdAt: editTask?.createdAt ?? DateTime.now(),
                              priority: priority,
                              isDone: editTask?.isDone ?? false,
                            );
                            
                            String refId;
                            if (editTask != null) {
                              await _fs.updateTask(widget.coupleId, editTask.id, task.toFirestore());
                              refId = editTask.id;
                              if (editTask.assignedTo == uid) {
                                 await _notif.cancelTask(editTask.id);
                              }
                            } else {
                              refId = await _fs.addTask(widget.coupleId, task);
                            }
                            
                            // Schedule local notification only for my own tasks
                            if (assignedTo == uid) {
                              await _notif.scheduleTask(
                                taskId: refId,
                                title: task.title,
                                dueDate: dueDate,
                              );
                            }
                            if (ctx.mounted) Navigator.pop(ctx);
                          },
                          child: Text(editTask == null ? 'زیادکردن' : 'پاشەکەوتکردن'),
                        ),
                      ),
                      if (editTask != null) ...[
                        const SizedBox(width: 12),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: AppTheme.error),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: ctx,
                              builder: (c) => AlertDialog(
                                backgroundColor: AppTheme.surface,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                title: Text('سڕینەوە', style: AppTheme.titleLarge),
                                content: Text('دڵنیایت لە سڕینەوەی ئەم تاسکە؟', style: AppTheme.bodyLarge),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('نەخێر', style: TextStyle(color: AppTheme.onSurfaceMuted))),
                                  TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('بەڵێ، بسڕەوە', style: TextStyle(color: AppTheme.error))),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await _fs.deleteTask(widget.coupleId, editTask.id);
                              await _notif.cancelTask(editTask.id);
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
                child: Text('تاسکەکان ✅', style: AppTheme.headlineMedium),
              ),

              // Tab bar
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
                    Tab(text: '👤 تاسکەکانم'),
                    Tab(text: '💑 تاسکی هاوسەر'),
                  ],
                ),
              ),

              Expanded(
                child: StreamBuilder<List<TaskModel>>(
                  stream: _fs.streamTasks(widget.coupleId),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                            color: AppTheme.primary),
                      );
                    }
                    final all = snap.data ?? [];
                    final myTasks = all
                        .where((t) => t.assignedTo == widget.currentUserId)
                        .toList()
                      ..sort(_sortTasks);
                    final partnerTasks = all
                        .where((t) => t.assignedTo != widget.currentUserId)
                        .toList()
                      ..sort(_sortTasks);

                    return TabBarView(
                      controller: _tab,
                      children: [
                        _TaskListView(
                          tasks: myTasks,
                          coupleId: widget.coupleId,
                          canToggle: true,
                          canDelete: true,
                          fs: _fs,
                          notif: _notif,
                          onTap: (task) => _showAddEditDialog(editTask: task),
                        ),
                        _TaskListView(
                          tasks: partnerTasks,
                          coupleId: widget.coupleId,
                          canToggle: false,
                          canDelete: false,
                          fs: _fs,
                          notif: _notif,
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
        onPressed: () => _showAddEditDialog(),
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label:
            const Text('تاسکی نوێ', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  int _sortTasks(TaskModel a, TaskModel b) {
    if (a.isDone != b.isDone) return a.isDone ? 1 : -1;
    const order = [TaskPriority.high, TaskPriority.normal, TaskPriority.low];
    final pa = order.indexOf(a.priority);
    final pb = order.indexOf(b.priority);
    if (pa != pb) return pa.compareTo(pb);
    return a.dueDate.compareTo(b.dueDate);
  }
}

// ── Task list ────────────────────────────────────────────────────────────────

class _TaskListView extends StatelessWidget {
  final List<TaskModel> tasks;
  final String coupleId;
  final bool canToggle;
  final bool canDelete;
  final FirestoreService fs;
  final NotificationService notif;
  final void Function(TaskModel)? onTap;

  const _TaskListView({
    required this.tasks,
    required this.coupleId,
    required this.canToggle,
    required this.canDelete,
    required this.fs,
    required this.notif,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final pending = tasks.where((t) => !t.isDone).length;
    final done = tasks.where((t) => t.isDone).length;

    return Column(
      children: [
        // Stats bar
        if (tasks.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: Row(
              children: [
                _StatChip(
                    label: '$pending چاوەڕوانە',
                    color: AppTheme.primary),
                const SizedBox(width: 8),
                _StatChip(
                    label: '$done تەواوبوو',
                    color: AppTheme.success),
              ],
            ),
          ),

        Expanded(
          child: tasks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('✅', style: TextStyle(fontSize: 52)),
                      const SizedBox(height: 12),
                      Text('هیچ تاسکێک نییە',
                          style: AppTheme.bodyMedium),
                    ],
                  ),
                )
              : ListView.builder(
                  padding:
                      const EdgeInsets.fromLTRB(20, 8, 20, 100),
                  itemCount: tasks.length,
                  itemBuilder: (_, i) =>
                      _TaskCard(
                        task: tasks[i],
                        coupleId: coupleId,
                        canToggle: canToggle,
                        canDelete: canDelete,
                        fs: fs,
                        notif: notif,
                        onTap: onTap != null ? () => onTap!(tasks[i]) : null,
                      ),
                ),
        ),
      ],
    );
  }
}

class _TaskCard extends StatelessWidget {
  final TaskModel task;
  final String coupleId;
  final bool canToggle;
  final bool canDelete;
  final FirestoreService fs;
  final NotificationService notif;
  final void Function()? onTap;

  const _TaskCard({
    required this.task,
    required this.coupleId,
    required this.canToggle,
    required this.canDelete,
    required this.fs,
    required this.notif,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final overdue =
        !task.isDone && task.dueDate.isBefore(DateTime.now());
    final pColor = _priorityColor(task.priority);

    final card = GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: AppTheme.cardGradient,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: task.isDone
                ? AppTheme.success.withValues(alpha: 0.25)
                : overdue
                    ? AppTheme.error.withValues(alpha: 0.4)
                    : pColor.withValues(alpha: 0.3),
          ),
        ),
      child: Row(
        children: [
          // Priority stripe
          Container(
            width: 4,
            height: 48,
            decoration: BoxDecoration(
              color: task.isDone
                  ? AppTheme.success.withValues(alpha: 0.4)
                  : pColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),

          // Checkbox
          if (canToggle)
            GestureDetector(
              onTap: () => fs.toggleTask(coupleId, task.id, !task.isDone),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: task.isDone
                      ? AppTheme.success
                      : Colors.transparent,
                  border: Border.all(
                    color: task.isDone
                        ? AppTheme.success
                        : AppTheme.onSurfaceMuted,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: task.isDone
                    ? const Icon(Icons.check,
                        size: 16, color: Colors.white)
                    : null,
              ),
            )
          else
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: task.isDone
                    ? AppTheme.success.withValues(alpha: 0.3)
                    : Colors.transparent,
                border: Border.all(
                  color: AppTheme.onSurfaceMuted,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: task.isDone
                  ? const Icon(Icons.check,
                      size: 16, color: AppTheme.success)
                  : null,
            ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(_priorityEmoji(task.priority),
                        style: const TextStyle(fontSize: 13)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        task.title,
                        style: AppTheme.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          decoration: task.isDone
                              ? TextDecoration.lineThrough
                              : null,
                          color: task.isDone
                              ? AppTheme.onSurfaceMuted
                              : AppTheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
                if (task.description.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(task.description, style: AppTheme.bodyMedium),
                ],
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 12,
                      color: overdue
                          ? AppTheme.error
                          : AppTheme.onSurfaceMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('yyyy/MM/dd').format(task.dueDate),
                      style: AppTheme.bodyMedium.copyWith(
                        fontSize: 12,
                        color: overdue
                            ? AppTheme.error
                            : AppTheme.onSurfaceMuted,
                      ),
                    ),
                    if (overdue) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.error.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('تواوبووە!',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppTheme.error,
                              fontWeight: FontWeight.w600,
                            )),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ));

    if (!canDelete) return card;

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('سڕینەوە', style: AppTheme.titleLarge),
        content: Text('دڵنیایت لە سڕینەوەی ئەم تاسکە؟', style: AppTheme.bodyLarge),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('نەخێر', style: TextStyle(color: AppTheme.onSurfaceMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('بەڵێ، بسڕەوە', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }

    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) {
        fs.deleteTask(coupleId, task.id);
        notif.cancelTask(task.id);
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.error.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child:
            const Icon(Icons.delete_outline, color: AppTheme.error),
      ),
      child: card,
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: AppTheme.bodyMedium
              .copyWith(color: color, fontWeight: FontWeight.w600)),
    );
  }
}

Color _priorityColor(TaskPriority p) => switch (p) {
      TaskPriority.high => AppTheme.error,
      TaskPriority.normal => AppTheme.primary,
      TaskPriority.low => AppTheme.success,
    };

String _priorityEmoji(TaskPriority p) => switch (p) {
      TaskPriority.high => '🔴',
      TaskPriority.normal => '🟡',
      TaskPriority.low => '🟢',
    };

String _priorityLabel(TaskPriority p) => switch (p) {
      TaskPriority.high => 'زۆر گرنگ',
      TaskPriority.normal => 'ناوەند',
      TaskPriority.low => 'کەم گرنگ',
    };
