import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme.dart';
import '../../../models/models.dart';
import '../../../services/firestore_service.dart';

class AddMemoryScreen extends StatefulWidget {
  final String coupleId;
  final String currentUserId;
  final MemoryModel? memory; // Null if creating, non-null if editing

  const AddMemoryScreen({
    super.key,
    required this.coupleId,
    required this.currentUserId,
    this.memory,
  });

  @override
  State<AddMemoryScreen> createState() => _AddMemoryScreenState();
}

class _AddMemoryScreenState extends State<AddMemoryScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.memory != null) {
      _titleController.text = widget.memory!.title;
      _descController.text = widget.memory!.description;
      _selectedDate = widget.memory!.date;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primary,
              onPrimary: Colors.white,
              surface: AppTheme.surface,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _saveMemory() async {
    final title = _titleController.text.trim();
    final desc = _descController.text.trim();
    if (title.isEmpty || desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تکایە ناونیشان و وەسف پڕبکەرەوە')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (widget.memory == null) {
        // Create new
        final memory = MemoryModel(
          id: '', 
          title: title,
          description: desc,
          date: _selectedDate,
          createdBy: widget.currentUserId,
          createdAt: DateTime.now(),
        );
        await FirestoreService().addMemory(widget.coupleId, memory);
      } else {
        // Update existing
        final updatedMemory = widget.memory!.copyWith(
          title: title,
          description: desc,
          date: _selectedDate,
        );
        await FirestoreService().updateMemory(widget.coupleId, widget.memory!.id, updatedMemory);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('هەڵەیەک ڕوویدا: $e')));
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(widget.memory == null ? 'زیادکردنی یادگاری' : 'دەستکاریکردنی یادگاری'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ناونیشان', style: AppTheme.bodyMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'نموونە: یەکەم بینینمان',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                filled: true,
                fillColor: AppTheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),

            Text('ڕۆژی یادگارییەکە', style: AppTheme.bodyMedium),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _selectDate,
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
                      DateFormat('yyyy/MM/dd').format(_selectedDate),
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    const Icon(Icons.calendar_today, color: AppTheme.primary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            Text('چیرۆکەکە / وەسف', style: AppTheme.bodyMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _descController,
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'چی ڕوویدا لەم ڕۆژەدا؟...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                filled: true,
                fillColor: AppTheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveMemory,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(widget.memory == null ? 'پاشکەوتکردن' : 'نوێکردنەوە', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
