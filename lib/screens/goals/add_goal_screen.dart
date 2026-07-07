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
  
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 30));
  bool _isLoading = false;
  String _selectedCurrency = '\$';
  String _selectedIcon = '🎯';

  // Popular icons to choose from
  final List<String> _popularIcons = [
    '🎯', '🚗', '✈️', '🏡', '💍', 
    '👶', '🎓', '📱', '💻', '🎮',
    '👗', '🎉', '🏥', '🏖️', '🎁'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.goal != null) {
      _titleController.text = widget.goal!.title;
      _amountController.text = widget.goal!.targetAmount.toString();
      _currentAmountController.text = widget.goal!.currentAmount.toString();
      _selectedIcon = widget.goal!.icon;
      if (!_popularIcons.contains(_selectedIcon)) {
        _popularIcons.insert(0, _selectedIcon);
      }
      _selectedDate = widget.goal!.targetDate;
      _selectedCurrency = widget.goal!.currency;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _currentAmountController.dispose();
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
            onSurface: Colors.white,
          ),
          dialogBackgroundColor: const Color(0xFF1E1E2E),
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
    String amountText = _amountController.text.trim().replaceAll(',', '');
    String currentAmountText = _currentAmountController.text.trim().replaceAll(',', '');

    if (title.isEmpty || amountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تکایە هەموو زانیارییەکان پڕبکەرەوە', style: TextStyle(fontFamily: 'Rabar')), backgroundColor: AppTheme.error, behavior: SnackBarBehavior.floating),
      );
      return;
    }

    // Kurdish/Arabic numerals conversion
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    const persian = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    for (int i = 0; i < 10; i++) {
      amountText = amountText.replaceAll(arabic[i], english[i]);
      amountText = amountText.replaceAll(persian[i], english[i]);
      currentAmountText = currentAmountText.replaceAll(arabic[i], english[i]);
      currentAmountText = currentAmountText.replaceAll(persian[i], english[i]);
    }
    
    amountText = amountText.replaceAll(RegExp(r'[^0-9.]'), '');
    currentAmountText = currentAmountText.replaceAll(RegExp(r'[^0-9.]'), '');

    if (amountText.split('.').length > 2) amountText = amountText.replaceAll('.', '');
    if (currentAmountText.split('.').length > 2) currentAmountText = currentAmountText.replaceAll('.', '');

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تکایە بڕێکی دروست بنووسە بۆ ئامانجەکە', style: TextStyle(fontFamily: 'Rabar')), backgroundColor: AppTheme.error, behavior: SnackBarBehavior.floating),
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
          icon: _selectedIcon,
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
          icon: _selectedIcon,
          targetDate: _selectedDate,
          currency: _selectedCurrency,
        );
        await FirestoreService().updateGoal(widget.coupleId, widget.goal!.id, updatedGoal);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('هەڵەیەک ڕوویدا: $e'), backgroundColor: AppTheme.error, behavior: SnackBarBehavior.floating)
        );
      }
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
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // EMOJI PICKER
            Text('ئایکۆنی ئامانج', style: AppTheme.titleLarge),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(_selectedIcon, style: const TextStyle(fontSize: 40)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: _popularIcons.map((icon) {
                      final isSelected = icon == _selectedIcon;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedIcon = icon),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.primary : AppTheme.background,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isSelected ? AppTheme.primary : Colors.white12),
                            boxShadow: isSelected ? [
                              BoxShadow(color: AppTheme.primary.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 2))
                            ] : [],
                          ),
                          child: Text(icon, style: const TextStyle(fontSize: 24)),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // TITLE
            _buildInputLabel('ناونیشانی ئامانج'),
            TextField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: _buildInputDecoration('نموونە: کڕینی ئۆتۆمبێلی نوێ', Icons.title_rounded),
            ),
            
            const SizedBox(height: 24),

            // AMOUNT AND CURRENCY
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInputLabel('بڕی پارەی پێویست'),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.primary.withOpacity(0.5)),
                  ),
                  child: Row(
                    children: [
                      _buildCurrencyToggle('\$', 'دۆلار'),
                      _buildCurrencyToggle('IQD', 'دینار'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              decoration: _buildInputDecoration('1000', null).copyWith(
                prefixText: _selectedCurrency == '\$' ? '\$ ' : '',
                suffixText: _selectedCurrency == 'IQD' ? ' دینار' : '',
                prefixStyle: const TextStyle(color: AppTheme.primary, fontSize: 24, fontWeight: FontWeight.bold),
                suffixStyle: const TextStyle(color: AppTheme.primary, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 24),

            // CURRENT AMOUNT (If editing)
            if (widget.goal != null) ...[
              _buildInputLabel('پارەی کۆکراوەی ئێستا'),
              TextField(
                controller: _currentAmountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: AppTheme.success, fontSize: 24, fontWeight: FontWeight.bold),
                decoration: _buildInputDecoration('0', null).copyWith(
                  prefixText: _selectedCurrency == '\$' ? '\$ ' : '',
                  suffixText: _selectedCurrency == 'IQD' ? ' دینار' : '',
                  prefixStyle: const TextStyle(color: AppTheme.success, fontSize: 24, fontWeight: FontWeight.bold),
                  suffixStyle: const TextStyle(color: AppTheme.success, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // DATE PICKER
            _buildInputLabel('بەرواری بەدەستهێنان'),
            GestureDetector(
              onTap: _selectDate,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.calendar_month_rounded, color: AppTheme.primary),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('بەرواری دیاریکراو', style: TextStyle(color: Colors.white54, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('yyyy/MM/dd').format(_selectedDate),
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Spacer(),
                    const Icon(Icons.chevron_right_rounded, color: Colors.white54),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 40),

            // SAVE BUTTON
            SizedBox(
              width: double.infinity,
              height: 64,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveGoal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 8,
                  shadowColor: AppTheme.primary.withOpacity(0.4),
                ),
                child: _isLoading
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                    : Text(
                        widget.goal == null ? 'پاشکەوتکردن' : 'نوێکردنەوەی ئامانج', 
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)
                      ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildInputLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, right: 4),
      child: Text(text, style: AppTheme.titleLarge),
    );
  }

  InputDecoration _buildInputDecoration(String hint, IconData? icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
      filled: true,
      fillColor: AppTheme.surface,
      prefixIcon: icon != null ? Icon(icon, color: AppTheme.primary.withOpacity(0.7)) : null,
      contentPadding: const EdgeInsets.all(20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: AppTheme.primary, width: 2),
      ),
    );
  }

  Widget _buildCurrencyToggle(String value, String label) {
    final isSelected = _selectedCurrency == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedCurrency = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white54,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
