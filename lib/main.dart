import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart'
    as stt; // 🎙️ Paquete de voz
import 'campus_data.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chatbot Ruta Óptima ESPAM-MFL',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff0d47a1),
          primary: const Color(0xff1565c0),
          secondary: const Color(0xff00a86b),
          surface: Colors.white,
        ),
      ),
      home: const ChatScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _estaEscribiendo = false;

  // 🎙️ Variables de control para el reconocimiento de voz
  late stt.SpeechToText _speech;
  bool _esEscuchando = false;
  String _textoDictado = "";
  String _currentLocaleId = "es-ES";

  final List<Map<String, String>> sugerencias = [
    {'text': '🏫 Vet ➔ Auditorio', 'from': 'VET', 'to': 'AUD'},
    {'text': '💼 Admin ➔ Agrícola', 'from': 'ADM', 'to': 'AGR'},
    {'text': '💻 Comp ➔ Coliseo', 'from': 'COM', 'to': 'COL'},
  ];

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText(); // Instanciar motor
    _preInicializarMicrofono(); // Inicializarlo una sola vez de fondo

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _messages.add({
            'type': 'bot',
            'text':
                '¡Hola! 🤖 Soy tu asistente de rutas.\n\nPuedes escribirme o presionar el micrófono abajo para decirme a dónde quieres ir de forma hablada.',
          });
        });
      }
    });
  }

  // Nueva función para dejar el micrófono listo y capturar errores en la consola
  void _preInicializarMicrofono() async {
    try {
      bool disponible = await _speech.initialize(
        onStatus: (val) {
          if (val == 'done' || val == 'notListening') {
            if (mounted) {
              setState(() => _esEscuchando = false);
            }
          }
        },
        onError: (val) {
          debugPrint(
            "🎙️ Error del Microfono: ${val.errorMsg} - Permanente: ${val.permanent}",
          );
          if (mounted) {
            setState(() => _esEscuchando = false);
          }
        },
      );

      // ✨ CORREGIDO: Cambiados los .id por .localeId
      if (disponible) {
        String idiomaDestino = 'es-ES'; // Fallback por defecto
        var systemLocales = await _speech.locales();

        for (var loc in systemLocales) {
          if (loc.localeId.contains('es-EC') ||
              loc.localeId.contains('es_EC')) {
            idiomaDestino =
                loc.localeId; // Si encuentra Ecuador, elige este de una
            break;
          } else if (loc.localeId.toLowerCase().startsWith('es')) {
            idiomaDestino = loc
                .localeId; // Guarda cualquier otra variante de español como plan B
          }
        }

        setState(() {
          _currentLocaleId = idiomaDestino;
        });
        debugPrint("🎙️ Micrófono listo. Idioma asignado: $_currentLocaleId");
      }
    } catch (e) {
      debugPrint("🎙️ Excepción al inicializar micrófono: $e");
    }
  }

  void _escucharVoz() async {
    if (!_speech.isAvailable) {
      _preInicializarMicrofono();
      debugPrint("🎙️ El micrófono no está listo o no tiene permisos.");
      return;
    }

    if (!_esEscuchando) {
      setState(() {
        _esEscuchando = true;
        _textoDictado = "";
      });

      _speech.listen(
        // Usamos el idioma dinámico que encontramos en el paso anterior
        listenOptions: stt.SpeechListenOptions(localeId: _currentLocaleId),
        onResult: (val) {
          // 🔥 CANDADO DE SEGURIDAD: Si ya se procesó el cierre, ignora ráfagas duplicadas
          if (!_esEscuchando) return;

          setState(() {
            _textoDictado = val.recognizedWords;
            _controller.text = _textoDictado;
          });

          if (val.finalResult && _textoDictado.isNotEmpty) {
            setState(
              () => _esEscuchando = false,
            ); // Apagamos el candado INMEDIATAMENTE
            _speech.stop();
            _enviarMensaje(); // Envía el mensaje de forma segura una sola vez
          }
        },
      );
    } else {
      setState(() => _esEscuchando = false);
      _speech.stop();
      if (_textoDictado.isNotEmpty) {
        _enviarMensaje();
      }
    }
  }

  void _enviarMensaje({String? textoPredefinido}) {
    String texto = textoPredefinido ?? _controller.text.trim();
    if (texto.isEmpty) return;

    setState(() {
      _messages.add({'type': 'user', 'text': texto});
      _estaEscribiendo = true;
    });

    if (textoPredefinido == null) _controller.clear();
    _textoDictado = "";
    _animatedScroll();

    Future.delayed(const Duration(milliseconds: 1200), () {
      String respuesta = procesarMensaje(texto.toLowerCase());
      if (mounted) {
        setState(() {
          _messages.add({'type': 'bot', 'text': respuesta});
          _estaEscribiendo = false;
        });
        _animatedScroll();
      }
    });
  }

  void _animatedScroll() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String procesarMensaje(String msg) {
    String textoLimpio = msg.toLowerCase().trim();
    String? inicio, destino;
    Map<String, int> lugaresEncontrados = {};

    sinonimos.forEach((nodo, listaSinonimos) {
      for (var sinonimo in listaSinonimos) {
        // Escapamos caracteres especiales por si acaso
        String patron = RegExp.escape(sinonimo);
        // Exigimos que no haya letras/dígitos inmediatamente antes o después (incluye acentos y ñ)
        RegExp regExp = RegExp(
          '(?<![a-zA-Z0-9áéíóúüñÁÉÍÓÚÜÑ])$patron(?![a-zA-Z0-9áéíóúüñÁÉÍÓÚÜÑ])',
          caseSensitive: false,
        );
        Match? match = regExp.firstMatch(textoLimpio);
        if (match != null) {
          int index = match.start;
          if (!lugaresEncontrados.containsKey(nodo)) {
            lugaresEncontrados[nodo] = index;
          }
          break; // tomamos solo el primer sinónimo que coincida
        }
      }
    });

    if (lugaresEncontrados.length < 2) {
      // Busca palabras completas que coincidan con claves de 'nombres' (VET, COM, etc.)
      RegExp expSiglas = RegExp(
        '\\b(${nombres.keys.join('|')})\\b',
        caseSensitive: false,
      );
      for (var match in expSiglas.allMatches(textoLimpio)) {
        String clave = match.group(0)!.toUpperCase();
        if (!lugaresEncontrados.containsKey(clave)) {
          lugaresEncontrados[clave] = match.start;
        }
      }
    }

    if (lugaresEncontrados.length >= 2) {
      var nodos = lugaresEncontrados.keys.toList();
      String nodoX = nodos[0];
      String nodoY = nodos[1];
      int posX = lugaresEncontrados[nodoX]!;
      int posY = lugaresEncontrados[nodoY]!;

      final conectoresOrigen = [
        'desde',
        'salgo de',
        'parto de',
        'vengo de',
        'de',
      ];
      final conectoresDestino = [
        'hasta el',
        'hasta la',
        'para el',
        'para la',
        'hasta',
        'para',
        'hacia',
        'al',
        'a',
      ];

      String? conectorAntesDe(String lugar, List<String> conectores) {
        int idx = lugaresEncontrados[lugar]!;
        int startSearch = idx - 30 < 0 ? 0 : idx - 30;
        String fragmento = textoLimpio.substring(startSearch, idx);
        for (var con in conectores) {
          if (fragmento.endsWith('$con ') || fragmento.endsWith(con)) {
            return con;
          }
        }
        return null;
      }

      if (conectorAntesDe(nodoX, conectoresOrigen) != null) {
        inicio = nodoX;
        destino = nodoY;
      } else if (conectorAntesDe(nodoY, conectoresOrigen) != null) {
        inicio = nodoY;
        destino = nodoX;
      } else if (conectorAntesDe(nodoX, conectoresDestino) != null) {
        inicio = nodoY;
        destino = nodoX;
      } else if (conectorAntesDe(nodoY, conectoresDestino) != null) {
        inicio = nodoX;
        destino = nodoY;
      } else {
        if (posX < posY) {
          inicio = nodoX;
          destino = nodoY;
        } else {
          inicio = nodoY;
          destino = nodoX;
        }
      }
    }

    if (inicio != null && destino != null && inicio != destino) {
      final resultado = algoritmoAEstrella(inicio, destino);
      List<String> ruta = resultado['ruta'];

      if (ruta.isEmpty) {
        return "ROUTE_NOT_FOUND::${nombres[inicio]}::${nombres[destino]}";
      }

      List<String> rutaNombres = ruta.map((n) => nombres[n] ?? n).toList();
      String pasos = rutaNombres.join(" ➔ ");
      return "ROUTE_SUCCESS::${nombres[inicio]}::${nombres[destino]}::$pasos::${resultado['costo'].toStringAsFixed(1)}";
    }

    if (lugaresEncontrados.length == 1) {
      return "NEED_INFO::${nombres[lugaresEncontrados.keys.first]}";
    }

    return "ERROR_NOT_UNDERSTOOD";
  }

  double _calcularHeuristica(String nodoActual, String nodoDestino) {
    final p1 = coordenadas[nodoActual]!;
    final p2 = coordenadas[nodoDestino]!;
    double dLat = (p2.$1 - p1.$1) * math.pi / 180.0;
    double dLon = (p2.$2 - p1.$2) * math.pi / 180.0;
    double a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(p1.$1 * math.pi / 180.0) *
            math.cos(p2.$1 * math.pi / 180.0) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return 6371000 * (2 * math.atan2(math.sqrt(a), math.sqrt(1 - a)));
  }

  Map<String, dynamic> algoritmoAEstrella(String start, String end) {
    final gScore = <String, double>{
      for (var k in grafo.keys) k: double.infinity,
    };
    final fScore = <String, double>{
      for (var k in grafo.keys) k: double.infinity,
    };
    final prev = <String, String?>{};
    final openSet = <(double, String)>[];

    gScore[start] = 0;
    fScore[start] = _calcularHeuristica(start, end);
    openSet.add((fScore[start]!, start));

    while (openSet.isNotEmpty) {
      openSet.sort((a, b) => a.$1.compareTo(b.$1));
      final (_, u) = openSet.removeAt(0);
      if (u == end) break;
      if (!grafo.containsKey(u)) continue;

      for (var v in grafo[u]!) {
        double tentativeGScore = gScore[u]! + v['costo'];
        if (tentativeGScore < gScore[v['to']]!) {
          prev[v['to']] = u;
          gScore[v['to']] = tentativeGScore;
          fScore[v['to']] =
              gScore[v['to']]! + _calcularHeuristica(v['to'], end);
          if (!openSet.any((element) => element.$2 == v['to'])) {
            openSet.add((fScore[v['to']]!, v['to']));
          }
        }
      }
    }

    List<String> path = [];
    String? current = end;
    while (current != null) {
      path.add(current);
      current = prev[current];
    }
    path = path.reversed.toList();
    return {'ruta': path.length > 1 ? path : [], 'costo': gScore[end]!};
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'ESPAM-MFL Navegación',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            Text(
              _esEscuchando
                  ? '🎙️ Escuchando tu voz...'
                  : 'Inteligencia de Rutas Críticas',
              style: TextStyle(
                fontSize: 11,
                color: _esEscuchando
                    ? Colors.greenAccent
                    : Colors.white.withAlpha((0.7 * 255).round()),
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: _esEscuchando
            ? const Color(0xff0a2540)
            : theme.colorScheme.primary,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Listado de Mensajes
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                reverse: true,
                itemCount: _messages.length + (_estaEscribiendo ? 1 : 0),
                itemBuilder: (context, index) {
                  if (_estaEscribiendo && index == 0) {
                    return _buildTypingIndicator(theme);
                  }
                  final actualIndex = _estaEscribiendo ? index - 1 : index;
                  final msg = _messages[_messages.length - 1 - actualIndex];
                  bool esUsuario = msg['type'] == 'user';
                  String rawText = msg['text']!;

                  if (!esUsuario && rawText.startsWith("ROUTE_SUCCESS")) {
                    var data = rawText.split("::");
                    return _buildRouteCard(
                      theme,
                      data[1],
                      data[2],
                      data[3],
                      data[4],
                    );
                  }
                  return _buildStandardBubble(theme, esUsuario, rawText);
                },
              ),
            ),

            // Chips Horizontales de Sugerencias
            if (!_esEscuchando) _buildSuggestionsCarousel(theme),

            // ⌨️ Consola de Entrada Premium Modularizada (Soporta Voz y Texto)
            _buildInputConsole(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionsCarousel(ThemeData theme) {
    return Container(
      height: 44,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        children: sugerencias.map((sug) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: ActionChip(
              label: Text(
                sug['text']!,
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              backgroundColor: Colors.white,
              elevation: 1,
              shadowColor: Colors.black.withAlpha((0.1 * 255).round()),
              side: BorderSide(
                color: theme.colorScheme.primary.withAlpha(
                  (0.15 * 255).round(),
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              onPressed: () => _enviarMensaje(
                textoPredefinido: "${sug['from']} a ${sug['to']}",
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Consola de entrada de datos adaptativa
  Widget _buildInputConsole(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
      child: Container(
        decoration: BoxDecoration(
          color: _esEscuchando
              ? theme.colorScheme.primary.withAlpha((0.05 * 255).round())
              : Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: _esEscuchando
              ? Border.all(
                  color: theme.colorScheme.primary.withAlpha(
                    (0.3 * 255).round(),
                  ),
                  width: 1.5,
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((0.05 * 255).round()),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Botón de micrófono izquierdo interactivo
            IconButton(
              icon: Icon(
                _esEscuchando ? Icons.mic_rounded : Icons.mic_none_rounded,
                color: _esEscuchando ? Colors.redAccent : Colors.black54,
                size: 24,
              ),
              onPressed: _escucharVoz,
            ),
            Expanded(
              child: TextField(
                controller: _controller,
                enabled: !_estaEscribiendo && !_esEscuchando,
                textCapitalization: TextCapitalization.sentences,
                style: TextStyle(
                  fontSize: 15,
                  color: _esEscuchando
                      ? theme.colorScheme.primary
                      : Colors.black87,
                ),
                decoration: InputDecoration(
                  hintText: _esEscuchando
                      ? "Escuchando... habla ahora"
                      : "Ej: De Veterinaria al Coliseo",
                  border: InputBorder.none,
                  hintStyle: TextStyle(
                    color: _esEscuchando
                        ? theme.colorScheme.primary.withAlpha(
                            (0.5 * 255).round(),
                          )
                        : Colors.black38,
                    fontSize: 14,
                  ),
                ),
                onSubmitted: (_) => _enviarMensaje(),
              ),
            ),
            if (!_esEscuchando)
              Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: _estaEscribiendo
                      ? Colors.grey
                      : theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_upward_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: _estaEscribiendo ? null : () => _enviarMensaje(),
                ),
              ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildStandardBubble(ThemeData theme, bool esUsuario, String texto) {
    String renderText = texto
        .replaceAll("ROUTE_NOT_FOUND::", "")
        .replaceAll("NEED_INFO::", "")
        .replaceAll(
          "ERROR_NOT_UNDERSTOOD",
          "No entendí la ruta hablada. Intenta decir algo claro como: 'Llevarme de administración a agrícola'.",
        );

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
              color: Colors.black.withAlpha((0.02 * 255).round()),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          renderText,
          style: TextStyle(
            color: esUsuario ? Colors.white : Colors.black87,
            fontSize: 14.5,
            height: 1.35,
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator(ThemeData theme) {
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
                  color: theme.colorScheme.primary.withAlpha(
                    (0.4 * 255).round(),
                  ),
                  shape: BoxShape.circle,
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildRouteCard(
    ThemeData theme,
    String origen,
    String destino,
    String pasos,
    String distancia,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.secondary.withAlpha((0.2 * 255).round()),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.03 * 255).round()),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary.withAlpha(
                (0.08 * 255).round(),
              ),
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.radio_button_checked,
                      color: Colors.blue,
                      size: 16,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        origen,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
                Container(
                  margin: const EdgeInsets.only(left: 7),
                  height: 20,
                  width: 2,
                  color: Colors.grey[300],
                ),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: theme.colorScheme.secondary,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        destino,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                const Text(
                  'RECORRIDO ÓPTIMO',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.black38,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  pasos,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: Colors.grey[800],
                    height: 1.4,
                  ),
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Distancia Calculada:',
                      style: TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withAlpha(
                          (0.08 * 255).round(),
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$distancia metros',
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
}
