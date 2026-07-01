import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme.dart';
import '../../../models/models.dart';
import '../../../models/user_model.dart';
import '../../../services/firestore_service.dart';
import 'add_memory_screen.dart';

class MemoriesScreen extends StatelessWidget {
  final UserModel me;

  const MemoriesScreen({super.key, required this.me});

  @override
  Widget build(BuildContext context) {
    if (me.coupleId == null) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(title: const Text('یادگارییەکان')),
        body: const Center(child: Text('هێشتا هاوسەرەکەت بەستراو نییە')),
      );
    }

    final fs = FirestoreService();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('ئەلبوومی یادگارییەکان'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<List<MemoryModel>>(
        stream: fs.streamMemories(me.coupleId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
          }
          if (snapshot.hasError) {
            return Center(child: Text('کێشەیەک هەیە: ${snapshot.error}'));
          }
          final memories = snapshot.data ?? [];

          if (memories.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('📸', style: TextStyle(fontSize: 64)),
                  const SizedBox(height: 16),
                  Text('هێشتا هیچ یادگارییەک نییە', style: AppTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text('یەکەم یادگاریتان تۆمار بکەن!', style: AppTheme.bodyMedium),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: memories.length,
            itemBuilder: (context, index) {
              final memory = memories[index];
              return _MemoryCard(memory: memory, me: me, fs: fs);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AddMemoryScreen(coupleId: me.coupleId!, currentUserId: me.uid),
            ),
          );
        },
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('یادگاری نوێ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _MemoryCard extends StatelessWidget {
  final MemoryModel memory;
  final UserModel me;
  final FirestoreService fs;

  const _MemoryCard({required this.memory, required this.me, required this.fs});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy/MM/dd');

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2A2A40)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(memory.title, style: AppTheme.titleLarge)),
                    if (memory.createdBy == me.uid) ...[
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: AppTheme.primary),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AddMemoryScreen(
                              coupleId: me.coupleId!,
                              currentUserId: me.uid,
                              memory: memory,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        onPressed: () => _confirmDelete(context),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  dateFormat.format(memory.date),
                  style: AppTheme.bodyMedium.copyWith(color: AppTheme.primary, fontSize: 12),
                ),
                const SizedBox(height: 12),
                Text(memory.description, style: AppTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('سڕینەوەی یادگاری', style: TextStyle(color: Colors.white)),
        content: const Text('دڵنیایت دەتەوێت ئەم یادگارییە بسڕیتەوە؟', style: TextStyle(color: Colors.white70)),
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
      await fs.deleteMemory(me.coupleId!, memory.id);
    }
  }
}
