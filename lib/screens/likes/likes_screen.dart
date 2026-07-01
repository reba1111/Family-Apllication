import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';

class LikesScreen extends StatefulWidget {
  final String userId;
  final String partnerId;

  const LikesScreen({
    super.key,
    required this.userId,
    required this.partnerId,
  });

  @override
  State<LikesScreen> createState() => _LikesScreenState();
}

class _LikesScreenState extends State<LikesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _fs = FirestoreService();

  final List<String> _categories = ['خواردن', 'دیاری', 'گشتی'];

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

  List<String> _getAllCategories(UserModel me) {
    final cats = Set<String>.from(_categories);
    cats.addAll(me.likes.keys);
    cats.addAll(me.dislikes.keys);
    return cats.toList();
  }

  Future<void> _addItem(UserModel me, bool isLike,
      {String? editOldCat, String? editOldText, int? editIndex}) async {
    final allCategories = _getAllCategories(me);

    final result = await showModalBottomSheet<Map<String, String>?>(
      context: context,
      backgroundColor: AppTheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        String selectedCat = editOldCat ?? 'گشتی';
        final catCtrl = TextEditingController(text: selectedCat);
        final ctrl = TextEditingController(text: editOldText ?? '');
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    editOldText != null
                        ? (isLike
                            ? '❤️ دەستکاریکردنی حەز'
                            : '💔 دەستکاریکردنی ناحەز')
                        : (isLike ? '❤️ حەزێکی نوێ' : '💔 ناحەزێکی نوێ'),
                    style: AppTheme.headlineMedium,
                  ),
                  const SizedBox(height: 16),
                  Autocomplete<String>(
                    initialValue: TextEditingValue(text: selectedCat),
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return allCategories;
                      }
                      return allCategories.where((String option) {
                        return option.contains(textEditingValue.text);
                      });
                    },
                    onSelected: (String selection) {
                      selectedCat = selection;
                      catCtrl.text = selection;
                    },
                    fieldViewBuilder: (context, textEditingController,
                        focusNode, onFieldSubmitted) {
                      return TextField(
                        controller: textEditingController,
                        focusNode: focusNode,
                        style: const TextStyle(color: AppTheme.onSurface),
                        decoration: InputDecoration(
                          hintText: 'جۆر (بۆ نموونە: خواردن)',
                          suffixIcon: const Icon(Icons.arrow_drop_down,
                              color: AppTheme.onSurfaceMuted),
                        ),
                        onChanged: (v) => selectedCat = v,
                      );
                    },
                    optionsViewBuilder: (context, onSelected, options) {
                      return Align(
                        alignment: Alignment.topLeft,
                        child: Material(
                          elevation: 4.0,
                          color: AppTheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                                maxHeight: 200, maxWidth: 300),
                            child: ListView.builder(
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              itemCount: options.length,
                              itemBuilder: (BuildContext context, int index) {
                                final option = options.elementAt(index);
                                return InkWell(
                                  onTap: () => onSelected(option),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Text(option,
                                        style: const TextStyle(
                                            color: AppTheme.onSurface)),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: ctrl,
                    autofocus: editOldText == null,
                    style: const TextStyle(color: AppTheme.onSurface),
                    decoration: InputDecoration(
                      hintText: isLike
                          ? 'مەسەلا: پیتزا، مووزیک...'
                          : 'مەسەلا: ترافیک، تاریکی...',
                    ),
                    onSubmitted: (_) => Navigator.pop(ctx, {
                      'cat': selectedCat.isEmpty ? 'گشتی' : selectedCat,
                      'text': ctrl.text
                    }),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, {
                            'cat': selectedCat.isEmpty ? 'گشتی' : selectedCat,
                            'text': ctrl.text
                          }),
                          child: Text(editOldText != null
                              ? 'پاشەکەوتکردن'
                              : 'زیادکردن'),
                        ),
                      ),
                      if (editOldText != null) ...[
                        const SizedBox(width: 12),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: AppTheme.error),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: ctx,
                              builder: (c) => AlertDialog(
                                backgroundColor: AppTheme.surface,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20)),
                                title:
                                    Text('سڕینەوە', style: AppTheme.titleLarge),
                                content: Text('دڵنیایت لە سڕینەوەی ئەمە؟',
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
                                          style: TextStyle(
                                              color: AppTheme.error))),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              Navigator.pop(ctx, {
                                'action': 'delete',
                                'cat': editOldCat ?? '',
                                'text': editOldText
                              });
                            }
                          },
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (result != null) {
      final newLikes = Map<String, List<String>>.from(
          me.likes.map((k, v) => MapEntry(k, List<String>.from(v))));
      final newDislikes = Map<String, List<String>>.from(
          me.dislikes.map((k, v) => MapEntry(k, List<String>.from(v))));

      if (result['action'] == 'delete') {
        if (isLike) {
          if (editOldCat != null && editIndex != null) {
            newLikes[editOldCat]?.removeAt(editIndex);
            if (newLikes[editOldCat]?.isEmpty ?? false)
              newLikes.remove(editOldCat);
          }
        } else {
          if (editOldCat != null && editIndex != null) {
            newDislikes[editOldCat]?.removeAt(editIndex);
            if (newDislikes[editOldCat]?.isEmpty ?? false)
              newDislikes.remove(editOldCat);
          }
        }
      } else if (result['text'] != null && result['text']!.trim().isNotEmpty) {
        final cat = result['cat']!;
        final text = result['text']!.trim();

        if (isLike) {
          if (editOldCat != null && editIndex != null) {
            newLikes[editOldCat]?.removeAt(editIndex);
            if (newLikes[editOldCat]?.isEmpty ?? false)
              newLikes.remove(editOldCat);
          }
          newLikes[cat] = [...(newLikes[cat] ?? []), text];
        } else {
          if (editOldCat != null && editIndex != null) {
            newDislikes[editOldCat]?.removeAt(editIndex);
            if (newDislikes[editOldCat]?.isEmpty ?? false)
              newDislikes.remove(editOldCat);
          }
          newDislikes[cat] = [...(newDislikes[cat] ?? []), text];
        }
      } else {
        return;
      }

      await _fs.updateLikesDislikes(
        uid: widget.userId,
        likes: newLikes,
        dislikes: newDislikes,
      );
    }
  }

  Future<void> _removeItem(
      UserModel me, bool isLike, String category, int index) async {
    final newLikes = Map<String, List<String>>.from(
        me.likes.map((k, v) => MapEntry(k, List<String>.from(v))));
    final newDislikes = Map<String, List<String>>.from(
        me.dislikes.map((k, v) => MapEntry(k, List<String>.from(v))));

    if (isLike) {
      newLikes[category]?.removeAt(index);
      if (newLikes[category]?.isEmpty ?? false) newLikes.remove(category);
    } else {
      newDislikes[category]?.removeAt(index);
      if (newDislikes[category]?.isEmpty ?? false) newDislikes.remove(category);
    }

    await _fs.updateLikesDislikes(
      uid: widget.userId,
      likes: newLikes,
      dislikes: newDislikes,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              // AppBar
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 12, 20, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new,
                          color: AppTheme.onSurface),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text('حەز و ناحەزەکان', style: AppTheme.headlineMedium),
                  ],
                ),
              ),

              // TabBar
              Container(
                margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
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
                    Tab(text: '👤 لیستی من'),
                    Tab(text: '💑 لیستی هاوسەر'),
                  ],
                ),
              ),
              const SizedBox(height: 4),

              Expanded(
                child: TabBarView(
                  controller: _tab,
                  children: [
                    // ── My List (editable, real-time) ──
                    StreamBuilder<UserModel?>(
                      stream: _fs.streamUser(widget.userId),
                      builder: (context, snap) {
                        if (snap.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                                color: AppTheme.primary),
                          );
                        }
                        final me = snap.data;
                        if (me == null) return const SizedBox();
                        return _MyListView(
                          me: me,
                          onAdd: (isLike,
                                  {editOldCat, editOldText, editIndex}) =>
                              _addItem(me, isLike,
                                  editOldCat: editOldCat,
                                  editOldText: editOldText,
                                  editIndex: editIndex),
                          onRemove: (isLike, cat, i) =>
                              _removeItem(me, isLike, cat, i),
                        );
                      },
                    ),

                    // ── Partner's List (read-only, real-time) ──
                    widget.partnerId.isEmpty
                        ? Center(
                            child: Text(
                              'هێشتا هاوسەرەکەت نەبەستراوەتەوە',
                              style: AppTheme.bodyLarge,
                            ),
                          )
                        : StreamBuilder<UserModel?>(
                            stream: _fs.streamUser(widget.partnerId),
                            builder: (context, snap) {
                              if (snap.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(
                                      color: AppTheme.primary),
                                );
                              }
                              final partner = snap.data;
                              if (partner == null) return const SizedBox();
                              return _PartnerListView(partner: partner);
                            },
                          ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── My editable list ──────────────────────────────────────────────────────────

class _MyListView extends StatelessWidget {
  final UserModel me;
  final void Function(bool isLike,
      {String? editOldCat, String? editOldText, int? editIndex}) onAdd;
  final void Function(bool isLike, String category, int index) onRemove;

  const _MyListView({
    required this.me,
    required this.onAdd,
    required this.onRemove,
  });

  List<Widget> _buildCategorizedItems(
      Map<String, List<String>> items, bool isLike, Color color) {
    if (items.isEmpty) {
      return [const SliverToBoxAdapter(child: _EmptyHint())];
    }

    final slivers = <Widget>[];
    for (final entry in items.entries) {
      if (entry.value.isEmpty) continue;

      // Category Header
      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Text(
              entry.key,
              style:
                  AppTheme.bodyLarge.copyWith(color: AppTheme.onSurfaceMuted),
            ),
          ),
        ),
      );

      // Category Items
      slivers.add(
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (_, i) => GestureDetector(
              onTap: () => onAdd(isLike,
                  editOldCat: entry.key,
                  editOldText: entry.value[i],
                  editIndex: i),
              child: _EditableItem(
                text: entry.value[i],
                color: color,
                onRemove: () => onRemove(isLike, entry.key, i),
              ),
            ),
            childCount: entry.value.length,
          ),
        ),
      );
    }
    return slivers;
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // Likes section
        SliverToBoxAdapter(
          child: _SectionHeader(
            emoji: '❤️',
            title: 'حەزەکانم',
            color: AppTheme.primary,
            onAdd: () => onAdd(true),
          ),
        ),
        ..._buildCategorizedItems(me.likes, true, AppTheme.primary),

        // Dislikes section
        SliverToBoxAdapter(
          child: _SectionHeader(
            emoji: '💔',
            title: 'ناحەزەکانم',
            color: AppTheme.error,
            onAdd: () => onAdd(false),
          ),
        ),
        ..._buildCategorizedItems(me.dislikes, false, AppTheme.error),

        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }
}

// ── Partner's read-only list ──────────────────────────────────────────────────

class _PartnerListView extends StatelessWidget {
  final UserModel partner;

  const _PartnerListView({required this.partner});

  List<Widget> _buildCategorizedItems(
      Map<String, List<String>> items, Color color) {
    if (items.isEmpty) {
      return [const SliverToBoxAdapter(child: _EmptyHint())];
    }

    final slivers = <Widget>[];
    for (final entry in items.entries) {
      if (entry.value.isEmpty) continue;

      // Category Header
      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Text(
              entry.key,
              style:
                  AppTheme.bodyLarge.copyWith(color: AppTheme.onSurfaceMuted),
            ),
          ),
        ),
      );

      // Category Items
      slivers.add(
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (_, i) => _ReadOnlyItem(
              text: entry.value[i],
              color: color,
            ),
            childCount: entry.value.length,
          ),
        ),
      );
    }
    return slivers;
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                      child: Text('💑', style: TextStyle(fontSize: 18))),
                ),
                const SizedBox(width: 10),
                Text(partner.displayName, style: AppTheme.titleLarge),
              ],
            ),
          ),
        ),

        // Partner Likes
        SliverToBoxAdapter(
          child: _SectionHeader(
            emoji: '❤️',
            title: 'حەزەکانی',
            color: AppTheme.primary,
          ),
        ),
        ..._buildCategorizedItems(partner.likes, AppTheme.primary),

        // Partner Dislikes
        SliverToBoxAdapter(
          child: _SectionHeader(
            emoji: '💔',
            title: 'ناحەزەکانی',
            color: AppTheme.error,
          ),
        ),
        ..._buildCategorizedItems(partner.dislikes, AppTheme.error),

        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }
}

// ── Shared small widgets ──────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String emoji;
  final String title;
  final Color color;
  final VoidCallback? onAdd;

  const _SectionHeader({
    required this.emoji,
    required this.title,
    required this.color,
    this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Text(title, style: AppTheme.titleLarge.copyWith(color: color)),
          const Spacer(),
          if (onAdd != null)
            GestureDetector(
              onTap: onAdd,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 16, color: color),
                    const SizedBox(width: 4),
                    Text('زیادکردن',
                        style: AppTheme.bodyMedium.copyWith(color: color)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EditableItem extends StatelessWidget {
  final String text;
  final Color color;
  final VoidCallback onRemove;

  const _EditableItem({
    required this.text,
    required this.color,
    required this.onRemove,
  });

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('سڕینەوە', style: AppTheme.titleLarge),
        content: Text('دڵنیایت لە سڕینەوەی ئەمە؟', style: AppTheme.bodyLarge),
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
    return Dismissible(
      key: ValueKey(text),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) => onRemove(),
      background: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppTheme.error.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline, color: AppTheme.error),
      ),
      child: _ItemCard(text: text, color: color),
    );
  }
}

class _ReadOnlyItem extends StatelessWidget {
  final String text;
  final Color color;

  const _ReadOnlyItem({required this.text, required this.color});

  @override
  Widget build(BuildContext context) => _ItemCard(text: text, color: color);
}

class _ItemCard extends StatelessWidget {
  final String text;
  final Color color;

  const _ItemCard({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: AppTheme.bodyLarge)),
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Text('هێشتا هیچی نەزیادکراوە', style: AppTheme.bodyMedium),
    );
  }
}
