import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/item.dart';

class ItemPlaceholderPainter extends CustomPainter {
  final Item item;
  final Color backgroundColor;

  ItemPlaceholderPainter({
    required this.item,
    this.backgroundColor = const Color(0xFFF0F0F0),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = math.min(size.width, size.height) * 0.3;

    // Background
    paint.color = backgroundColor;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Item color with gradient
    final gradient = RadialGradient(
      colors: [
        item.rarityColor,
        item.rarityColor.withOpacity(0.7),
      ],
    ).createShader(
      Rect.fromCircle(center: Offset(centerX, centerY), radius: radius),
    );
    
    paint.shader = gradient;

    // Draw different shapes based on item name
    if (item.name.contains('剣') || item.name.contains('ブレード')) {
      _drawSword(canvas, paint, centerX, centerY, radius);
    } else if (item.name.contains('帽子') || item.name.contains('クラウン')) {
      _drawHat(canvas, paint, centerX, centerY, radius);
    } else if (item.name.contains('ブーツ')) {
      _drawBoots(canvas, paint, centerX, centerY, radius);
    } else if (item.name.contains('リング') || item.name.contains('ネックレス')) {
      _drawRing(canvas, paint, centerX, centerY, radius);
    } else if (item.name.contains('盾')) {
      _drawShield(canvas, paint, centerX, centerY, radius);
    } else if (item.name.contains('杖') || item.name.contains('スタッフ')) {
      _drawStaff(canvas, paint, centerX, centerY, radius);
    } else if (item.name.contains('アーマー') || item.name.contains('ローブ')) {
      _drawArmor(canvas, paint, centerX, centerY, radius);
    } else if (item.name.contains('マント')) {
      _drawCloak(canvas, paint, centerX, centerY, radius);
    } else if (item.name.contains('羽根')) {
      _drawFeather(canvas, paint, centerX, centerY, radius);
    } else {
      // Default circular shape
      canvas.drawCircle(Offset(centerX, centerY), radius, paint);
    }

    // Add rarity glow effect
    if (item.rarity == ItemRarity.epic || item.rarity == ItemRarity.legendary) {
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = 3;
      paint.shader = null;
      paint.color = item.rarityColor.withOpacity(
        item.rarity == ItemRarity.legendary ? 0.6 : 0.3,
      );
      paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawRect(
        Rect.fromLTWH(10, 10, size.width - 20, size.height - 20),
        paint,
      );
    }
  }

  void _drawSword(Canvas canvas, Paint paint, double cx, double cy, double r) {
    final path = Path();
    path.moveTo(cx, cy - r * 1.2);
    path.lineTo(cx + r * 0.2, cy + r * 0.8);
    path.lineTo(cx, cy + r * 1.2);
    path.lineTo(cx - r * 0.2, cy + r * 0.8);
    path.close();
    canvas.drawPath(path, paint);
    
    // Hilt
    paint.shader = null;
    paint.color = Colors.grey[700]!;
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(cx, cy + r * 0.6),
        width: r * 0.8,
        height: r * 0.2,
      ),
      paint,
    );
  }

  void _drawHat(Canvas canvas, Paint paint, double cx, double cy, double r) {
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy),
        width: r * 1.8,
        height: r * 1.2,
      ),
      paint,
    );
    
    // Brim
    paint.shader = null;
    paint.color = item.rarityColor.withOpacity(0.8);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy + r * 0.3),
        width: r * 2.2,
        height: r * 0.6,
      ),
      paint,
    );
  }

  void _drawBoots(Canvas canvas, Paint paint, double cx, double cy, double r) {
    final path = Path();
    path.addRRect(RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cx, cy),
        width: r * 1.2,
        height: r * 1.8,
      ),
      Radius.circular(r * 0.3),
    ));
    canvas.drawPath(path, paint);
    
    // Sole
    paint.shader = null;
    paint.color = Colors.brown[800]!;
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(cx, cy + r * 0.8),
        width: r * 1.2,
        height: r * 0.2,
      ),
      paint,
    );
  }

  void _drawRing(Canvas canvas, Paint paint, double cx, double cy, double r) {
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = r * 0.3;
    canvas.drawCircle(Offset(cx, cy), r, paint);
    
    // Gem
    paint.style = PaintingStyle.fill;
    paint.shader = null;
    paint.color = item.rarityColor.withOpacity(0.8);
    canvas.drawCircle(Offset(cx, cy - r), r * 0.3, paint);
  }

  void _drawShield(Canvas canvas, Paint paint, double cx, double cy, double r) {
    final path = Path();
    path.moveTo(cx, cy - r);
    path.quadraticBezierTo(
      cx + r * 1.2, cy - r * 0.5,
      cx + r * 0.8, cy + r,
    );
    path.lineTo(cx, cy + r * 1.2);
    path.lineTo(cx - r * 0.8, cy + r);
    path.quadraticBezierTo(
      cx - r * 1.2, cy - r * 0.5,
      cx, cy - r,
    );
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawStaff(Canvas canvas, Paint paint, double cx, double cy, double r) {
    // Staff body
    paint.shader = null;
    paint.color = Colors.brown[600]!;
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(cx, cy),
        width: r * 0.3,
        height: r * 2.4,
      ),
      paint,
    );
    
    // Crystal/orb at top
    final gradient = RadialGradient(
      colors: [
        item.rarityColor.withOpacity(0.8),
        item.rarityColor,
      ],
    ).createShader(
      Rect.fromCircle(center: Offset(cx, cy - r * 1.2), radius: r * 0.5),
    );
    paint.shader = gradient;
    canvas.drawCircle(Offset(cx, cy - r * 1.2), r * 0.5, paint);
  }

  void _drawArmor(Canvas canvas, Paint paint, double cx, double cy, double r) {
    // Chest piece
    final path = Path();
    path.moveTo(cx - r * 0.8, cy - r * 0.8);
    path.lineTo(cx + r * 0.8, cy - r * 0.8);
    path.lineTo(cx + r * 0.6, cy + r * 0.8);
    path.lineTo(cx - r * 0.6, cy + r * 0.8);
    path.close();
    canvas.drawPath(path, paint);
    
    // Shoulders
    canvas.drawCircle(Offset(cx - r * 0.8, cy - r * 0.6), r * 0.3, paint);
    canvas.drawCircle(Offset(cx + r * 0.8, cy - r * 0.6), r * 0.3, paint);
  }

  void _drawCloak(Canvas canvas, Paint paint, double cx, double cy, double r) {
    final path = Path();
    path.moveTo(cx, cy - r);
    path.quadraticBezierTo(
      cx + r * 1.5, cy,
      cx + r * 1.2, cy + r * 1.5,
    );
    path.lineTo(cx - r * 1.2, cy + r * 1.5);
    path.quadraticBezierTo(
      cx - r * 1.5, cy,
      cx, cy - r,
    );
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawFeather(Canvas canvas, Paint paint, double cx, double cy, double r) {
    final path = Path();
    path.moveTo(cx, cy - r * 1.5);
    path.quadraticBezierTo(
      cx + r * 0.5, cy - r * 0.5,
      cx + r * 0.3, cy + r * 1.5,
    );
    path.quadraticBezierTo(
      cx, cy + r * 1.2,
      cx - r * 0.3, cy + r * 1.5,
    );
    path.quadraticBezierTo(
      cx - r * 0.5, cy - r * 0.5,
      cx, cy - r * 1.5,
    );
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}