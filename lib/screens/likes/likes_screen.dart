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

  Future<void> _addItem(UserModel me, bool isLike) async {
    final ctrl = TextEditingController();
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppTheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isLike ? '❤️ حەزێکی نوێ' : '💔 ناحەزێکی نوێ',
              style: AppTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              autofocus: true,
              style: TextStyle(color: AppTheme.onSurface),
              decoration: InputDecoration(
                hintText: isLike ? 'مەسەلا: پیتزا، مووزیک...' : 'مەسەلا: ترافیک، تاریکی...',
              ),
              onSubmitted: (_) => Navigator.pop(ctx, true),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('زیادکردن'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && ctrl.text.trim().isNotEmpty) {
      final newLikes = List<String>.from(me.likes);
      final newDislikes = List<String>.from(me.dislikes);
      if (isLike) {
        newLikes.add(ctrl.text.trim());
      } else {
        newDislikes.add(ctrl.text.trim());
      }
      await _fs.updateLikesDislikes(
        uid: widget.userId,
        likes: newLikes,
        dislikes: newDislikes,
      );
    }
  }

  Future<void> _removeItem(UserModel me, bool isLike, int index) async {
    final newLikes = List<String>.from(me.likes);
    final newDislikes = List<String>.from(me.dislikes);
    if (isLike) {
      newLikes.removeAt(index);
    } else {
      newDislikes.removeAt(index);
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
                          onAdd: (isLike) => _addItem(me, isLike),
                          onRemove: (isLike, i) => _removeItem(me, isLike, i),
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
  final void Function(bool isLike) onAdd;
  final void Function(bool isLike, int index) onRemove;

  const _MyListView({
    required this.me,
    required this.onAdd,
    required this.onRemove,
  });

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
        me.likes.isEmpty
            ? const SliverToBoxAdapter(child: _EmptyHint())
            : SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _EditableItem(
                    text: me.likes[i],
                    color: AppTheme.primary,
                    onRemove: () => onRemove(true, i),
                  ),
                  childCount: me.likes.length,
                ),
              ),

        // Dislikes section
        SliverToBoxAdapter(
          child: _SectionHeader(
            emoji: '💔',
            title: 'ناحەزەکانم',
            color: AppTheme.error,
            onAdd: () => onAdd(false),
          ),
        ),
        me.dislikes.isEmpty
            ? const SliverToBoxAdapter(child: _EmptyHint())
            : SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _EditableItem(
                    text: me.dislikes[i],
                    color: AppTheme.error,
                    onRemove: () => onRemove(false, i),
                  ),
                  childCount: me.dislikes.length,
                ),
              ),

        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }
}

// ── Partner's read-only list ──────────────────────────────────────────────────

class _PartnerListView extends StatelessWidget {
  final UserModel partner;

  const _PartnerListView({required this.partner});

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
                  decoration: BoxDecoration(
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
        partner.likes.isEmpty
            ? const SliverToBoxAdapter(child: _EmptyHint())
            : SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _ReadOnlyItem(
                    text: partner.likes[i],
                    color: AppTheme.primary,
                  ),
                  childCount: partner.likes.length,
                ),
              ),

        // Partner Dislikes
        SliverToBoxAdapter(
          child: _SectionHeader(
            emoji: '💔',
            title: 'ناحەزەکانی',
            color: AppTheme.error,
          ),
        ),
        partner.dislikes.isEmpty
            ? const SliverToBoxAdapter(child: _EmptyHint())
            : SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _ReadOnlyItem(
                    text: partner.dislikes[i],
                    color: AppTheme.error,
                  ),
                  childCount: partner.dislikes.length,
                ),
              ),

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
          Text(title,
              style: AppTheme.titleLarge.copyWith(color: color)),
          const Spacer(),
          if (onAdd != null)
            GestureDetector(
              onTap: onAdd,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withOpacity(0.3)),
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

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(text),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onRemove(),
      background: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppTheme.error.withOpacity(0.15),
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
        border: Border.all(color: color.withOpacity(0.25)),
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
      child: Text('هێشتا هیچی نەزیادکراوە',
          style: AppTheme.bodyMedium),
    );
  }
}
