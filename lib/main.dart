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
      title: 'Chatbot Ruta Óptima ESPAM-MFL',
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

  // 🏛️ Nombres reales de la ESPAM-MFL (actualizado con todas las carreras y edificios)
  final Map<String, String> nombres = {
    'VET': 'Facultad Medicina Veterinarias',
    'INC': 'Planta Incubadora',
    'ADM': 'Carrera de Administración de Empresas',
    'AUD': 'Auditorio Jacinta López',
    'AGR': 'Carrera de Ingeniería Agrícola',
    'LAB': 'Laboratorio de Agropecuaria',
    'KAA': 'Kaacao S.A.',
    'CAN': 'Cancha Acústica de la ESPAM-MFL',
    'COL': 'Coliseo ESPAM MFL',
    'FMA': 'Facultad de Medio Ambiente',
    'TUR': 'Carrera de Turismo',
    'HOT': 'Hotel Higuerón',
    'GAS': 'Carrera de Gastronomía',
    'COM': 'Carrera de Computación',
    'POS': 'Posgrado',
    'BIB': 'Edificio Biblioteca',
    'ADM2': 'Edificio Administrativo', // Lo nombro ADM2 para no chocar con ADM
  };

  // 🧠 Diccionario de sinónimos ampliado con las nuevas ubicaciones
  final Map<String, List<String>> sinonimos = {
    'VET': [
      'veterinaria',
      'medicina veterinaria',
      'facultad de veterinaria',
      'bloque de veterinaria',
      'vet'
    ],
    'INC': [
      'incubadora',
      'planta incubadora',
      'incubacion',
      'incubación',
      'inc'
    ],
    'ADM': [
      'administracion',
      'administración',
      'empresas',
      'administracion de empresas',
      'bloque de administracion',
      'adm'
    ],
    'AUD': [
      'auditorio',
      'jacinta lopez',
      'jacinta lópez',
      'auditorio jacinta',
      'aud'
    ],
    'AGR': [
      'agricola',
      'agrícola',
      'ingenieria agricola',
      'ingeniería agrícola',
      'agr'
    ],
    'LAB': [
      'laboratorio',
      'agropecuaria',
      'laboratorio de agropecuaria',
      'lab'
    ],
    'KAA': [
      'kaacao',
      'cacao',
      'fabrica kaacao',
      'fábrica kaacao',
      'kaa'
    ],
    'CAN': [
      'cancha',
      'acustica',
      'acústica',
      'cancha acustica',
      'cancha acústica',
      'concha acustica',
      'can'
    ],
    'COL': [
      'coliseo',
      'coliseo espam',
      'coliseo mfl',
      'col'
    ],
    'FMA': [
      'medio ambiente',
      'facultad de medio ambiente',
      'ambiental',
      'fma'
    ],
    'TUR': [
      'turismo',
      'carrera de turismo',
      'tur'
    ],
    'HOT': [
      'hotel',
      'higueron',
      'higuerón',
      'hotel higueron',
      'hot'
    ],
    'GAS': [
      'gastronomia',
      'gastronomía',
      'carrera de gastronomia',
      'gas'
    ],
    'COM': [
      'computacion',
      'computación',
      'carrera de computacion',
      'sistemas',
      'com'
    ],
    'POS': [
      'posgrado',
      'postgrado',
      'pos'
    ],
    'BIB': [
      'biblioteca',
      'edificio biblioteca',
      'bib'
    ],
    'ADM2': [
      'edificio administrativo',
      'administrativo',
      'edificio admin'
    ],
  };

    // 🛣️ Grafo de conexiones peatonales generado con Haversine (umbral 300m + puente LAB↔HOT)
  final Map<String, List<Map<String, dynamic>>> grafo = {
    'VET': [
      {'to': 'INC', 'costo': 70.0},
      {'to': 'AGR', 'costo': 140.0},
    ],
    'INC': [
      {'to': 'VET', 'costo': 70.0},
      {'to': 'ADM', 'costo': 200.0},
    ],
    'ADM': [
      {'to': 'INC', 'costo': 200.0},
      {'to': 'AUD', 'costo': 40.0},
    ],
    'AUD': [
      {'to': 'ADM', 'costo': 40.0},
      {'to': 'AGR', 'costo': 90.0},
    ],
    'AGR': [
      {'to': 'AUD', 'costo': 90.0},
      {'to': 'VET', 'costo': 140.0},
      {'to': 'LAB', 'costo': 1100.0},
    ],
    'LAB': [
      {'to': 'AGR', 'costo': 1100.0},
      {'to': 'KAA', 'costo': 70.0},
      {'to': 'HOT', 'costo': 568.3}, // Puente hacia la zona oeste
    ],
    'KAA': [
      {'to': 'LAB', 'costo': 70.0},
      {'to': 'CAN', 'costo': 230.0},
      {'to': 'FMA', 'costo': 252.1},
      {'to': 'TUR', 'costo': 263.3},
    ],
    'CAN': [
      {'to': 'KAA', 'costo': 230.0},
      {'to': 'COL', 'costo': 216.4},
      {'to': 'FMA', 'costo': 59.3},
      {'to': 'TUR', 'costo': 47.8},
    ],
    'COL': [
      {'to': 'CAN', 'costo': 216.4},
      {'to': 'FMA', 'costo': 243.9},
      {'to': 'TUR', 'costo': 230.5},
    ],
    'FMA': [
      {'to': 'CAN', 'costo': 59.3},
      {'to': 'COL', 'costo': 243.9},
      {'to': 'TUR', 'costo': 16.4},
      {'to': 'KAA', 'costo': 252.1},
    ],
    'TUR': [
      {'to': 'CAN', 'costo': 47.8},
      {'to': 'COL', 'costo': 230.5},
      {'to': 'FMA', 'costo': 16.4},
      {'to': 'KAA', 'costo': 263.3},
    ],
    'HOT': [
      {'to': 'LAB', 'costo': 568.3},
      {'to': 'COM', 'costo': 98.3},
      {'to': 'BIB', 'costo': 148.2},
      {'to': 'GAS', 'costo': 302.8},
    ],
    'GAS': [
      {'to': 'HOT', 'costo': 302.8},
      {'to': 'COM', 'costo': 216.4},
      {'to': 'POS', 'costo': 174.5},
    ],
    'COM': [
      {'to': 'HOT', 'costo': 98.3},
      {'to': 'GAS', 'costo': 216.4},
      {'to': 'POS', 'costo': 79.1},
      {'to': 'ADM2', 'costo': 190.8},
      {'to': 'BIB', 'costo': 71.4},
    ],
    'POS': [
      {'to': 'GAS', 'costo': 174.5},
      {'to': 'COM', 'costo': 79.1},
      {'to': 'BIB', 'costo': 54.3},
    ],
    'BIB': [
      {'to': 'HOT', 'costo': 148.2},
      {'to': 'COM', 'costo': 71.4},
      {'to': 'POS', 'costo': 54.3},
      {'to': 'ADM2', 'costo': 135.4},
    ],
    'ADM2': [
      {'to': 'COM', 'costo': 190.8},
      {'to': 'BIB', 'costo': 135.4},
    ],
  };

  // 🌐 Coordenadas GPS reales (Latitud, Longitud) actualizadas con todas las ubicaciones
  final Map<String, (double, double)> coordenadas = {
    'VET': (-0.8191042309287083, -80.18070584205533),
    'INC': (-0.8184793400393129, -80.18068170216947),
    'ADM': (-0.8190613199660038, -80.17890071539665),
    'AUD': (-0.8193295134504462, -80.17861908345724),
    'AGR': (-0.8193054588772872, -80.17946284266132),
    'LAB': (-0.8275175347704268, -80.18704880030674),
    'KAA': (-0.826897170957849, -80.18705667929609),
    'CAN': (-0.8289493495008273, -80.18582805994684),
    'COL': (-0.8306550555082427, -80.18489465120184),
    'FMA': (-0.8285344886942664, -80.18549412488781),
    'TUR': (-0.828682413814722, -80.18548515626249),
    'HOT': (-0.8274703625918673, -80.18194846667554),
    'GAS': (-0.8252476162378222, -80.1835522055805),
    'COM': (-0.8266171478177358, -80.18216960805292),
    'POS': (-0.8259043539873512, -80.18212996425095),
    'BIB': (-0.826156455432419, -80.18171422184288),
    'ADM2': (-0.8262560220902032, -80.18050823362339),
  };

  // Sugerencias rápidas (se pueden ampliar cuando el grafo esté completo)
    final List<Map<String, String>> sugerencias = [
    {'text': 'Veterinaria → Auditorio', 'from': 'VET', 'to': 'AUD'},
    {'text': 'Admin → Agrícola', 'from': 'ADM', 'to': 'AGR'},
    {'text': 'Incubadora → Laboratorio', 'from': 'INC', 'to': 'LAB'},
    {'text': 'Kaacao → Cancha', 'from': 'KAA', 'to': 'CAN'},
    {'text': 'Computación → Coliseo', 'from': 'COM', 'to': 'COL'},
    {'text': 'Biblioteca → Turismo', 'from': 'BIB', 'to': 'TUR'},
  ];

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _messages.add({
          'type': 'bot',
          'text': '👋 ¡Hola! Soy el asistente de rutas de la ESPAM-MFL.\n\n'
              'Puedes hablarme naturalmente:\n'
              '• "Quiero ir de veterinaria al auditorio"\n'
              '• "¿Cómo llego a la cancha desde administración?"\n'
              '• "Ruta de la incubadora hasta agrícola"\n\n'
              'También puedes usar las sugerencias rápidas de abajo.',
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

  String procesarMensaje(String msg) {
  String textoLimpio = msg.toLowerCase().trim();
  String? inicio, destino;

  Map<String, int> lugaresEncontrados = {};

  sinonimos.forEach((nodo, listaSinonimos) {
    for (var sinonimo in listaSinonimos) {
      int index = textoLimpio.indexOf(sinonimo.toLowerCase());
      if (index != -1) {
        if (!lugaresEncontrados.containsKey(nodo)) {
          lugaresEncontrados[nodo] = index;
        }
        break;
      }
    }
  });

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

  if (lugaresEncontrados.length >= 2) {
    var nodos = lugaresEncontrados.keys.toList();
    String nodoX = nodos[0];
    String nodoY = nodos[1];

    // ----- NUEVA LÓGICA de detección (corregida) -----
    int posX = lugaresEncontrados[nodoX]!;
    int posY = lugaresEncontrados[nodoY]!;

    final conectoresOrigen = ['desde', 'salgo de', 'parto de', 'vengo de', 'de'];
    final conectoresDestino = [
      'hasta el', 'hasta la', 'para el', 'para la', 'hasta', 'para', 'hacia', 'al', 'a'
    ];

    // Función auxiliar: busca si justo antes de un lugar hay un conector
    String? conectorAntesDe(String lugar, List<String> conectores) {
      int idx = lugaresEncontrados[lugar]!;
      int startSearch = idx - 30;
      if (startSearch < 0) startSearch = 0;
      String fragmento = textoLimpio.substring(startSearch, idx);
      // Ordenamos por longitud descendente para preferir conectores más largos
      for (var con in conectores) {
        if (fragmento.endsWith(con + ' ') || fragmento.endsWith(con)) {
          return con;
        }
      }
      return null;
    }

    String? conectorXOrigen = conectorAntesDe(nodoX, conectoresOrigen);
    String? conectorYOrigen = conectorAntesDe(nodoY, conectoresOrigen);
    String? conectorXDestino = conectorAntesDe(nodoX, conectoresDestino);
    String? conectorYDestino = conectorAntesDe(nodoY, conectoresDestino);

    // Decidir origen/destino según los conectores encontrados
    if (conectorXOrigen != null) {
      inicio = nodoX;
      destino = nodoY;
    } else if (conectorYOrigen != null) {
      inicio = nodoY;
      destino = nodoX;
    } else if (conectorXDestino != null) {
      inicio = nodoY;
      destino = nodoX;
    } else if (conectorYDestino != null) {
      inicio = nodoX;
      destino = nodoY;
    } else {
      // Fallback: el lugar que aparece primero en el texto es el origen
      if (posX < posY) {
        inicio = nodoX;
        destino = nodoY;
      } else {
        inicio = nodoY;
        destino = nodoX;
      }
    }
    // ----- FIN NUEVA LÓGICA -----
  }

  if (inicio != null && destino != null && inicio != destino) {
    final resultado = algoritmoAEstrella(inicio, destino);
    List<String> ruta = resultado['ruta'];

    if (ruta.isEmpty) {
      return "No se pudo encontrar una ruta entre ${nombres[inicio]} y ${nombres[destino]}.\n"
          "Verifica que exista conexión en el grafo para estos puntos. "
          "Algunas ubicaciones nuevas aún no tienen caminos peatonales definidos.";
    }

    List<String> rutaNombres = ruta.map((n) => nombres[n] ?? n).toList();

    String rutaTexto = '';
    for (int i = 0; i < rutaNombres.length; i++) {
      String flecha = i < rutaNombres.length - 1 ? ' ⬇️' : ' 🎯';
      rutaTexto += "${i + 1}. ${rutaNombres[i]}$flecha\n";
    }

    return "🤖 **Ruta interpretada con éxito**\n\n"
        "📍 **Desde:** ${nombres[inicio]}\n"
        "🏁 **Hasta:** ${nombres[destino]}\n\n"
        "🗺️ **Recorrido óptimo:**\n"
        "$rutaTexto\n"
        "📏 **Distancia aproximada:** ${resultado['costo'].toStringAsFixed(1)} metros\n\n"
        "✨ *Cálculo basado en coordenadas satelitales reales.*";
  }

  if (lugaresEncontrados.length == 1) {
    String lugar = nombres[lugaresEncontrados.keys.first]!;
    return "🤔 Entiendo que te refieres a **$lugar**, pero necesito saber tanto el punto de origen como el de destino.\n\n"
        "Por ejemplo: 'Quiero ir de Veterinaria a $lugar'";
  }

  return "No logré entender la ruta. Inténtalo de esta forma:\n\n"
      "• 'Quiero ir de administración a agrícola'\n"
      "• '¿Cómo voy desde Kaacao hasta la cancha?'\n"
      "• 'Ruta de VET a AUD'\n\n"
      "También puedes presionar los botones de sugerencia rápida 👇";
}

  // Fórmula de Haversine para calcular distancia real en metros
  double _calcularHeuristica(String nodoActual, String nodoDestino) {
    final p1 = coordenadas[nodoActual]!;
    final p2 = coordenadas[nodoDestino]!;

    double lat1 = p1.$1;
    double lon1 = p1.$2;
    double lat2 = p2.$1;
    double lon2 = p2.$2;

    const double R = 6371000;

    double dLat = (lat2 - lat1) * math.pi / 180.0;
    double dLon = (lon2 - lon1) * math.pi / 180.0;

    double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180.0) *
            math.cos(lat2 * math.pi / 180.0) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return R * c;
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

  void _limpiarChat() {
    setState(() {
      _messages.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🤖 Chatbot ESPAM-MFL'),
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
                      hintText: "Ej: Quiero ir de veterinaria al auditorio",
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