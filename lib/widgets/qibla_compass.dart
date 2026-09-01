import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import '../theme/app_theme.dart';

/// Kompas kiblat sederhana, digambar manual dengan CustomPainter — TIDAK
/// memakai tile peta online (Google Maps/OpenStreetMap), sehingga tetap
/// konsisten dengan syarat aplikasi 100% offline.
///
/// Dua mode:
/// - LIVE: jika sensor magnetometer perangkat tersedia (umumnya HP/tablet),
///   lingkaran kompas berputar mengikuti arah hadap perangkat sungguhan,
///   dan jarum emas tetap menunjuk ke arah kiblat sebenarnya (mirip aplikasi
///   kompas kiblat pada umumnya).
/// - STATIS: jika sensor tidak tersedia (umum terjadi di desktop/web, atau
///   izin sensor ditolak), otomatis jatuh ke tampilan statis dengan utara
///   selalu di atas — tetap menampilkan derajat bearing yang benar, hanya
///   tidak berputar mengikuti gerakan fisik perangkat.
class QiblaCompass extends StatefulWidget {
  final double bearingDerajat;
  final double size;

  const QiblaCompass({
    super.key,
    required this.bearingDerajat,
    this.size = 180,
  });

  @override
  State<QiblaCompass> createState() => _QiblaCompassState();
}

class _QiblaCompassState extends State<QiblaCompass> {
  StreamSubscription<CompassEvent>? _subscription;
  double? _headingDerajat; // arah hadap perangkat sungguhan, null jika tak tersedia
  bool _sensorError = false;

  @override
  void initState() {
    super.initState();
    _listenCompass();
  }

  void _listenCompass() {
    try {
      if (FlutterCompass.events == null) {
        setState(() => _sensorError = true);
        return;
      }
      _subscription = FlutterCompass.events!.listen(
        (event) {
          if (!mounted) return;
          if (event.heading == null) return;
          setState(() => _headingDerajat = event.heading);
        },
        onError: (_) {
          if (mounted) setState(() => _sensorError = true);
        },
      );
    } catch (_) {
      setState(() => _sensorError = true);
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  bool get _isLive => !_sensorError && _headingDerajat != null;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Mode live: putar seluruh dial berlawanan arah heading perangkat, agar
    // "Utara" pada dial selalu menunjuk utara sungguhan, dan jarum kiblat
    // (digambar relatif terhadap dial) otomatis tetap akurat.
    final dialRotationDeg = _isLive ? -(_headingDerajat!) : 0.0;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.rotate(
            angle: dialRotationDeg * pi / 180,
            child: CustomPaint(
              size: Size(widget.size, widget.size),
              painter: _CompassPainter(
                bearingDerajat: widget.bearingDerajat,
                isDark: isDark,
              ),
            ),
          ),
          if (_isLive)
            Positioned(
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.emerald.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'LIVE',
                  style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CompassPainter extends CustomPainter {
  final double bearingDerajat;
  final bool isDark;

  _CompassPainter({required this.bearingDerajat, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    final ringPaint = Paint()
      ..color = AppColors.gold.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(center, radius, ringPaint);

    final tickPaint = Paint()
      ..color = (isDark ? Colors.white : AppColors.emerald).withOpacity(0.4)
      ..strokeWidth = 1.5;
    for (int i = 0; i < 36; i++) {
      final angle = (i * 10) * pi / 180;
      final outer = Offset(
        center.dx + radius * sin(angle),
        center.dy - radius * cos(angle),
      );
      final innerR = i % 9 == 0 ? radius - 12 : radius - 6;
      final inner = Offset(
        center.dx + innerR * sin(angle),
        center.dy - innerR * cos(angle),
      );
      canvas.drawLine(inner, outer, tickPaint);
    }

    // Label mata angin utama
    _drawLabel(canvas, 'U', center, radius - 26, 0, isDark);
    _drawLabel(canvas, 'T', center, radius - 26, 90, isDark);
    _drawLabel(canvas, 'S', center, radius - 26, 180, isDark);
    _drawLabel(canvas, 'B', center, radius - 26, 270, isDark);

    // Jarum arah kiblat — warna tertiary sesuai design system Stitch
    // (maroon di light mode, salmon/pink di dark mode), bukan gold seperti
    // versi sebelumnya. Gold dicadangkan khusus badge & highlight, bukan
    // elemen kompas itu sendiri.
    final needleColor = isDark ? AppColors.tertiaryDark : AppColors.tertiaryLight;

    final needleAngle = bearingDerajat * pi / 180;
    final tip = Offset(
      center.dx + (radius - 20) * sin(needleAngle),
      center.dy - (radius - 20) * cos(needleAngle),
    );
    final tailAngle = needleAngle + pi;
    final tail = Offset(
      center.dx + 18 * sin(tailAngle),
      center.dy - 18 * cos(tailAngle),
    );

    final needlePaint = Paint()
      ..color = needleColor
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, tip, needlePaint);
    canvas.drawLine(center, tail, needlePaint..color = needleColor.withOpacity(0.5));

    // Ikon kecil di ujung jarum (segitiga sederhana, menandai "Ka'bah")
    final arrowPaint = Paint()..color = needleColor;
    final perp = needleAngle + pi / 2;
    final base1 = Offset(
      tip.dx - 10 * sin(needleAngle) + 6 * sin(perp),
      tip.dy + 10 * cos(needleAngle) - 6 * cos(perp),
    );
    final base2 = Offset(
      tip.dx - 10 * sin(needleAngle) - 6 * sin(perp),
      tip.dy + 10 * cos(needleAngle) + 6 * cos(perp),
    );
    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(base1.dx, base1.dy)
      ..lineTo(base2.dx, base2.dy)
      ..close();
    canvas.drawPath(path, arrowPaint);

    // Titik pusat — gold sesuai referensi (pusat presisi kompas)
    canvas.drawCircle(center, 4, Paint()..color = AppColors.gold);
  }

  void _drawLabel(Canvas canvas, String text, Offset center, double dist, double angleDeg, bool isDark) {
    final angle = angleDeg * pi / 180;
    final pos = Offset(
      center.dx + dist * sin(angle),
      center.dy - dist * cos(angle),
    );
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: isDark ? Colors.white70 : AppColors.emeraldDark,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _CompassPainter oldDelegate) =>
      oldDelegate.bearingDerajat != bearingDerajat || oldDelegate.isDark != isDark;
}
