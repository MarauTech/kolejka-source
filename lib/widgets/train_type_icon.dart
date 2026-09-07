import 'package:flutter/material.dart';
import '../utils/category_utils.dart';

/// Category artwork, not a promise about the rolling stock on a given service.
bool usesExpressTrainIcon(String category) => const {
      'IC',
      'EIC',
      'EIP',
      'EC',
      'EN',
      'TLK',
      'ICE',
      'TGV',
      'RJ',
      'RJX',
    }.contains(primaryCategorySymbol(category));

class TrainTypeIcon extends StatelessWidget {
  final String category;
  final double size;
  final Color? color;
  const TrainTypeIcon(
      {super.key, required this.category, this.size = 24, this.color});

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: CustomPaint(
          size: Size.square(size),
          painter: _TrainPainter(
            express: usesExpressTrainIcon(category),
            color: color ?? Theme.of(context).colorScheme.primary,
          ),
        ),
      );
}

class _TrainPainter extends CustomPainter {
  final bool express;
  final Color color;
  const _TrainPainter({required this.express, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24, size.height / 24);
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.65
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    final fill = Paint()..color = color;
    if (express) {
      // Tapered nose and swept windscreen of a high-speed train, seen head-on.
      final body = Path()
        ..moveTo(7, 4)
        ..quadraticBezierTo(12, 0.8, 17, 4)
        ..cubicTo(19, 7, 21, 14, 18.8, 17.5)
        ..quadraticBezierTo(12, 22, 5.2, 17.5)
        ..cubicTo(3, 14, 5, 7, 7, 4)
        ..close();
      canvas.drawPath(body, stroke);
      canvas.drawPath(
          Path()
            ..moveTo(7, 6)
            ..quadraticBezierTo(12, 3.8, 17, 6)
            ..lineTo(16, 10)
            ..quadraticBezierTo(12, 12, 8, 10)
            ..close(),
          fill);
      canvas.drawLine(const Offset(6.8, 14), const Offset(9, 14.8), stroke);
      canvas.drawLine(const Offset(17.2, 14), const Offset(15, 14.8), stroke);
      canvas.drawLine(const Offset(10.5, 18), const Offset(13.5, 18), stroke);
    } else {
      // Upright cab, split windows and round headlights of a regional unit.
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              const Rect.fromLTWH(5, 2, 14, 17), const Radius.circular(4)),
          stroke);
      for (final x in [7.0, 12.7]) {
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                const Rect.fromLTWH(0, 0, 4.3, 6).shift(Offset(x, 6)),
                const Radius.circular(1)),
            fill);
      }
      canvas.drawLine(const Offset(9, 4), const Offset(15, 4), stroke);
      canvas.drawCircle(const Offset(8, 15.4), 1.2, fill);
      canvas.drawCircle(const Offset(16, 15.4), 1.2, fill);
      canvas.drawLine(const Offset(10, 18), const Offset(14, 18), stroke);
    }
    canvas.drawLine(const Offset(8, 20), const Offset(6, 22), stroke);
    canvas.drawLine(const Offset(16, 20), const Offset(18, 22), stroke);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_TrainPainter oldDelegate) =>
      oldDelegate.express != express || oldDelegate.color != color;
}
