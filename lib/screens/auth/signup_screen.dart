import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme.dart';
import '../../services/auth_service.dart';
import '../../widgets/google_sign_in_button.dart';
import '../couple_code/generate_code_screen.dart';
import '../home/home_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  bool _googleLoading = false;
  final _auth = AuthService();

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await _auth.signUp(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
        displayName: _nameCtrl.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const GenerateCodeScreen()),
        (_) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (mounted) _showError(_authError(e.code));
    } catch (e) {
      if (mounted) _showError('هەڵەیەک ڕووی دا: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _googleSignIn() async {
    setState(() => _googleLoading = true);
    try {
      final user = await _auth.signInWithGoogle();
      if (user == null || !mounted) return;
      if (user.coupleId != null) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (_) => false,
        );
      } else {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const GenerateCodeScreen()),
          (_) => false,
        );
      }
    } catch (e) {
      if (mounted) _showError('هەڵەی گۆگڵ: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppTheme.error),
    );
  }

  String _authError(String code) => switch (code) {
        'email-already-in-use' => 'ئەم ئیمەیڵە پێشتر تۆمارکراوە.',
        'invalid-email' => 'فۆرماتی ئیمەیڵ هەڵەیە.',
        'weak-password' => 'پاسوۆردەکە قایم نییە.',
        _ => 'هەڵەیەک ڕووی دا: $code',
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new,
                          color: AppTheme.onSurface),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(height: 12),

                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primary.withOpacity(0.4),
                                  blurRadius: 24,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Center(
                              child:
                                  Text('💑', style: TextStyle(fontSize: 36)),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text('دروستکردنی هەژمار',
                              style: AppTheme.displayLarge),
                          const SizedBox(height: 6),
                          Text('خوشی دەکات تۆ و هاوسەرت پێکەوە بن',
                              style: AppTheme.bodyMedium),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    GoogleSignInButton(
                      loading: _googleLoading,
                      onPressed: _googleSignIn,
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 22),
                      child: Row(
                        children: [
                          Expanded(
                              child: Divider(
                                  color:
                                      AppTheme.onSurfaceMuted.withOpacity(0.3))),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 14),
                            child: Text('یان بە ئیمەیڵ',
                                style: AppTheme.bodyMedium),
                          ),
                          Expanded(
                              child: Divider(
                                  color:
                                      AppTheme.onSurfaceMuted.withOpacity(0.3))),
                        ],
                      ),
                    ),

                    _label('ناو'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameCtrl,
                      style: TextStyle(color: AppTheme.onSurface),
                      decoration: const InputDecoration(
                        hintText: 'ناوت بنووسە',
                        prefixIcon: Icon(Icons.person_outline,
                            color: AppTheme.onSurfaceMuted),
                      ),
                      validator: (v) =>
                          v!.trim().length >= 2 ? null : 'ناوێک بنووسە',
                    ),
                    const SizedBox(height: 16),

                    _label('ئیمەیڵ'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(color: AppTheme.onSurface),
                      decoration: const InputDecoration(
                        hintText: 'name@example.com',
                        prefixIcon: Icon(Icons.email_outlined,
                            color: AppTheme.onSurfaceMuted),
                      ),
                      validator: (v) => v!.contains('@')
                          ? null
                          : 'ئیمەیڵێکی دروست بنووسە',
                    ),
                    const SizedBox(height: 16),

                    _label('پاسوۆرد'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passCtrl,
                      obscureText: _obscure,
                      style: TextStyle(color: AppTheme.onSurface),
                      decoration: InputDecoration(
                        hintText: '••••••••',
                        prefixIcon: const Icon(Icons.lock_outlined,
                            color: AppTheme.onSurfaceMuted),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: AppTheme.onSurfaceMuted,
                          ),
                          onPressed: () =>
                              setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) =>
                          v!.length >= 6 ? null : 'کەمتر لە ٦ پیت نابێت',
                    ),
                    const SizedBox(height: 16),

                    _label('دووبارەکردنەوەی پاسوۆرد'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _confirmCtrl,
                      obscureText: _obscure,
                      style: TextStyle(color: AppTheme.onSurface),
                      decoration: const InputDecoration(
                        hintText: '••••••••',
                        prefixIcon: Icon(Icons.lock_outlined,
                            color: AppTheme.onSurfaceMuted),
                      ),
                      validator: (v) => v == _passCtrl.text
                          ? null
                          : 'پاسوۆردەکانیان یەک نییە',
                    ),
                    const SizedBox(height: 32),

                    ElevatedButton(
                      onPressed: _loading ? null : _signup,
                      child: _loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('تۆمارکردن'),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('هەژمارت هەیە؟ ', style: AppTheme.bodyMedium),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Text(
                            'چوونەژوورەوە',
                            style: AppTheme.bodyMedium.copyWith(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.underline,
                              decorationColor: AppTheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text, style: AppTheme.labelLarge);
}
