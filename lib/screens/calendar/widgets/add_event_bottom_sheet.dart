import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme.dart';
import '../../../models/models.dart';
import '../../../services/firestore_service.dart';
import '../../../models/user_model.dart';

class AddEventBottomSheet extends StatefulWidget {
  final String coupleId;
  const AddEventBottomSheet({super.key, required this.coupleId});

  @override
  State<AddEventBottomSheet> createState() => _AddEventBottomSheetState();
}

class _AddEventBottomSheetState extends State<AddEventBottomSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String _selectedType = 'other';
  bool _notify = true;
  bool _loading = false;

  final Map<String, String> _types = {
    'anniversary': 'يادی هاوسەرگیری 💍',
    'birthday': 'لەدایکبوون 🎂',
    'appointment': 'پزیشک / چاوپێکەوتن 🏥',
    'trip': 'گەشت ✈️',
    'other': 'بۆنەی تر 📅',
  };

  final Map<String, String> _icons = {
    'anniversary': '💍',
    'birthday': '🎂',
    'appointment': '🏥',
    'trip': '✈️',
    'other': '📅',
  };

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (time != null) {
      setState(() => _selectedTime = time);
    }
  }

  Future<void> _saveEvent() async {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تکایە ناوی بۆنەکە بنووسە')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final finalDate = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final event = EventModel(
        id: '',
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        date: finalDate,
        type: _selectedType,
        icon: _icons[_selectedType]!,
        notify: _notify,
        createdBy: uid,
        createdAt: DateTime.now(),
      );

      await FirestoreService().addEvent(widget.coupleId, event);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('هەڵەیەک ڕوویدا: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('بۆنەی نوێ 📅', style: AppTheme.headlineMedium),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Title
              TextField(
                controller: _titleCtrl,
                style: const TextStyle(color: AppTheme.onSurface),
                decoration: const InputDecoration(
                  hintText: 'ناوی بۆنەکە...',
                  prefixIcon: Icon(Icons.edit_outlined),
                ),
              ),
              const SizedBox(height: 16),

              // Type Selector
              DropdownButtonFormField<String>(
                value: _selectedType,
                dropdownColor: AppTheme.surfaceVariant,
                style: const TextStyle(color: AppTheme.onSurface, fontFamily: 'Rabar'),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: _types.entries.map((e) {
                  return DropdownMenuItem(
                    value: e.key,
                    child: Text(e.value),
                  );
                }).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedType = v);
                },
              ),
              const SizedBox(height: 16),

              // Date & Time
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _pickDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF33334A)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.calendar_today_outlined, color: AppTheme.primary, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              DateFormat('yyyy/MM/dd').format(_selectedDate),
                              style: AppTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: _pickTime,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF33334A)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.access_time_outlined, color: AppTheme.accent, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              _selectedTime.format(context),
                              style: AppTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Notification Toggle
              SwitchListTile(
                value: _notify,
                onChanged: (v) => setState(() => _notify = v),
                title: const Text('ئاگادارکردنەوەی هاوسەر', style: TextStyle(color: AppTheme.onSurface)),
                activeColor: AppTheme.primary,
                contentPadding: EdgeInsets.zero,
              ),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _saveEvent,
                  child: _loading
                      ? const CircularProgressIndicator()
                      : const Text('پاشکەوتکردن'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
