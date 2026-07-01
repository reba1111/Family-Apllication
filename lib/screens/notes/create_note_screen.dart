import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme.dart';
import '../../../models/models.dart';
import '../../../services/firestore_service.dart';

class CreateNoteScreen extends StatefulWidget {
  final String coupleId;
  final String currentUserId;
  final NoteModel? note; // Null if creating, non-null if editing

  const CreateNoteScreen({
    super.key,
    required this.coupleId,
    required this.currentUserId,
    this.note,
  });

  @override
  State<CreateNoteScreen> createState() => _CreateNoteScreenState();
}

class _CreateNoteScreenState extends State<CreateNoteScreen> {
  final _contentController = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(hours: 1));
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.note != null) {
      _contentController.text = widget.note!.content;
      _selectedDate = widget.note!.unlockDate;
      _selectedTime = TimeOfDay.fromDateTime(widget.note!.unlockDate);
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppTheme.primary,
            surface: AppTheme.surface,
          ),
        ),
        child: child!,
      ),
    );

    if (pickedDate != null) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: _selectedTime,
        builder: (context, child) => Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primary,
              surface: AppTheme.surface,
            ),
          ),
          child: child!,
        ),
      );

      if (pickedTime != null) {
        setState(() {
          _selectedDate = pickedDate;
          _selectedTime = pickedTime;
        });
      }
    }
  }

  Future<void> _sendNote() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تکایە نامەیەک بنووسە')),
      );
      return;
    }

    final unlockDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    if (unlockDateTime.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('کاتی کرانەوە دەبێت لە داهاتوودا بێت')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (widget.note == null) {
        final note = NoteModel(
          id: '',
          content: content,
          createdBy: widget.currentUserId,
          unlockDate: unlockDateTime,
          createdAt: DateTime.now(),
        );
        await FirestoreService().addNote(widget.coupleId, note);
      } else {
        final updatedNote = widget.note!.copyWith(
          content: content,
          unlockDate: unlockDateTime,
        );
        await FirestoreService().updateNote(widget.coupleId, widget.note!.id, updatedNote);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('هەڵەیەک ڕوویدا: $e')));
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final unlockDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
    final dateFormat = DateFormat('yyyy/MM/dd - hh:mm a');

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(widget.note == null ? 'نووسینی نامەی شاردراوە' : 'دەستکاریکردنی نامە'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppTheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'ئەم نامەیە بە قفڵکراوی دەگاتە دەستی هاوسەرەکەت، وە تەنها لەو کاتەدا دەکرێتەوە کە تۆ دیاری دەکەیت.',
                      style: AppTheme.bodyMedium.copyWith(color: AppTheme.primary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Text('کاتی کرانەوەی نامەکە:', style: AppTheme.titleLarge),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _selectDateTime,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      dateFormat.format(unlockDateTime),
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    const Icon(Icons.timer, color: AppTheme.primary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            Text('ناوەڕۆکی نامەکە:', style: AppTheme.titleLarge),
            const SizedBox(height: 8),
            TextField(
              controller: _contentController,
              maxLines: 8,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'سوپاس بۆ ئەوەی کە هەمیشە پاڵپشتیم دەکەیت...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                filled: true,
                fillColor: AppTheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _sendNote,
                icon: _isLoading ? const SizedBox() : const Icon(Icons.send, color: Colors.white),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                label: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(widget.note == null ? 'ناردنی نامەکە 💌' : 'نوێکردنەوە 💌', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
