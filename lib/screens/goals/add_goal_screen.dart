import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../services/firestore_service.dart';

class AddGoalScreen extends StatefulWidget {
  final String coupleId;
  final String currentUserId;
  final GoalModel? goal;

  const AddGoalScreen({
    super.key,
    required this.coupleId,
    required this.currentUserId,
    this.goal,
  });

  @override
  State<AddGoalScreen> createState() => _AddGoalScreenState();
}

class _AddGoalScreenState extends State<AddGoalScreen> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _currentAmountController = TextEditingController(text: '0');
  final _iconController = TextEditingController(text: '🎯');
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 30));
  bool _isLoading = false;

  String _selectedCurrency = '\$';

  @override
  void initState() {
    super.initState();
    if (widget.goal != null) {
      _titleController.text = widget.goal!.title;
      _amountController.text = widget.goal!.targetAmount.toString();
      _currentAmountController.text = widget.goal!.currentAmount.toString();
      _iconController.text = widget.goal!.icon;
      _selectedDate = widget.goal!.targetDate;
      _selectedCurrency = widget.goal!.currency;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _currentAmountController.dispose();
    _iconController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
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
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _saveGoal() async {
    final title = _titleController.text.trim();
    final amountText = _amountController.text.trim();
    final currentAmountText = _currentAmountController.text.trim();
    final icon = _iconController.text.trim();

    if (title.isEmpty || amountText.isEmpty || icon.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تکایە هەموو زانیارییەکان پڕبکەرەوە')),
      );
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تکایە بڕێکی دروست بنووسە بۆ ئامانجەکە')),
      );
      return;
    }

    final currentAmount = double.tryParse(currentAmountText) ?? 0.0;

    setState(() => _isLoading = true);

    try {
      if (widget.goal == null) {
        final goal = GoalModel(
          id: '',
          title: title,
          targetAmount: amount,
          currentAmount: currentAmount,
          icon: icon,
          targetDate: _selectedDate,
          currency: _selectedCurrency,
          createdBy: widget.currentUserId,
          createdAt: DateTime.now(),
        );
        await FirestoreService().addGoal(widget.coupleId, goal);
      } else {
        final updatedGoal = widget.goal!.copyWith(
          title: title,
          targetAmount: amount,
          currentAmount: currentAmount,
          icon: icon,
          targetDate: _selectedDate,
          currency: _selectedCurrency,
        );
        await FirestoreService().updateGoal(widget.coupleId, widget.goal!.id, updatedGoal);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('هەڵەیەک ڕوویدا: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(widget.goal == null ? 'ئامانجێکی نوێ' : 'دەستکاریکردنی ئامانج'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: _iconController,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 32),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppTheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      hintText: '🎯',
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ناونیشانی ئامانج', style: AppTheme.bodyMedium),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _titleController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'نموونە: کڕینی ئۆتۆمبێل',
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                          filled: true,
                          fillColor: AppTheme.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('بڕی پارەی پێویست', style: AppTheme.bodyMedium),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _selectedCurrency = '\$'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: _selectedCurrency == '\$' ? AppTheme.primary : AppTheme.surface,
                          borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                          border: Border.all(color: AppTheme.primary),
                        ),
                        child: Text('\$', style: TextStyle(color: _selectedCurrency == '\$' ? Colors.white : AppTheme.primary, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _selectedCurrency = 'IQD'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: _selectedCurrency == 'IQD' ? AppTheme.primary : AppTheme.surface,
                          borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
                          border: Border.all(color: AppTheme.primary),
                        ),
                        child: Text('دینار', style: TextStyle(color: _selectedCurrency == 'IQD' ? Colors.white : AppTheme.primary, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white, fontSize: 20),
              decoration: InputDecoration(
                prefixText: '$_selectedCurrency ',
                prefixStyle: const TextStyle(color: AppTheme.primary, fontSize: 20, fontWeight: FontWeight.bold),
                hintText: '1000',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                filled: true,
                fillColor: AppTheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),

            if (widget.goal != null) ...[
              Text('کۆکراوەی ئێستا', style: AppTheme.bodyMedium),
              const SizedBox(height: 8),
              TextField(
                controller: _currentAmountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white, fontSize: 20),
                decoration: InputDecoration(
                  prefixText: '$_selectedCurrency ',
                  prefixStyle: const TextStyle(color: AppTheme.success, fontSize: 20, fontWeight: FontWeight.bold),
                  hintText: '500',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                  filled: true,
                  fillColor: AppTheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            Text('بەرواری ئامانجەکە', style: AppTheme.bodyMedium),
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
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveGoal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(widget.goal == null ? 'پاشکەوتکردن' : 'نوێکردنەوە', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
