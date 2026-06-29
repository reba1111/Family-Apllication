import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../services/firestore_service.dart';

class FamilyScreen extends StatefulWidget {
  final String coupleId;
  const FamilyScreen({super.key, required this.coupleId});

  @override
  State<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends State<FamilyScreen> {
  final _fs = FirestoreService();

  void _showAddDialog() {
    final nameCtrl = TextEditingController();
    final relationCtrl = TextEditingController();
    DateTime? birthday;

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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('زیادکردنی ئەندامی خێزان',
                  style: AppTheme.headlineMedium),
              const SizedBox(height: 20),
              TextField(
                controller: nameCtrl,
                style: TextStyle(color: AppTheme.onSurface),
                decoration: const InputDecoration(hintText: 'ناو'),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: relationCtrl,
                style: TextStyle(color: AppTheme.onSurface),
                decoration: const InputDecoration(
                    hintText: 'پەیوەندی (دایک، باوک، براکە...)'),
              ),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: DateTime(1990),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                    builder: (_, child) => Theme(
                      data: ThemeData.dark().copyWith(
                        colorScheme: const ColorScheme.dark(
                          primary: AppTheme.primary,
                        ),
                      ),
                      child: child!,
                    ),
                  );
                  if (picked != null) setModal(() => birthday = picked);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF33334A)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.cake_outlined,
                          color: AppTheme.onSurfaceMuted),
                      const SizedBox(width: 12),
                      Text(
                        birthday != null
                            ? DateFormat('yyyy/MM/dd').format(birthday!)
                            : 'بەرواری لەدایکبوون (ئارەزووی)',
                        style: AppTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  if (nameCtrl.text.trim().isEmpty) return;
                  final member = FamilyMember(
                    id: '',
                    name: nameCtrl.text.trim(),
                    relation: relationCtrl.text.trim(),
                    birthday: birthday,
                    addedBy:
                        FirebaseAuth.instance.currentUser?.uid ?? '',
                  );
                  await _fs.addFamilyMember(widget.coupleId, member);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('زیادکردن'),
              ),
            ],
          ),
        ),
      ),
    );
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
              // App bar
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 12, 20, 16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new,
                          color: AppTheme.onSurface),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text('ئەندامانی خێزان',
                        style: AppTheme.headlineMedium),
                  ],
                ),
              ),

              Expanded(
                child: StreamBuilder<List<FamilyMember>>(
                  stream: _fs.streamFamily(widget.coupleId),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                            color: AppTheme.primary),
                      );
                    }
                    final members = snap.data ?? [];

                    if (members.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('👨‍👩‍👧',
                                style: TextStyle(fontSize: 56)),
                            const SizedBox(height: 12),
                            Text('هێشتا هیچ ئەندامێک نەزیادکراوە',
                                style: AppTheme.bodyMedium),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      itemCount: members.length,
                      itemBuilder: (_, i) {
                        final m = members[i];
                        final bday = m.birthday != null
                            ? DateFormat('yyyy/MM/dd').format(m.birthday!)
                            : null;
                        return Dismissible(
                          key: ValueKey(m.id),
                          direction: DismissDirection.endToStart,
                          onDismissed: (_) =>
                              _fs.deleteFamilyMember(widget.coupleId, m.id),
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: AppTheme.error.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.delete_outline,
                                color: AppTheme.error),
                          ),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: AppTheme.cardGradient,
                              borderRadius: BorderRadius.circular(16),
                              border: const Border.fromBorderSide(
                                BorderSide(color: Color(0xFF2A2A40)),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color:
                                        AppTheme.primary.withOpacity(0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      m.name[0].toUpperCase(),
                                      style: AppTheme.titleLarge.copyWith(
                                          color: AppTheme.primary),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(m.name,
                                          style: AppTheme.bodyLarge
                                              .copyWith(
                                                  fontWeight:
                                                      FontWeight.w600)),
                                      const SizedBox(height: 2),
                                      Text(m.relation,
                                          style: AppTheme.bodyMedium),
                                      if (bday != null) ...[
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            const Icon(Icons.cake_outlined,
                                                size: 13,
                                                color:
                                                    AppTheme.onSurfaceMuted),
                                            const SizedBox(width: 4),
                                            Text(bday,
                                                style: AppTheme.bodyMedium
                                                    .copyWith(fontSize: 12)),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
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
        icon: const Icon(Icons.person_add_outlined, color: Colors.white),
        label: const Text('زیادکردن',
            style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
