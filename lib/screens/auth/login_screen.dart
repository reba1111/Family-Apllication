import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme.dart';
import '../../services/auth_service.dart';
import '../../widgets/google_sign_in_button.dart';
import 'signup_screen.dart';
import '../couple_code/generate_code_screen.dart';
import '../couple_code/enter_code_screen.dart';
import '../home/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  bool _googleLoading = false;
  final _auth = AuthService();

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  late AnimationController _slideCtrl;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slideCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _slideAnim =
        Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero).animate(
            CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));
    _fadeCtrl.forward();
    _slideCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _slideCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final cred = await _auth.signIn(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
      final user = await _auth
          .getUserModel(cred.user!.uid)
          .timeout(const Duration(seconds: 10), onTimeout: () => null);
      if (!mounted) return;
      _navigateAfterAuth(user?.coupleId);
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
      _navigateAfterAuth(user.coupleId);
    } catch (e) {
      if (mounted) _showError('هەڵەی گۆگڵ: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  void _navigateAfterAuth(String? coupleId) {
    if (coupleId != null) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (_) => false,
      );
    } else {
      _showLinkDialog();
    }
  }

  void _showLinkDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('💑', style: TextStyle(fontSize: 52)),
            const SizedBox(height: 12),
            Text('بەستنی هاوسەر', style: AppTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              'کۆدی هاوسەرت داخڵ بکە یان کۆدی خۆت دروست بکە',
              style: AppTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const GenerateCodeScreen()));
              },
              child: const Text('دروستکردنی کۆد'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const EnterCodeScreen()));
              },
              child: const Text('داخڵکردنی کۆد'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppTheme.error),
    );
  }

  String _authError(String code) => switch (code) {
        'user-not-found' => 'ئەم ئیمەیڵە بوجود نییە.',
        'wrong-password' => 'پاسوۆردەکە هەڵەیە.',
        'invalid-email' => 'فۆرماتی ئیمەیڵ هەڵەیە.',
        'too-many-requests' => 'زۆر جارت هەوڵدا، کەمێک چاوەڕێ بکە.',
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
            child: SlideTransition(
              position: _slideAnim,
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 88,
                              height: 88,
                              decoration: BoxDecoration(
                                gradient: AppTheme.primaryGradient,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primary.withOpacity(0.45),
                                    blurRadius: 28,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child:
                                    Text('❤️', style: TextStyle(fontSize: 40)),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text('بەخێربێیت', style: AppTheme.displayLarge),
                            const SizedBox(height: 6),
                            Text('چوونەژوورەوە بۆ ئەپەکەت',
                                style: AppTheme.bodyMedium),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),

                      GoogleSignInButton(
                        loading: _googleLoading,
                        onPressed: _googleSignIn,
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Row(
                          children: [
                            Expanded(
                                child: Divider(
                                    color: AppTheme.onSurfaceMuted
                                        .withOpacity(0.3))),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 14),
                              child: Text('یان بە ئیمەیڵ',
                                  style: AppTheme.bodyMedium),
                            ),
                            Expanded(
                                child: Divider(
                                    color: AppTheme.onSurfaceMuted
                                        .withOpacity(0.3))),
                          ],
                        ),
                      ),

                      Text('ئیمەیڵ', style: AppTheme.labelLarge),
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
                      const SizedBox(height: 20),

                      Text('پاسوۆرد', style: AppTheme.labelLarge),
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
                      const SizedBox(height: 32),

                      ElevatedButton(
                        onPressed: _loading ? null : _login,
                        child: _loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('چوونەژوورەوە'),
                      ),
                      const SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('هەژمارت نییە؟ ', style: AppTheme.bodyMedium),
                          GestureDetector(
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const SignupScreen()),
                            ),
                            child: Text(
                              'تۆمارکردن',
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
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
