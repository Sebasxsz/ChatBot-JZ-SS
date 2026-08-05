// ignore_for_file: avoid_print
import 'package:flutter_test/flutter_test.dart';
import 'package:chatbot/data/campus_data.dart';
import 'package:chatbot/models/chat_models.dart';
import 'package:chatbot/services/route_engine.dart';

void main() {
  test('Benchmark del Algoritmo A* - Tiempos de Ejecución', () {
    // 1. Definir los escenarios de prueba exactos que mencionas en tu informe.
    // Cada mensaje usa conectores claros ("desde" = origen, "hasta" = destino)
    // para que el motor identifique y ordene los dos lugares correctamente.
    final pruebas = [
      {
        'escenario': 'Ruta Corta (2-3 nodos)',
        'mensaje': 'Voy desde el VET hasta el INC',
      },
      {
        'escenario': 'Ruta Media (4-6 nodos)',
        'mensaje': 'Voy desde el LAB hasta el HOT',
      },
      {
        'escenario': 'Ruta Larga (7-10 nodos)',
        'mensaje': 'Voy desde el VET hasta el AUD',
      },
      {
        'escenario': 'Ruta Completa (10+ nodos)',
        'mensaje': 'Voy desde el BIB hasta el COL',
      },
    ];

    final stopwatch = Stopwatch();

    print('==================================================');
    print('   INICIANDO BENCHMARK A* - ESPAM MFL NAVEGACIÓN   ');
    print('==================================================\n');

    for (var prueba in pruebas) {
      // Reiniciar el cronómetro para cada prueba.
      stopwatch.reset();
      stopwatch.start();

      // 2. Llamar al método público que ejecuta la búsqueda A*. `_buscarRuta`
      //    es privado, así que usamos `interpretarMensaje` como envoltorio.
      final RouteResult resultado =
          RouteEngine.interpretarMensaje(prueba['mensaje']!);

      stopwatch.stop();

      // 3. Mostrar resultados en milisegundos (ms).
      final double tiempoMs = stopwatch.elapsedMicroseconds / 1000.0;

      print('Escenario: ${prueba['escenario']}');
      print('Tiempo:    ${tiempoMs.toStringAsFixed(2)} ms');

      switch (resultado) {
        case RouteFound(
            origenNombre: final origen,
            destinoNombre: final destino,
            pasos: final pasos,
            distanciaMetros: final distancia,
          ):
          print('Trayecto:  $origen -> $destino');
          print('Nodos:     ${pasos.length}');
          print('Distancia: ${distancia.toStringAsFixed(2)} m');
          print('Ruta:      ${pasos.join(' -> ')}');
        case RouteNotFound(origenNombre: final o, destinoNombre: final d):
          print('Trayecto:  $o -> $d');
          print('Resultado: NO ENCONTRADO');
        case NeedsMoreInfo(lugarNombre: final lugar):
          print('Resultado: FALTA INFORMACIÓN ($lugar)');
        case NotUnderstood():
          print('Resultado: NO ENTENDIDO');
      }
      print('--------------------------------------------------');
    }
  });
}