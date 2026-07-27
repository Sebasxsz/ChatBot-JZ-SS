import 'package:flutter/material.dart';
 
import '../utils/color_utils.dart';
 
class IsometricBuildingIcon extends StatelessWidget {
  final double size;
  final Color color;
 
  const IsometricBuildingIcon({super.key, this.size = 36, required this.color});
 
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 1.15,
      child: CustomPaint(painter: _IsometricBuildingPainter(color: color)),
    );
  }
}
 
class _IsometricBuildingPainter extends CustomPainter {
  final Color color;
 
  _IsometricBuildingPainter({required this.color});
 
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final techo = h * 0.35; // Alto de la "punta" superior del cubo.
 
    // Los 6 vértices del cubo isométrico.
    final apex = Offset(w / 2, 0);
    final derSup = Offset(w, techo * 0.5);
    final izqSup = Offset(0, techo * 0.5);
    final frenteSup = Offset(w / 2, techo);
    final derInf = Offset(w, h - techo * 0.5);
    final izqInf = Offset(0, h - techo * 0.5);
    final frenteInf = Offset(w / 2, h);
 
    final caraSuperior = Path()
      ..moveTo(apex.dx, apex.dy)
      ..lineTo(derSup.dx, derSup.dy)
      ..lineTo(frenteSup.dx, frenteSup.dy)
      ..lineTo(izqSup.dx, izqSup.dy)
      ..close();
 
    final caraIzquierda = Path()
      ..moveTo(izqSup.dx, izqSup.dy)
      ..lineTo(frenteSup.dx, frenteSup.dy)
      ..lineTo(frenteInf.dx, frenteInf.dy)
      ..lineTo(izqInf.dx, izqInf.dy)
      ..close();
 
    final caraDerecha = Path()
      ..moveTo(derSup.dx, derSup.dy)
      ..lineTo(frenteSup.dx, frenteSup.dy)
      ..lineTo(frenteInf.dx, frenteInf.dy)
      ..lineTo(derInf.dx, derInf.dy)
      ..close();
 
    // Tonos: cara superior con el color pleno (más "iluminada"), las
    // caras laterales más oscuras para dar sensación de volumen.
    canvas.drawPath(caraSuperior, Paint()..color = color);
    canvas.drawPath(caraIzquierda, Paint()..color = color.conOpacidad(0.6));
    canvas.drawPath(caraDerecha, Paint()..color = color.conOpacidad(0.8));
 
    final borde = Paint()
      ..color = Colors.black.conOpacidad(0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawPath(caraSuperior, borde);
    canvas.drawPath(caraIzquierda, borde);
    canvas.drawPath(caraDerecha, borde);
  }
 
  @override
  bool shouldRepaint(covariant _IsometricBuildingPainter oldDelegate) =>
      oldDelegate.color != color;
}