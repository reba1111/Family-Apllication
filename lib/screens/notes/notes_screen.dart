import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme.dart';
import '../../../models/models.dart';
import '../../../models/user_model.dart';
import '../../../services/firestore_service.dart';
import 'create_note_screen.dart';

class NotesScreen extends StatelessWidget {
  final UserModel me;

  const NotesScreen({super.key, required this.me});

  @override
  Widget build(BuildContext context) {
    if (me.coupleId == null) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(title: const Text('نامە شاردراوەکان')),
        body: const Center(child: Text('هێشتا هاوسەرەکەت بەستراو نییە')),
      );
    }

    final fs = FirestoreService();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('نامە شاردراوەکان 💌'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<List<NoteModel>>(
        stream: fs.streamNotes(me.coupleId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
          }
          if (snapshot.hasError) {
            return Center(child: Text('کێشەیەک هەیە: ${snapshot.error}'));
          }
          final notes = snapshot.data ?? [];

          if (notes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('📬', style: TextStyle(fontSize: 64)),
                  const SizedBox(height: 16),
                  Text('سندوقی نامەکان بەتاڵە', style: AppTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text('یەکەم نامەی شاردراوە بنێرە!', style: AppTheme.bodyMedium),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              return _NoteCard(note: note, currentUserId: me.uid, coupleId: me.coupleId!, fs: fs);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CreateNoteScreen(coupleId: me.coupleId!, currentUserId: me.uid),
            ),
          );
        },
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.edit, color: Colors.white),
        label: const Text('نووسین', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final NoteModel note;
  final String currentUserId;
  final String coupleId;
  final FirestoreService fs;

  const _NoteCard({
    required this.note,
    required this.currentUserId,
    required this.coupleId,
    required this.fs,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isLocked = note.unlockDate.isAfter(now);
    final amSender = note.createdBy == currentUserId;
    final dateFormat = DateFormat('yyyy/MM/dd - hh:mm a');

    if (isLocked) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3), width: 1.5),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Icon(Icons.lock_clock, size: 40, color: AppTheme.primary),
                if (amSender)
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: AppTheme.primary),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => CreateNoteScreen(
                              coupleId: coupleId,
                              currentUserId: currentUserId,
                              note: note,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        onPressed: () => _confirmDelete(context),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text('نامەیەکی شاردراوە 💌', style: AppTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              amSender ? 'تۆ ئەم نامەیەت ناردووە' : 'هاوسەرەکەت ئەم نامەیەی بۆ ناردوویت',
              style: AppTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'دەکرێتەوە لە: ${dateFormat.format(note.unlockDate)}',
                style: AppTheme.bodyMedium.copyWith(color: AppTheme.primary, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    }

    // Unlocked
    if (!note.isRead && !amSender) {
      // Mark as read if I am the receiver and it's unlocked
      fs.markNoteAsRead(coupleId, note.id);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2A2A40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.mark_email_read, color: AppTheme.success, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  amSender ? 'نامەکەت بۆ هاوسەرەکەت' : 'نامەیەک لە هاوسەرەکەتەوە',
                  style: AppTheme.titleLarge.copyWith(fontSize: 16),
                ),
              ),
              if (amSender)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                  onPressed: () => _confirmDelete(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                )
              else
                Text(
                  DateFormat('MM/dd').format(note.createdAt),
                  style: AppTheme.bodyMedium.copyWith(fontSize: 12),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(note.content, style: AppTheme.bodyLarge.copyWith(height: 1.6)),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('سڕینەوەی نامە', style: TextStyle(color: Colors.white)),
        content: const Text('دڵنیایت دەتەوێت ئەم نامەیە بسڕیتەوە؟', style: TextStyle(color: Colors.white70)),
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
      await fs.deleteNote(coupleId, note.id);
    }
  }
}
