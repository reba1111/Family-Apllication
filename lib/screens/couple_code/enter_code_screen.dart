import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme.dart';
import '../../services/firestore_service.dart';
import '../home/home_screen.dart';

class EnterCodeScreen extends StatefulWidget {
  const EnterCodeScreen({super.key});

  @override
  State<EnterCodeScreen> createState() => _EnterCodeScreenState();
}

class _EnterCodeScreenState extends State<EnterCodeScreen>
    with TickerProviderStateMixin {
  final List<TextEditingController> _ctrls =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _nodes = List.generate(6, (_) => FocusNode());
  bool _loading = false;
  final _fs = FirestoreService();

  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _shakeAnim = Tween<double>(begin: 0, end: 12).animate(
      CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticIn),
    );
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    for (final c in _ctrls) c.dispose();
    for (final n in _nodes) n.dispose();
    _shakeCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  String get _code => _ctrls.map((c) => c.text).join();

  Future<void> _submit() async {
    if (_code.length < 6) {
      _shakeCtrl.forward(from: 0);
      _showError('تکایە ٦ ژمارە بنووسە');
      return;
    }
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _loading = true);
    try {
      await _fs.enterCoupleCode(code: _code, user2Id: uid);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (_) => false,
      );
    } catch (e) {
      _shakeCtrl.forward(from: 0);
      _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onChanged(int index, String val) {
    if (val.length == 1 && index < 5) {
      _nodes[index + 1].requestFocus();
    } else if (val.isEmpty && index > 0) {
      _nodes[index - 1].requestFocus();
    }
    setState(() {});
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppTheme.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration:
            const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                  horizontal: 28, vertical: 40),
              child: Column(
                children: [
                  // Back
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new,
                          color: AppTheme.onSurface),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Icon
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withOpacity(0.45),
                          blurRadius: 28,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Center(
                      child:
                          Text('🔑', style: TextStyle(fontSize: 38)),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text('کۆدی هاوسەر', style: AppTheme.displayLarge),
                  const SizedBox(height: 8),
                  Text(
                    '٦ ژمارەی کۆدەکەی هاوسەرەکەت بنووسە',
                    style: AppTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),

                  // Code input boxes
                  AnimatedBuilder(
                    animation: _shakeAnim,
                    builder: (_, child) => Transform.translate(
                      offset: Offset(
                        _shakeCtrl.isAnimating
                            ? (_shakeAnim.value *
                                    (_shakeCtrl.value < 0.5 ? 1 : -1))
                            : 0,
                        0,
                      ),
                      child: child,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(6, (i) {
                        final filled = _ctrls[i].text.isNotEmpty;
                        return SizedBox(
                          width: 46,
                          height: 60,
                          child: TextField(
                            controller: _ctrls[i],
                            focusNode: _nodes[i],
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            maxLength: 1,
                            style: AppTheme.titleLarge.copyWith(
                              fontSize: 22,
                              color: filled
                                  ? AppTheme.primary
                                  : AppTheme.onSurface,
                            ),
                            decoration: InputDecoration(
                              counterText: '',
                              filled: true,
                              fillColor: filled
                                  ? AppTheme.primary.withOpacity(0.12)
                                  : AppTheme.surfaceVariant,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: filled
                                      ? AppTheme.primary
                                      : const Color(0xFF33334A),
                                  width: filled ? 1.5 : 1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                    color: AppTheme.primary, width: 2),
                              ),
                            ),
                            onChanged: (v) => _onChanged(i, v),
                          ),
                        );
                      }),
                    ),
                  ),

                  const SizedBox(height: 48),

                  ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('بەستنی هاوسەر ❤️'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
