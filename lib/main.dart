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
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
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

  final Map<String, List<Map<String, dynamic>>> grafo = {
    'A': [{'to': 'B', 'costo': 40}, {'to': 'C', 'costo': 60}, {'to': 'G', 'costo': 30}],
    'B': [{'to': 'A', 'costo': 40}, {'to': 'C', 'costo': 25}, {'to': 'D', 'costo': 50}],
    'C': [{'to': 'A', 'costo': 60}, {'to': 'B', 'costo': 25}, {'to': 'E', 'costo': 35}],
    'D': [{'to': 'B', 'costo': 50}, {'to': 'E', 'costo': 20}, {'to': 'F', 'costo': 45}],
    'E': [{'to': 'C', 'costo': 35}, {'to': 'D', 'costo': 20}, {'to': 'F', 'costo': 30}],
    'F': [{'to': 'D', 'costo': 45}, {'to': 'E', 'costo': 30}, {'to': 'G', 'costo': 55}],
    'G': [{'to': 'A', 'costo': 30}, {'to': 'F', 'costo': 55}],
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
          'text': '👋 ¡Hola! Soy tu asistente de rutas.\n\n'
              'Toca alguna sugerencia rápida o escribe una ruta.'
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
    String? inicio, destino;

    for (var key in nombres.keys) {
      if (msg.contains(key.toLowerCase())) {
        if (inicio == null) inicio = key;
        else destino = key;
      }
    }

    if (inicio != null && destino != null) {
      final resultado = dijkstra(inicio, destino);
      List<String> ruta = resultado['ruta'];
      List<String> rutaNombres = ruta.map((n) => nombres[n] ?? n).toList();

      String rutaTexto = '';
      for (int i = 0; i < rutaNombres.length; i++) {
        rutaTexto += "${i + 1}. ${rutaNombres[i]}\n";
      }

      return "✅ **Ruta más corta encontrada**\n\n"
          "$rutaTexto\n"
          "💰 **Costo total: ${resultado['costo'].toStringAsFixed(0)}** unidades";
    }

    return "No entendí la ruta. Intenta con las sugerencias de abajo o escribe algo como:\n"
        "• ruta de A a E\n"
        "• desde B hasta F";
  }

  Map<String, dynamic> dijkstra(String start, String end) {
    final dist = <String, double>{for (var k in grafo.keys) k: double.infinity};
    final prev = <String, String?>{};
    final pq = <(double, String)>[];

    dist[start] = 0;
    pq.add((0, start));

    while (pq.isNotEmpty) {
      pq.sort((a, b) => a.$1.compareTo(b.$1));
      final (cost, u) = pq.removeAt(0);
      if (cost > dist[u]!) continue;

      for (var v in grafo[u]!) {
        double newCost = cost + v['costo'];
        if (newCost < dist[v['to']]!) {
          dist[v['to']] = newCost;
          prev[v['to']] = u;
          pq.add((newCost, v['to']));
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

    return {'ruta': path.length > 1 ? path : [], 'costo': dist[end]!};
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
          IconButton(icon: const Icon(Icons.delete), onPressed: _limpiarChat, tooltip: "Limpiar chat"),
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
                  alignment: esUsuario ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.all(16),
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
              children: sugerencias.map((sug) => ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo[100],
                  foregroundColor: Colors.indigo[900],
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onPressed: () => _enviarMensaje(textoPredefinido: "${sug['from']} a ${sug['to']}"),
                child: Text(sug['text']!),
              )).toList(),
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
                      hintText: "Escribe una ruta (ej: A a E)",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onSubmitted: (_) => _enviarMensaje(),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  onPressed: _enviarMensaje,
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