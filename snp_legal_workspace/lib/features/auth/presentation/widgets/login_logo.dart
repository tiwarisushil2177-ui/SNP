import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Gold shield + scales of justice logo used on the login card.
/// Matches the reference design (gold line-art on transparent).
class LoginLogo extends StatelessWidget {
  const LoginLogo({super.key, this.size = 56});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ShieldScalesPainter(),
        size: Size(size, size),
      ),
    );
  }
}

class _ShieldScalesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.loginGold
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.045
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = AppColors.loginGold
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    final shield = Path();
    shield.moveTo(w * 0.5, h * 0.02);
    shield.lineTo(w * 0.92, h * 0.18);
    shield.lineTo(w * 0.92, h * 0.52);
    shield.quadraticBezierTo(w * 0.92, h * 0.78, w * 0.5, h * 0.98);
    shield.quadraticBezierTo(w * 0.08, h * 0.78, w * 0.08, h * 0.52);
    shield.lineTo(w * 0.08, h * 0.18);
    shield.close();
    canvas.drawPath(shield, paint);

    final pillarX = w * 0.5;
    final pillarTop = h * 0.28;
    final pillarBottom = h * 0.72;
    final pillarW = w * 0.07;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(pillarX, pillarBottom),
          width: pillarW * 2.2,
          height: h * 0.06,
        ),
        const Radius.circular(2),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(
          pillarX - pillarW * 0.55,
          pillarTop + h * 0.08,
          pillarX + pillarW * 0.55,
          pillarBottom - h * 0.03,
        ),
        const Radius.circular(1),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(pillarX, pillarTop + h * 0.06),
          width: pillarW * 1.8,
          height: h * 0.05,
        ),
        const Radius.circular(1),
      ),
      paint,
    );

    canvas.drawCircle(Offset(pillarX, h * 0.22), w * 0.035, fillPaint);
    canvas.drawLine(
      Offset(pillarX, h * 0.22 + w * 0.03),
      Offset(pillarX, pillarTop + h * 0.02),
      paint,
    );

    final beamY = pillarTop + h * 0.04;
    canvas.drawLine(Offset(w * 0.22, beamY), Offset(w * 0.78, beamY), paint);
    canvas.drawCircle(Offset(w * 0.22, beamY), w * 0.025, fillPaint);
    canvas.drawCircle(Offset(w * 0.78, beamY), w * 0.025, fillPaint);

    final leftPanX = w * 0.28;
    final panY = h * 0.48;
    final panW = w * 0.14;
    canvas.drawLine(Offset(w * 0.22, beamY), Offset(leftPanX - panW * 0.4, panY - h * 0.02), paint);
    canvas.drawLine(Offset(w * 0.22, beamY), Offset(leftPanX + panW * 0.4, panY - h * 0.02), paint);
    final leftPan = Path();
    leftPan.moveTo(leftPanX - panW, panY - h * 0.02);
    leftPan.quadraticBezierTo(leftPanX, panY + h * 0.08, leftPanX + panW, panY - h * 0.02);
    canvas.drawPath(leftPan, paint);

    final rightPanX = w * 0.72;
    canvas.drawLine(Offset(w * 0.78, beamY), Offset(rightPanX - panW * 0.4, panY - h * 0.02), paint);
    canvas.drawLine(Offset(w * 0.78, beamY), Offset(rightPanX + panW * 0.4, panY - h * 0.02), paint);
    final rightPan = Path();
    rightPan.moveTo(rightPanX - panW, panY - h * 0.02);
    rightPan.quadraticBezierTo(rightPanX, panY + h * 0.08, rightPanX + panW, panY - h * 0.02);
    canvas.drawPath(rightPan, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
