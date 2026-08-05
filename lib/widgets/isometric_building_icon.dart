
import 'package:flutter/material.dart';

enum BuildingType { generico, auditorio, coliseo, laboratorio }

class IsometricBuildingIcon extends StatelessWidget {
  final double size;
  final Color color;
  final BuildingType tipo;

  const IsometricBuildingIcon({
    super.key,
    this.size = 32,
    required this.color,
    this.tipo = BuildingType.generico,
  });

  @override
  Widget build(BuildContext context) {
    final painter = switch (tipo) {
      BuildingType.generico => _GenericClusterPainter(color: color),
      BuildingType.auditorio => _AuditorioPainter(color: color),
      BuildingType.coliseo => _ColiseoPainter(color: color),
      BuildingType.laboratorio => _LaboratorioPainter(color: color),
    };

    final ancho = switch (tipo) {
      BuildingType.coliseo => size * 1.8,
      _ => size * 1.6,
    };

    return SizedBox(
      width: ancho,
      height: size * 1.3,
      child: CustomPaint(painter: painter),
    );
  }
}

// ---------------------------------------------------------------------
// Helpers de color e isometría compartidos por todos los pintores.
// ---------------------------------------------------------------------

const _marronTecho = Color(0xFF6D4C41);

/// Aplica sobre [base] la opacidad de [colorPared] multiplicada por
/// [factor]. Es la pieza clave que evita el bug de "atenuado ignorado":
/// en vez de fijar una opacidad absoluta, la deriva del alpha que
/// realmente trae el color del edificio en ese momento.
Color _conAlphaRelativa(Color base, Color colorPared, double factor) {
  final alpha = (colorPared.a * 255.0 * factor).round().clamp(0, 255);
  return base.withAlpha(alpha);
}

Color _colorTecho(Color colorPared) =>
    _conAlphaRelativa(_marronTecho, colorPared, 1.0);

Color _sombrear(Color colorPared, double factor) =>
    _conAlphaRelativa(colorPared, colorPared, factor);

Color _colorBorde(Color colorPared) =>
    _conAlphaRelativa(Colors.black, colorPared, 0.2);

Color _colorVentana(Color colorPared) =>
    _conAlphaRelativa(Colors.white, colorPared, 0.9);

/// Interpola un punto dentro de una cara paralelográmica (superior-izq,
/// superior-der, inferior-der, inferior-izq), con u,v en [0,1]. Al ser
/// exactamente un paralelogramo, la interpolación bilineal es exacta.
Offset _puntoEnCara(
  Offset supIzq,
  Offset supDer,
  Offset infDer,
  Offset infIzq,
  double u,
  double v,
) {
  final arriba = Offset.lerp(supIzq, supDer, u)!;
  final abajo = Offset.lerp(infIzq, infDer, u)!;
  return Offset.lerp(arriba, abajo, v)!;
}

/// Dibuja una ventana ya inclinada para que encaje sobre una cara
/// isométrica, en vez de un Rect recto que se ve como una calcomanía
/// pegada torcida sobre una pared en diagonal.
void _dibujarVentana(
  Canvas canvas,
  Offset supIzq,
  Offset supDer,
  Offset infDer,
  Offset infIzq, {
  required double u0,
  required double v0,
  required double u1,
  required double v1,
  required Paint relleno,
  required Paint borde,
}) {
  final p1 = _puntoEnCara(supIzq, supDer, infDer, infIzq, u0, v0);
  final p2 = _puntoEnCara(supIzq, supDer, infDer, infIzq, u1, v0);
  final p3 = _puntoEnCara(supIzq, supDer, infDer, infIzq, u1, v1);
  final p4 = _puntoEnCara(supIzq, supDer, infDer, infIzq, u0, v1);
  final ventana = Path()
    ..moveTo(p1.dx, p1.dy)
    ..lineTo(p2.dx, p2.dy)
    ..lineTo(p3.dx, p3.dy)
    ..lineTo(p4.dx, p4.dy)
    ..close();
  canvas.drawPath(ventana, relleno);
  canvas.drawPath(ventana, borde);
}

/// Dibuja un edificio con forma de prisma isométrico (techo reducido a un
/// punto), con la BASE apoyada en [sueloY] — a diferencia de la versión
/// anterior, que posicionaba el ápice siempre en y=0 y dejaba que
/// edificios de distinta altura terminaran en bases distintas (el bug de
/// "edificios flotando" del cluster genérico).
void _dibujarEdificio(
  Canvas canvas, {
  required double xCentro,
  required double ancho,
  required double alto,
  required double sueloY,
  required Color colorPared,
  double proporcionTecho = 0.2,
  List<(double, double, double, double)> ventanasIzquierda = const [],
  List<(double, double, double, double)> ventanasDerecha = const [],
}) {
  final techoH = alto * proporcionTecho;
  final apex = Offset(xCentro, sueloY - alto);
  final rt = Offset(xCentro + ancho / 2, sueloY - alto + techoH * 0.5);
  final lt = Offset(xCentro - ancho / 2, sueloY - alto + techoH * 0.5);
  final ft = Offset(xCentro, sueloY - alto + techoH);
  final rb = Offset(xCentro + ancho / 2, sueloY);
  final lb = Offset(xCentro - ancho / 2, sueloY);
  final fb = Offset(xCentro, sueloY);

  final techo = Path()
    ..moveTo(apex.dx, apex.dy)
    ..lineTo(rt.dx, rt.dy)
    ..lineTo(ft.dx, ft.dy)
    ..lineTo(lt.dx, lt.dy)
    ..close();
  final izquierda = Path()
    ..moveTo(lt.dx, lt.dy)
    ..lineTo(ft.dx, ft.dy)
    ..lineTo(fb.dx, fb.dy)
    ..lineTo(lb.dx, lb.dy)
    ..close();
  final derecha = Path()
    ..moveTo(rt.dx, rt.dy)
    ..lineTo(ft.dx, ft.dy)
    ..lineTo(fb.dx, fb.dy)
    ..lineTo(rb.dx, rb.dy)
    ..close();

  final borde = Paint()
    ..color = _colorBorde(colorPared)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0;

  canvas.drawPath(techo, Paint()..color = _colorTecho(colorPared));
  canvas.drawPath(izquierda, Paint()..color = _sombrear(colorPared, 0.7));
  canvas.drawPath(derecha, Paint()..color = colorPared);
  canvas.drawPath(techo, borde);
  canvas.drawPath(izquierda, borde);
  canvas.drawPath(derecha, borde);

  final rellenoVentana = Paint()..color = _colorVentana(colorPared);
  final bordeVentana = Paint()
    ..color = _colorBorde(colorPared)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.5;

  for (final (u0, v0, u1, v1) in ventanasIzquierda) {
    _dibujarVentana(
      canvas, lt, ft, fb, lb,
      u0: u0, v0: v0, u1: u1, v1: v1,
      relleno: rellenoVentana, borde: bordeVentana,
    );
  }
  for (final (u0, v0, u1, v1) in ventanasDerecha) {
    _dibujarVentana(
      canvas, rt, ft, fb, rb,
      u0: u0, v0: v0, u1: u1, v1: v1,
      relleno: rellenoVentana, borde: bordeVentana,
    );
  }
}

// ---------------------------------------------------------------------
// Genérico: tres edificios de distinta altura, compartiendo el mismo piso.
// ---------------------------------------------------------------------
class _GenericClusterPainter extends CustomPainter {
  final Color color;
  _GenericClusterPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final sueloY = h * 0.98;

    _dibujarEdificio(
      canvas,
      xCentro: w * 0.2, ancho: w * 0.35, alto: h * 0.8, sueloY: sueloY,
      colorPared: _sombrear(color, 0.75),
      ventanasIzquierda: const [(0.25, 0.55, 0.5, 0.75)],
    );
    _dibujarEdificio(
      canvas,
      xCentro: w * 0.55, ancho: w * 0.25, alto: h * 0.55, sueloY: sueloY,
      colorPared: color,
      ventanasDerecha: const [(0.3, 0.45, 0.6, 0.65)],
    );
    _dibujarEdificio(
      canvas,
      xCentro: w * 0.85, ancho: w * 0.28, alto: h * 0.7, sueloY: sueloY,
      colorPared: _sombrear(color, 0.9),
      ventanasIzquierda: const [(0.3, 0.5, 0.6, 0.7)],
    );
  }

  @override
  bool shouldRepaint(covariant _GenericClusterPainter old) => old.color != color;
}

// ---------------------------------------------------------------------
// Auditorio: edificio ancho con techo curvo.
// ---------------------------------------------------------------------
class _AuditorioPainter extends CustomPainter {
  final Color color;
  _AuditorioPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final ancho = w * 0.7, alto = h * 0.7;
    final xCentro = w * 0.5;
    final yBase = h * 0.05;
    final roofH = alto * 0.25;

    final apex = Offset(xCentro, yBase);
    final rt = Offset(xCentro + ancho / 2, yBase + roofH * 0.5);
    final lt = Offset(xCentro - ancho / 2, yBase + roofH * 0.5);
    final ft = Offset(xCentro, yBase + roofH);
    final rb = Offset(xCentro + ancho / 2, yBase + alto);
    final lb = Offset(xCentro - ancho / 2, yBase + alto);
    final fb = Offset(xCentro, yBase + alto);

    final techo = Path()..moveTo(apex.dx, apex.dy);
    techo.quadraticBezierTo(rt.dx, apex.dy, rt.dx, rt.dy);
    techo.lineTo(ft.dx, ft.dy);
    techo.quadraticBezierTo(lt.dx, apex.dy, lt.dx, lt.dy);
    techo.close();

    final izquierda = Path()
      ..moveTo(lt.dx, lt.dy)
      ..lineTo(ft.dx, ft.dy)
      ..lineTo(fb.dx, fb.dy)
      ..lineTo(lb.dx, lb.dy)
      ..close();
    final derecha = Path()
      ..moveTo(rt.dx, rt.dy)
      ..lineTo(ft.dx, ft.dy)
      ..lineTo(fb.dx, fb.dy)
      ..lineTo(rb.dx, rb.dy)
      ..close();

    final borde = Paint()
      ..color = _colorBorde(color)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawPath(techo, Paint()..color = _colorTecho(color));
    canvas.drawPath(izquierda, Paint()..color = _sombrear(color, 0.7));
    canvas.drawPath(derecha, Paint()..color = color);
    canvas.drawPath(techo, borde);
    canvas.drawPath(izquierda, borde);
    canvas.drawPath(derecha, borde);

    final rellenoVentana = Paint()..color = _colorVentana(color);
    final bordeVentana = Paint()
      ..color = _colorBorde(color)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    // Ventanas alargadas horizontales, ya inclinadas según cada cara.
    for (final v in [0.4, 0.65]) {
      _dibujarVentana(canvas, lt, ft, fb, lb,
          u0: 0.25, v0: v, u1: 0.55, v1: v + 0.15,
          relleno: rellenoVentana, borde: bordeVentana);
      _dibujarVentana(canvas, rt, ft, fb, rb,
          u0: 0.25, v0: v, u1: 0.55, v1: v + 0.15,
          relleno: rellenoVentana, borde: bordeVentana);
    }
  }

  @override
  bool shouldRepaint(covariant _AuditorioPainter old) => old.color != color;
}

// ---------------------------------------------------------------------
// Coliseo: forma ovalada, con anillos concéntricos para simular
// graderías (en vez de líneas radiando hacia el centro, que se veían
// más como una telaraña que como un estadio).
// ---------------------------------------------------------------------
class _ColiseoPainter extends CustomPainter {
  final Color color;
  _ColiseoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final centro = Offset(w * 0.5, h * 0.6);
    final anchoBase = w * 0.65, altoBase = h * 0.5;

    final borde = Paint()
      ..color = _colorBorde(color)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final exterior = Rect.fromCenter(center: centro, width: anchoBase, height: altoBase);
    canvas.drawOval(exterior, Paint()..color = color);
    canvas.drawOval(exterior, borde);

    // Anillos de graderías.
    for (final factor in [0.78, 0.56]) {
      final anillo = Rect.fromCenter(
        center: centro,
        width: anchoBase * factor,
        height: altoBase * factor,
      );
      canvas.drawOval(anillo, borde);
    }

    // Cancha/techo central.
    final campo = Rect.fromCenter(
      center: centro,
      width: anchoBase * 0.34,
      height: altoBase * 0.34,
    );
    canvas.drawOval(campo, Paint()..color = _colorTecho(color));
    canvas.drawOval(campo, borde);
  }

  @override
  bool shouldRepaint(covariant _ColiseoPainter old) => old.color != color;
}

// ---------------------------------------------------------------------
// Laboratorio: edificio bajo con chimeneas.
// ---------------------------------------------------------------------
class _LaboratorioPainter extends CustomPainter {
  final Color color;
  _LaboratorioPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final sueloY = h * 0.9;

    _dibujarEdificio(
      canvas,
      xCentro: w * 0.5, ancho: w * 0.6, alto: h * 0.55, sueloY: sueloY,
      colorPared: color,
      proporcionTecho: 0.15,
      ventanasIzquierda: const [(0.25, 0.5, 0.5, 0.75)],
      ventanasDerecha: const [(0.5, 0.5, 0.75, 0.75)],
    );

    // Chimeneas sobre el techo, ya con la altura correcta ahora que el
    // edificio está apoyado en `sueloY` y no "flotando" desde y=0.
    final techoY = sueloY - h * 0.55;
    final chimPaint = Paint()..color = _conAlphaRelativa(Colors.grey.shade700, color, 1.0);
    final chimBorde = Paint()
      ..color = _colorBorde(color)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    final chimW = w * 0.06, chimH = h * 0.14;

    for (final dx in [-w * 0.12, w * 0.08]) {
      final chimRect = Rect.fromLTWH(
        w * 0.5 + dx - chimW / 2,
        techoY - chimH,
        chimW,
        chimH,
      );
      canvas.drawRect(chimRect, chimPaint);
      canvas.drawRect(chimRect, chimBorde);
    }
  }

  @override
  bool shouldRepaint(covariant _LaboratorioPainter old) => old.color != color;
}