// lib/widgets/chat_widgets.dart
//
// Widgets de presentación puros: reciben datos ya listos y los dibujan.
// No conocen nada sobre reconocimiento de voz ni sobre el motor de rutas,
// lo que los hace reutilizables y fáciles de ajustar visualmente sin tocar
// la lógica de `ChatScreen`.

import 'package:flutter/material.dart';

import '../models/chat_models.dart';
import '../utils/color_utils.dart';

/// Una burbuja de chat estándar (usuario o bot).
class ChatBubble extends StatelessWidget {
  final bool esUsuario;
  final String texto;

  const ChatBubble({super.key, required this.esUsuario, required this.texto});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: esUsuario ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: esUsuario ? theme.colorScheme.primary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(esUsuario ? 18 : 4),
            bottomRight: Radius.circular(esUsuario ? 4 : 18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.conOpacidad(0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          texto,
          style: TextStyle(
            color: esUsuario ? Colors.white : Colors.black87,
            fontSize: 14.5,
            height: 1.35,
          ),
        ),
      ),
    );
  }
}

/// Indicador de "el bot está escribiendo..." (los tres puntos animados).
class TypingIndicator extends StatelessWidget {
  const TypingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: SizedBox(
          width: 32,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(3, (index) {
              return Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.conOpacidad(0.4),
                  shape: BoxShape.circle,
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

/// Tarjeta que muestra una ruta calculada exitosamente.
class RouteCard extends StatelessWidget {
  final RouteFound ruta;

  const RouteCard({super.key, required this.ruta});

  // Velocidad promedio de caminata (metros por segundo)
  static const double _velocidadCaminata = 1.4;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pasos = ruta.pasos;
    // Tiempo estimado en minutos
    final minutos = (ruta.distanciaMetros / _velocidadCaminata) / 60;
    final tiempoFormateado = minutos < 1
        ? '${(minutos * 60).round()} seg'
        : '${minutos.toStringAsFixed(1)} min';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.secondary.conOpacidad(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.conOpacidad(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary.conOpacidad(0.08),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.assistant_direction_rounded,
                  color: theme.colorScheme.secondary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Ruta Peatonal Trazada',
                  style: TextStyle(
                    color: theme.colorScheme.secondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                  ),
                ),
              ],
            ),
          ),
          // Cuerpo con línea de tiempo
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Punto de origen
                _buildPaso(
                  icono: Icons.radio_button_checked,
                  colorIcono: Colors.blue,
                  texto: ruta.origenNombre,
                  esDestacado: true,
                ),
                // Pasos intermedios (si hay más de 2)
                if (pasos.length > 2) ...[
                  for (int i = 1; i < pasos.length - 1; i++)
                    _buildPasoIntermedio(
                      nombre: pasos[i],
                      // Distancia entre el paso anterior y este (no tenemos directamente,
                      // podemos calcularla con la heurística o mostrar "—").
                      // Para simplificar, mostraremos un guion porque no tenemos el desglose exacto.
                      // Más adelante, al integrar mapa, podrás obtener las distancias reales.
                      distancia: null,
                    ),
                ],
                // Punto de destino (último paso)
                _buildPaso(
                  icono: Icons.location_on,
                  colorIcono: theme.colorScheme.secondary,
                  texto: ruta.destinoNombre,
                  esDestacado: true,
                  esUltimo: true,
                ),
                const Divider(height: 24),
                // Resumen de distancia y tiempo
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.timer_outlined, size: 18, color: Colors.grey[600]),
                        const SizedBox(width: 6),
                        Text(
                          '~$tiempoFormateado',
                          style: TextStyle(
                            fontSize: 13.5,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.conOpacidad(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${ruta.distanciaMetros.toStringAsFixed(1)} m',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Construye un paso de la línea de tiempo (origen o destino).
  Widget _buildPaso({
    required IconData icono,
    required Color colorIcono,
    required String texto,
    bool esDestacado = false,
    bool esUltimo = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Columna del icono y línea conectora
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Icon(icono, color: colorIcono, size: esDestacado ? 20 : 16),
                if (!esUltimo)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: Colors.grey[300],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: esUltimo ? 0 : 12),
              child: Text(
                texto,
                style: TextStyle(
                  fontWeight: esDestacado ? FontWeight.w600 : FontWeight.normal,
                  fontSize: esDestacado ? 14.5 : 13.5,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Construye un paso intermedio (punto gris y nombre sin destacar).
  Widget _buildPasoIntermedio({
    required String nombre,
    double? distancia,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                const SizedBox(height: 6), // Alineación visual con el icono
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey[400],
                  ),
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    color: Colors.grey[300],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      nombre,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                  if (distancia != null)
                    Text(
                      '${distancia.toStringAsFixed(1)} m',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Carrusel horizontal de chips con rutas sugeridas.
class SuggestionsCarousel extends StatelessWidget {
  final List<RouteSuggestion> sugerencias;
  final void Function(RouteSuggestion sugerencia) onSeleccionar;

  const SuggestionsCarousel({
    super.key,
    required this.sugerencias,
    required this.onSeleccionar,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        children: [
          for (final sugerencia in sugerencias)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: ActionChip(
                label: Text(
                  sugerencia.etiqueta,
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                backgroundColor: Colors.white,
                elevation: 1,
                shadowColor: Colors.black.conOpacidad(0.1),
                side: BorderSide(color: theme.colorScheme.primary.conOpacidad(0.15)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                onPressed: () => onSeleccionar(sugerencia),
              ),
            ),
        ],
      ),
    );
  }
}

/// Consola de entrada inferior: campo de texto + botón de micrófono +
/// botón de enviar.
class InputConsole extends StatelessWidget {
  final TextEditingController controller;
  final bool escuchando;
  final bool enviando;
  final VoidCallback onMicPressed;
  final VoidCallback onEnviarPressed;

  const InputConsole({
    super.key,
    required this.controller,
    required this.escuchando,
    required this.enviando,
    required this.onMicPressed,
    required this.onEnviarPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
      child: Container(
        decoration: BoxDecoration(
          color: escuchando ? theme.colorScheme.primary.conOpacidad(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: escuchando
              ? Border.all(
                  color: theme.colorScheme.primary.conOpacidad(0.3),
                  width: 1.5,
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.conOpacidad(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            IconButton(
              icon: Icon(
                escuchando ? Icons.mic_rounded : Icons.mic_none_rounded,
                color: escuchando ? Colors.redAccent : Colors.black54,
                size: 24,
              ),
              onPressed: onMicPressed,
            ),
            Expanded(
              child: TextField(
                controller: controller,
                enabled: !enviando && !escuchando,
                textCapitalization: TextCapitalization.sentences,
                style: TextStyle(
                  fontSize: 15,
                  color: escuchando ? theme.colorScheme.primary : Colors.black87,
                ),
                decoration: InputDecoration(
                  hintText: escuchando
                      ? 'Escuchando... habla ahora'
                      : 'Ej: De Veterinaria al Coliseo',
                  border: InputBorder.none,
                  hintStyle: TextStyle(
                    color: escuchando
                        ? theme.colorScheme.primary.conOpacidad(0.5)
                        : Colors.black38,
                    fontSize: 14,
                  ),
                ),
                onSubmitted: (_) => onEnviarPressed(),
              ),
            ),
            if (!escuchando)
              Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: enviando ? Colors.grey : theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_upward_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: enviando ? null : onEnviarPressed,
                ),
              ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}