import 'package:flutter/material.dart';
import '../../core/theme.dart';

/// Shared Google Sign-In button used in both LoginScreen and SignupScreen.
class GoogleSignInButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onPressed;
  const GoogleSignInButton(
      {super.key, required this.loading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 58,
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: loading
                ? AppTheme.onSurfaceMuted.withOpacity(0.2)
                : const Color(0xFF44446A),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: loading
            ? const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.primary,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const _GoogleLogo(),
                  const SizedBox(width: 12),
                  Text(
                    'بەردەوامبوون بە گۆگڵ',
                    style: AppTheme.labelLarge.copyWith(fontSize: 15),
                  ),
                ],
              ),
      ),
    );
  }
}

class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(24, 24),
      painter: _GoogleLogoPainter(),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final double r = size.width / 2;

    // White background circle
    final bgPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(cx, cy), r, bgPaint);

    const strokeW = 3.5;
    final innerR = r - strokeW / 2 - 1;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: innerR);

    Paint arcPaint(Color c) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW;

    // 4 colored arcs
    canvas.drawArc(rect, -0.3, 1.6, false,
        arcPaint(const Color(0xFF4285F4))); // blue
    canvas.drawArc(rect, 1.3, 1.6, false,
        arcPaint(const Color(0xFFFBBC05))); // yellow
    canvas.drawArc(rect, 2.9, 1.6, false,
        arcPaint(const Color(0xFF34A853))); // green
    canvas.drawArc(rect, 4.5, 1.1, false,
        arcPaint(const Color(0xFFEA4335))); // red

    // White horizontal bar (the "─" in G)
    canvas.drawLine(
      Offset(cx, cy),
      Offset(cx + innerR, cy),
      Paint()
        ..color = Colors.white
        ..strokeWidth = strokeW
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
