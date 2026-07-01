import 'dart:math' as math;
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chatbot Ruta Óptima',
      theme: ThemeData(primarySwatch: Colors.indigo, useMaterial3: true),
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
  final List<Map<String, String>> _messages = [];

  final Map<String, String> nombres = {
    'A': 'Entrada Principal',
    'B': 'Edificio Administrativo',
    'C': 'Laboratorio 1',
    'D': 'Almacén',
    'E': 'Planta de Producción',
    'F': 'Comedor',
    'G': 'Estacionamiento',
  };

  // 🌟 NUEVO: Diccionario de sinónimos para NLP
  final Map<String, List<String>> sinonimos = {
    'A': [
      'entrada',
      'entrada principal',
      'puerta',
      'ingreso',
      'acceso',
      'porton',
      'recepción',
      'recepcion'
    ],
    'B': [
      'administrativo',
      'edificio administrativo',
      'admin',
      'oficinas',
      'bloque administrativo',
      'administración',
      'administracion'
    ],
    'C': [
      'laboratorio',
      'lab',
      'laboratorio 1',
      'laboratorios',
      'lab 1',
      'laboratorio uno'
    ],
    'D': [
      'almacen',
      'almacén',
      'bodega',
      'deposito',
      'depósito',
      'almacen central',
      'almacén central',
      'stock'
    ],
    'E': [
      'planta',
      'produccion',
      'producción',
      'planta de produccion',
      'planta de producción',
      'fabrica',
      'fábrica',
      'manufactura'
    ],
    'F': [
      'comedor',
      'cafeteria',
      'cafetería',
      'restaurante',
      'comida',
      'almuerzo',
      'desayuno',
      'cena'
    ],
    'G': [
      'estacionamiento',
      'parqueadero',
      'parking',
      'parqueo',
      'estacionar',
      'garaje',
      'aparcamiento'
    ],
  };

  final Map<String, List<Map<String, dynamic>>> grafo = {
    'A': [
      {'to': 'B', 'costo': 40},
      {'to': 'C', 'costo': 60},
      {'to': 'G', 'costo': 30},
    ],
    'B': [
      {'to': 'A', 'costo': 40},
      {'to': 'C', 'costo': 25},
      {'to': 'D', 'costo': 50},
    ],
    'C': [
      {'to': 'A', 'costo': 60},
      {'to': 'B', 'costo': 25},
      {'to': 'E', 'costo': 35},
    ],
    'D': [
      {'to': 'B', 'costo': 50},
      {'to': 'E', 'costo': 20},
      {'to': 'F', 'costo': 45},
    ],
    'E': [
      {'to': 'C', 'costo': 35},
      {'to': 'D', 'costo': 20},
      {'to': 'F', 'costo': 30},
    ],
    'F': [
      {'to': 'D', 'costo': 45},
      {'to': 'E', 'costo': 30},
      {'to': 'G', 'costo': 55},
    ],
    'G': [
      {'to': 'A', 'costo': 30},
      {'to': 'F', 'costo': 55},
    ],
  };

  // Coordenadas a escala para la heurística de línea recta
  final Map<String, (double, double)> coordenadas = {
    'A': (0.0, 0.0),
    'B': (4.0, 4.0),
    'C': (6.0, 2.0),
    'D': (10.0, 8.0),
    'E': (8.0, 12.0),
    'F': (4.0, 10.0),
    'G': (2.0, 5.0),
  };

  final List<Map<String, String>> sugerencias = [
    {'text': 'Entrada → Planta', 'from': 'A', 'to': 'E'},
    {'text': 'Admin → Comedor', 'from': 'B', 'to': 'F'},
    {'text': 'Lab → Almacén', 'from': 'C', 'to': 'D'},
    {'text': 'Entrada → Estacionamiento', 'from': 'A', 'to': 'G'},
    {'text': 'Planta → Comedor', 'from': 'E', 'to': 'F'},
    {'text': 'Almacén → Entrada', 'from': 'D', 'to': 'A'},
  ];

  @override
  void initState() {
    super.initState();
    // Mensaje de bienvenida
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _messages.add({
          'type': 'bot',
          'text':
              '👋 ¡Hola! Soy tu asistente de rutas.\n\n'
              'Puedes hablarme naturalmente:\n'
              '• "Quiero ir del laboratorio al almacén"\n'
              '• "¿Cómo llego a la planta desde la entrada?"\n'
              '• "Ruta de admin hasta comedor"\n\n'
              'También puedes usar las sugerencias rápidas.',
        });
      });
    });
  }

  void _enviarMensaje({String? textoPredefinido}) {
    String texto = textoPredefinido ?? _controller.text.trim();
    if (texto.isEmpty) return;

    setState(() {
      _messages.add({'type': 'user', 'text': texto});
    });

    if (textoPredefinido == null) _controller.clear();

    Future.delayed(const Duration(milliseconds: 600), () {
      String respuesta = procesarMensaje(texto.toLowerCase());
      setState(() {
        _messages.add({'type': 'bot', 'text': respuesta});
      });
    });
  }

  //  NUEVO: Función mejorada con NLP para entender lenguaje natural
  String procesarMensaje(String msg) {
    String textoLimpio = msg.toLowerCase().trim();
    String? inicio, destino;

    // PASO 1: Buscar qué lugares mencionó el usuario usando sinónimos
    Map<String, int> lugaresEncontrados = {}; // Guarda el Nodo y posición en la frase

    sinonimos.forEach((nodo, listaSinonimos) {
      for (var sinonimo in listaSinonimos) {
        int index = textoLimpio.indexOf(sinonimo.toLowerCase());
        if (index != -1) {
          // Guardamos la primera aparición de este nodo
          if (!lugaresEncontrados.containsKey(nodo)) {
            lugaresEncontrados[nodo] = index;
          }
          break; // Encontramos un sinónimo, pasamos al siguiente nodo
        }
      }
    });

    // También buscar por letras de nodo (A, B, C, etc.) como fallback
    if (lugaresEncontrados.length < 2) {
      List<String> palabras = textoLimpio
          .replaceAll(RegExp(r'[^\w\s]'), '')
          .split(' ')
          .where((p) => p.isNotEmpty)
          .toList();

      for (var palabra in palabras) {
        for (var key in nombres.keys) {
          if (palabra == key.toLowerCase() &&
              !lugaresEncontrados.containsKey(key)) {
            lugaresEncontrados[key] = textoLimpio.indexOf(palabra);
          }
        }
      }
    }

    //  PASO 2: Si encontramos al menos 2 lugares, aplicar NLP para origen/destino
    if (lugaresEncontrados.length >= 2) {
      var nodos = lugaresEncontrados.keys.toList();
      String nodoX = nodos[0];
      String nodoY = nodos[1];

      // Verificar si hay conectores de destino antes del segundo nodo
      // Conectores: "al", "a", "hasta", "para", "hacia"
      bool destinoEsElSegundo = false;

      // Buscar patrones como "de X a Y", "desde X hasta Y", "X al Y"
      List<String> conectoresOrigen = ['de', 'desde', 'salgo de', 'parto de', 'vengo de'];
      List<String> conectoresDestino = ['al', 'a', 'hasta', 'para', 'hacia', 'hasta el', 'hasta la', 'para el', 'para la'];

      // Determinar cuál es origen y cuál es destino basado en conectores
      for (var conector in conectoresOrigen) {
        String patron = '$conector.*\\b${sinonimos[nodoX]?.first ?? nodoX.toLowerCase()}';
        if (RegExp(patron).hasMatch(textoLimpio)) {
          inicio = nodoX;
          destino = nodoY;
          break;
        }
        patron = '$conector.*\\b${sinonimos[nodoY]?.first ?? nodoY.toLowerCase()}';
        if (RegExp(patron).hasMatch(textoLimpio)) {
          inicio = nodoY;
          destino = nodoX;
          break;
        }
      }

      // Si no se determinó por conectores de origen, buscar por conectores de destino
      if (inicio == null || destino == null) {
        for (var conector in conectoresDestino) {
          String patron = '$conector.*\\b${sinonimos[nodoY]?.first ?? nodoY.toLowerCase()}';
          if (RegExp(patron).hasMatch(textoLimpio)) {
            inicio = nodoX;
            destino = nodoY;
            break;
          }
          patron = '$conector.*\\b${sinonimos[nodoX]?.first ?? nodoX.toLowerCase()}';
          if (RegExp(patron).hasMatch(textoLimpio)) {
            inicio = nodoY;
            destino = nodoX;
            break;
          }
        }
      }

      // Si aún no se determinó, usar el orden de aparición en la frase
      if (inicio == null || destino == null) {
        if (lugaresEncontrados[nodoX]! < lugaresEncontrados[nodoY]!) {
          // Si menciona "X a Y" o "X hasta Y", el primero suele ser origen
          inicio = nodoX;
          destino = nodoY;
        } else {
          inicio = nodoY;
          destino = nodoX;
        }
      }
    }

    // PASO 3: Si el NLP logró extraer origen y destino, ejecutar A*
    if (inicio != null && destino != null && inicio != destino) {
      final resultado = algoritmoAEstrella(inicio, destino);
      List<String> ruta = resultado['ruta'];
      
      if (ruta.isEmpty) {
        return "No se pudo encontrar una ruta entre ${nombres[inicio]} y ${nombres[destino]}.\n"
            "Verifica que exista conexión entre estos puntos.";
      }

      List<String> rutaNombres = ruta.map((n) => nombres[n] ?? n).toList();

      String rutaTexto = '';
      for (int i = 0; i < rutaNombres.length; i++) {
        String flecha = i < rutaNombres.length - 1 ? ' ⬇️' : ' 🎯';
        rutaTexto += "${i + 1}. ${rutaNombres[i]}$flecha\n";
      }

      return "🤖Ruta interpretada con éxito\n\n"
          "📍 Desde: ${nombres[inicio]}\n"
          "🏁 Hasta: ${nombres[destino]}\n\n"
          "🗺️ Recorrido:\n"
          "$rutaTexto\n"
          "Costo total: ${resultado['costo'].toStringAsFixed(0)} unidades\n\n"
          "✨La ruta más eficiente";
    }

    // Si solo encontró un lugar
    if (lugaresEncontrados.length == 1) {
      String lugar = nombres[lugaresEncontrados.keys.first]!;
      return "🤔 Entiendo que quieres ir a **$lugar**, pero necesito saber desde dónde.\n"
          "Por ejemplo: 'Quiero ir de la entrada a $lugar' o 'Desde admin hasta $lugar'";
    }

    // Si no entendió nada
    return "No logré entender la ruta. Aquí tienes algunos ejemplos de cómo pedírmelo:\n\n"
        "• 'Quiero ir del laboratorio hasta el almacén'\n"
        "• '¿Cómo llego a la planta desde la entrada?'\n"
        "• 'Ruta de admin a comedor'\n"
        "• 'De A a E'\n\n"
        "También puedes usar los botones de sugerencia rápida 👇";
  }

  double _calcularHeuristica(String nodoActual, String nodoDestino) {
    final p1 = coordenadas[nodoActual]!;
    final p2 = coordenadas[nodoDestino]!;
    return math.sqrt(
      (p1.$1 - p2.$1) * (p1.$1 - p2.$1) + (p1.$2 - p2.$2) * (p1.$2 - p2.$2),
    );
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

  void _limpiarChat() {
    setState(() {
      _messages.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🤖 Chatbot Ruta Menor Costo'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _limpiarChat,
            tooltip: "Limpiar chat",
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              reverse: true,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[_messages.length - 1 - index];
                bool esUsuario = msg['type'] == 'user';
                return Align(
                  alignment: esUsuario
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.all(16),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.8,
                    ),
                    decoration: BoxDecoration(
                      color: esUsuario ? Colors.indigo[600] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      msg['text']!,
                      style: TextStyle(
                        color: esUsuario ? Colors.white : Colors.black87,
                        fontSize: 16,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Botones de sugerencia siempre visibles
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.grey[100],
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: sugerencias
                  .map(
                    (sug) => ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo[100],
                        foregroundColor: Colors.indigo[900],
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      onPressed: () => _enviarMensaje(
                        textoPredefinido: "${sug['from']} a ${sug['to']}",
                      ),
                      child: Text(sug['text']!),
                    ),
                  )
                  .toList(),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "Ej: Quiero ir del laboratorio al almacén",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onSubmitted: (_) => _enviarMensaje(),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  onPressed: () => _enviarMensaje(),
                  child: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}