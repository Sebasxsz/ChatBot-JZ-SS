// lib/utils/color_utils.dart
//
// Antes, cada widget calculaba la opacidad manualmente con
// `color.withAlpha((0.x * 255).round())`, repetido decenas de veces.
// Esta extensión lo deja en una sola línea legible: `color.conOpacidad(0.1)`.

import 'package:flutter/material.dart';

extension ColorOpacity on Color {
  Color conOpacidad(double opacidad) => withAlpha((opacidad * 255).round());
}