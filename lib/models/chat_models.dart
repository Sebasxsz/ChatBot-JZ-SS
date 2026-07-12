// lib/models/chat_models.dart
//
// Modelos de datos puros (sin dependencias de Flutter) para el chat y para
// el resultado del motor de interpretación de rutas.
//
// Antes, la comunicación entre la lógica y la UI se hacía codificando todo
// en un solo String con separadores "::" (ej. "ROUTE_SUCCESS::A::B::..."),
// lo cual es frágil: un error de tipeo en el separador, o un nombre que
// contenga "::", rompe el parseo silenciosamente. Usar clases selladas
// (`sealed class`) logra lo mismo de forma segura: el compilador obliga a
// manejar todos los casos posibles en cada `switch`.

/// Un mensaje dentro de la conversación del chat.
class ChatMessage {
  final String texto;
  final bool esUsuario;

  /// Solo presente en mensajes del bot que representan una ruta calculada.
  /// Cuando es un [RouteFound], la UI lo muestra como una tarjeta de ruta
  /// en vez de una burbuja de texto normal.
  final RouteResult? resultado;

  const ChatMessage.usuario(this.texto)
    : esUsuario = true,
      resultado = null;

  const ChatMessage.bot(this.texto, {this.resultado}) : esUsuario = false;
}

/// Resultado devuelto por `RouteEngine.interpretarMensaje`.
sealed class RouteResult {
  const RouteResult();
}

/// Se encontró una ruta válida entre dos puntos del campus.
class RouteFound extends RouteResult {
  final String origenNombre;
  final String destinoNombre;
  final List<String> pasos;
  final double distanciaMetros;

  const RouteFound({
    required this.origenNombre,
    required this.destinoNombre,
    required this.pasos,
    required this.distanciaMetros,
  });
}

/// Ambos lugares existen en el grafo, pero no hay camino entre ellos.
class RouteNotFound extends RouteResult {
  final String origenNombre;
  final String destinoNombre;

  const RouteNotFound({
    required this.origenNombre,
    required this.destinoNombre,
  });
}

/// Solo se detectó un lugar en el mensaje; falta el origen o el destino.
class NeedsMoreInfo extends RouteResult {
  final String lugarNombre;

  const NeedsMoreInfo(this.lugarNombre);
}

/// No se pudo identificar ningún lugar conocido en el mensaje.
class NotUnderstood extends RouteResult {
  const NotUnderstood();
}

/// Convierte un [RouteResult] en el texto que debe mostrarse en una burbuja
/// de chat normal. Los [RouteFound] no usan este texto: se muestran con el
/// widget `RouteCard` en su lugar (ver `resultado` en [ChatMessage]).
extension RouteResultMensaje on RouteResult {
  String get mensaje => switch (this) {
    RouteFound() => '',
    RouteNotFound(origenNombre: final origen, destinoNombre: final destino) =>
      'No encontré un camino entre $origen y $destino.',
    NeedsMoreInfo(lugarNombre: final lugar) =>
      'Detecté "$lugar", pero necesito también el otro punto de tu '
          'recorrido. Por ejemplo: "de $lugar al coliseo".',
    NotUnderstood() =>
      'No entendí la ruta hablada. Intenta decir algo claro como: '
          '"Llevarme de administración a agrícola".',
  };
}

/// Una sugerencia rápida de ruta mostrada como chip debajo del chat.
typedef RouteSuggestion = ({String etiqueta, String origen, String destino});