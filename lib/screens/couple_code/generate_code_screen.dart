import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../home/home_screen.dart';
import '../auth/login_screen.dart';
import 'enter_code_screen.dart';

class GenerateCodeScreen extends StatefulWidget {
  const GenerateCodeScreen({super.key});

  @override
  State<GenerateCodeScreen> createState() => _GenerateCodeScreenState();
}

class _GenerateCodeScreenState extends State<GenerateCodeScreen>
    with TickerProviderStateMixin {
  String? _code;
  bool _generating = false;
  final _fs = FirestoreService();

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  late AnimationController _scaleCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.97, end: 1.03).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnim = CurvedAnimation(parent: _scaleCtrl, curve: Curves.elasticOut);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _scaleCtrl.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _generating = true);
    try {
      final code = await _fs
          .generateCoupleCode(uid)
          .timeout(const Duration(seconds: 20), onTimeout: () {
        throw Exception('کات تەواو بوو — تکایە ئینتەرنێتەکەت پشکنە و دووبارە هەوڵ بدە');
      });
      setState(() => _code = code);
      _scaleCtrl.forward(from: 0);
    } on FirebaseException catch (e) {
      _showError('Firebase هەڵە: ${e.code} — ${e.message}');
    } catch (e) {
      _showError('هەڵە: $e');
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  void _copy() {
    if (_code == null) return;
    Clipboard.setData(ClipboardData(text: _code!));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('کۆدەکە کۆپی کرا ✓')),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppTheme.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: () async {
              await AuthService().signOut();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (_) => false,
              );
            },
            icon: const Icon(Icons.logout, color: AppTheme.onSurfaceMuted),
            label: Text('دەرچوون', style: TextStyle(color: AppTheme.onSurfaceMuted)),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
            child: Column(
              children: [
                // Pulsing heart
                AnimatedBuilder(
                  animation: _pulseAnim,
                  builder: (_, child) => Transform.scale(
                    scale: _pulseAnim.value,
                    child: child,
                  ),
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withOpacity(0.5),
                          blurRadius: 32,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text('💌', style: TextStyle(fontSize: 44)),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Text('کۆدی هاوسەر', style: AppTheme.displayLarge),
                const SizedBox(height: 10),
                Text(
                  'کۆدەکە بدە بە هاوسەرەکەت تا پێکەوە بەستراوبن',
                  style: AppTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                if (_code == null) ...[
                  // Generate button with shimmer border
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: AppTheme.primaryGradient,
                    ),
                    padding: const EdgeInsets.all(2),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: ElevatedButton(
                        onPressed: _generating ? null : _generate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          minimumSize: const Size(double.infinity, 60),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: _generating
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppTheme.primary,
                                ),
                              )
                            : Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.auto_awesome,
                                      color: AppTheme.primary),
                                  const SizedBox(width: 8),
                                  Text(
                                    'دروستکردنی کۆد',
                                    style: AppTheme.titleLarge.copyWith(
                                      color: AppTheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ] else ...[
                  // Code display
                  ScaleTransition(
                    scale: _scaleAnim,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 28),
                      decoration: BoxDecoration(
                        gradient: AppTheme.cardGradient,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: AppTheme.primary.withOpacity(0.4),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withOpacity(0.2),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text('کۆدەکەت',
                              style: AppTheme.bodyMedium),
                          const SizedBox(height: 12),
                          Text(
                            _code!,
                            style: AppTheme.displayLarge.copyWith(
                              fontSize: 48,
                              letterSpacing: 12,
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: _copy,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color:
                                    AppTheme.primary.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.copy,
                                      size: 16, color: AppTheme.primary),
                                  const SizedBox(width: 6),
                                  Text('کۆپیکردن',
                                      style: AppTheme.labelLarge.copyWith(
                                        color: AppTheme.primary,
                                      )),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context)
                        .pushAndRemoveUntil(
                      MaterialPageRoute(
                          builder: (_) => const HomeScreen()),
                      (_) => false,
                    ),
                    child: const Text('چوونەژوورەوە بۆ ئەپ'),
                  ),
                ],
                const SizedBox(height: 24),

                // Divider
                Row(
                  children: [
                    Expanded(
                        child: Divider(color: AppTheme.onSurfaceMuted
                            .withOpacity(0.3))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('یان',
                          style: AppTheme.bodyMedium),
                    ),
                    Expanded(
                        child: Divider(color: AppTheme.onSurfaceMuted
                            .withOpacity(0.3))),
                  ],
                ),
                const SizedBox(height: 24),

                OutlinedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const EnterCodeScreen()),
                  ),
                  child: const Text('داخڵکردنی کۆدی هاوسەرم'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
