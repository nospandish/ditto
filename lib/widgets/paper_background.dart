import 'package:flutter/material.dart';

class PaperBackground extends StatelessWidget {
  const PaperBackground({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(painter: const _PaperTexturePainter(), child: child),
    );
  }
}

class _PaperTexturePainter extends CustomPainter {
  const _PaperTexturePainter();

  static const _creases = <_Crease>[
    _Crease(0.00, 0.16, 0.28, 0.11, 0.53, 0.20),
    _Crease(0.54, 0.20, 0.72, 0.28, 1.00, 0.22),
    _Crease(0.08, 0.43, 0.31, 0.36, 0.47, 0.49),
    _Crease(0.48, 0.49, 0.69, 0.39, 0.94, 0.46),
    _Crease(0.00, 0.70, 0.20, 0.61, 0.39, 0.74),
    _Crease(0.40, 0.74, 0.63, 0.66, 0.82, 0.78),
    _Crease(0.12, 1.00, 0.32, 0.87, 0.54, 0.94),
    _Crease(0.67, 1.00, 0.79, 0.87, 1.00, 0.91),
    _Crease(0.17, 0.00, 0.23, 0.19, 0.15, 0.37),
    _Crease(0.76, 0.00, 0.69, 0.16, 0.78, 0.34),
    _Crease(0.29, 0.35, 0.39, 0.52, 0.31, 0.68),
    _Crease(0.88, 0.43, 0.77, 0.58, 0.89, 0.72),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFF6F3EB),
    );

    _paintFacets(canvas, size);
    for (final crease in _creases) {
      final path = crease.path(size);
      canvas.drawPath(
        path.shift(const Offset(0.9, 1.2)),
        Paint()
          ..color = const Color(0x140F241B)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
      canvas.drawPath(
        path.shift(const Offset(-0.7, -0.8)),
        Paint()
          ..color = const Color(0x66FFFFFF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.1,
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0x0D456B5A)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.7,
      );
    }
  }

  void _paintFacets(Canvas canvas, Size size) {
    final shade = Paint()..color = const Color(0x0A456B5A);
    final light = Paint()..color = const Color(0x24FFFFFF);

    canvas.drawPath(
      Path()
        ..moveTo(0, size.height * 0.16)
        ..lineTo(size.width * 0.28, size.height * 0.11)
        ..lineTo(size.width * 0.15, size.height * 0.37)
        ..close(),
      shade,
    );
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.54, size.height * 0.20)
        ..lineTo(size.width * 0.76, 0)
        ..lineTo(size.width * 0.78, size.height * 0.34)
        ..close(),
      light,
    );
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.31, size.height * 0.68)
        ..lineTo(size.width * 0.48, size.height * 0.49)
        ..lineTo(size.width * 0.63, size.height * 0.66)
        ..close(),
      shade,
    );
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.67, size.height)
        ..lineTo(size.width * 0.82, size.height * 0.78)
        ..lineTo(size.width, size.height * 0.91)
        ..close(),
      light,
    );
  }

  @override
  bool shouldRepaint(covariant _PaperTexturePainter oldDelegate) => false;
}

class _Crease {
  const _Crease(
    this.startX,
    this.startY,
    this.controlX,
    this.controlY,
    this.endX,
    this.endY,
  );

  final double startX;
  final double startY;
  final double controlX;
  final double controlY;
  final double endX;
  final double endY;

  Path path(Size size) {
    return Path()
      ..moveTo(size.width * startX, size.height * startY)
      ..quadraticBezierTo(
        size.width * controlX,
        size.height * controlY,
        size.width * endX,
        size.height * endY,
      );
  }
}
