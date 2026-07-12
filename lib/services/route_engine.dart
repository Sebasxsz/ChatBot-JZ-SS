// lib/services/route_engine.dart
//
// Toda la lógica de negocio que antes vivía dentro de `_ChatScreenState`:
// interpretar el mensaje del usuario (encontrar lugares y decidir cuál es
// el origen y cuál el destino) y calcular la ruta más corta con A*.
//
// No depende de Flutter ni de la UI: recibe un String y devuelve un
// [RouteResult]. Esto la hace fácil de probar de forma aislada.

import 'dart:math' as math;

import '../data/campus_data.dart';
import '../models/chat_models.dart';

abstract final class RouteEngine {
  // --- Patrones de reconocimiento, precompilados una sola vez -------------
  //
  // Antes, cada mensaje enviado reconstruía todas las expresiones
  // regulares desde cero (una por cada sinónimo de cada lugar). Al ser
  // `static final`, Dart las compila una única vez la primera vez que se
  // usan y las reutiliza en cada mensaje siguiente.

  static final Map<String, List<RegExp>> _patronesSinonimos = {
    for (final entrada in sinonimos.entries)
      entrada.key: [
        for (final palabra in entrada.value)
          RegExp(
            '(?<![a-zA-Z0-9áéíóúüñÁÉÍÓÚÜÑ])${RegExp.escape(palabra)}'
            '(?![a-zA-Z0-9áéíóúüñÁÉÍÓÚÜÑ])',
            caseSensitive: false,
          ),
      ],
  };

  static final RegExp _patronSiglas = RegExp(
    r'\b(' + nombres.keys.join('|') + r')\b',
    caseSensitive: false,
  );

  static const _conectoresOrigen = ['desde', 'salgo de', 'parto de', 'vengo de', 'de'];

  static const _conectoresDestino = [
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

  // --- Interpretación del mensaje ------------------------------------------

  /// Analiza el mensaje del usuario, detecta hasta dos lugares del campus y
  /// determina cuál es el origen y cuál el destino, para luego calcular la
  /// ruta entre ambos.
  static RouteResult interpretarMensaje(String mensajeCrudo) {
    final texto = mensajeCrudo.toLowerCase().trim();
    final lugaresEncontrados = <String, int>{};

    _patronesSinonimos.forEach((nodo, patrones) {
      for (final patron in patrones) {
        final match = patron.firstMatch(texto);
        if (match != null) {
          lugaresEncontrados.putIfAbsent(nodo, () => match.start);
          break; // Solo tomamos el primer sinónimo que coincida.
        }
      }
    });

    // Si no se detectaron dos lugares por sinónimos, se intenta por sigla
    // exacta (VET, COM, etc.) como respaldo.
    if (lugaresEncontrados.length < 2) {
      for (final match in _patronSiglas.allMatches(texto)) {
        final clave = match.group(0)!.toUpperCase();
        lugaresEncontrados.putIfAbsent(clave, () => match.start);
      }
    }

    final (inicio, destino) = _determinarOrigenYDestino(texto, lugaresEncontrados);

    if (inicio != null && destino != null && inicio != destino) {
      final resultado = _buscarRuta(inicio, destino);

      if (resultado.ruta.isEmpty) {
        return RouteNotFound(
          origenNombre: nombres[inicio]!,
          destinoNombre: nombres[destino]!,
        );
      }

      return RouteFound(
        origenNombre: nombres[inicio]!,
        destinoNombre: nombres[destino]!,
        pasos: resultado.ruta.map((n) => nombres[n] ?? n).toList(),
        distanciaMetros: resultado.costo,
      );
    }

    if (lugaresEncontrados.length == 1) {
      return NeedsMoreInfo(nombres[lugaresEncontrados.keys.first]!);
    }

    return const NotUnderstood();
  }

  /// Dado el conjunto de lugares detectados (con la posición en el texto
  /// donde aparecieron), decide cuál es el origen y cuál el destino usando
  /// los conectores del lenguaje natural ("desde", "hasta", "a", etc.). Si
  /// ningún conector es concluyente, se asume que el primero mencionado es
  /// el origen.
  static (String?, String?) _determinarOrigenYDestino(
    String texto,
    Map<String, int> lugaresEncontrados,
  ) {
    if (lugaresEncontrados.length < 2) return (null, null);

    final nodos = lugaresEncontrados.keys.toList();
    final nodoX = nodos[0];
    final nodoY = nodos[1];
    final posX = lugaresEncontrados[nodoX]!;
    final posY = lugaresEncontrados[nodoY]!;

    if (_conectorAntesDe(posX, texto, _conectoresOrigen)) {
      return (nodoX, nodoY);
    }
    if (_conectorAntesDe(posY, texto, _conectoresOrigen)) {
      return (nodoY, nodoX);
    }
    if (_conectorAntesDe(posX, texto, _conectoresDestino)) {
      return (nodoY, nodoX);
    }
    if (_conectorAntesDe(posY, texto, _conectoresDestino)) {
      return (nodoX, nodoY);
    }
    return posX < posY ? (nodoX, nodoY) : (nodoY, nodoX);
  }

  /// Revisa si, justo antes de la posición dada, aparece alguno de los
  /// conectores indicados (ej. "desde", "hasta").
  static bool _conectorAntesDe(int posicion, String texto, List<String> conectores) {
    final inicioBusqueda = posicion - 30 < 0 ? 0 : posicion - 30;
    final fragmento = texto.substring(inicioBusqueda, posicion);
    return conectores.any(
      (con) => fragmento.endsWith('$con ') || fragmento.endsWith(con),
    );
  }

  // --- Búsqueda de ruta (A*) -----------------------------------------------

  /// Calcula la ruta más corta entre [inicio] y [destino] usando A*, con la
  /// distancia en línea recta (haversine) como heurística.
  ///
  /// Nota sobre el "borrado perezoso": a diferencia de una implementación
  /// naive que evita agregar un nodo dos veces a la cola abierta, aquí se
  /// permite agregarlo varias veces con distintas prioridades, y al
  /// extraerlo se descarta si ya existe una versión mejor (`fScore[actual]`
  /// más bajo). Esto evita que una entrada con prioridad desactualizada
  /// haga que el algoritmo explore en un orden subóptimo y termine
  /// devolviendo un camino que no es el más corto.
  static ({List<String> ruta, double costo}) _buscarRuta(String inicio, String destino) {
    final gScore = {for (final nodo in grafo.keys) nodo: double.infinity};
    final fScore = {for (final nodo in grafo.keys) nodo: double.infinity};
    final anterior = <String, String>{};

    gScore[inicio] = 0;
    fScore[inicio] = _heuristica(inicio, destino);

    final abiertos = <(double, String)>[(fScore[inicio]!, inicio)];

    while (abiertos.isNotEmpty) {
      abiertos.sort((a, b) => a.$1.compareTo(b.$1));
      final (fActual, actual) = abiertos.removeAt(0);

      // Entrada obsoleta: ya se encontró un camino mejor para este nodo.
      if (fActual > fScore[actual]!) continue;
      if (actual == destino) break;

      for (final vecino in grafo[actual] ?? const <Edge>[]) {
        final gTentativo = gScore[actual]! + vecino.costo;
        if (gTentativo < gScore[vecino.to]!) {
          anterior[vecino.to] = actual;
          gScore[vecino.to] = gTentativo;
          fScore[vecino.to] = gTentativo + _heuristica(vecino.to, destino);
          abiertos.add((fScore[vecino.to]!, vecino.to));
        }
      }
    }

    if (!anterior.containsKey(destino)) {
      return (ruta: const [], costo: gScore[destino]!);
    }

    final ruta = <String>[destino];
    var nodoActual = destino;
    while (anterior.containsKey(nodoActual)) {
      nodoActual = anterior[nodoActual]!;
      ruta.add(nodoActual);
    }
    return (ruta: ruta.reversed.toList(), costo: gScore[destino]!);
  }

  /// Distancia en línea recta (metros) entre dos nodos, usando la fórmula
  /// de haversine sobre sus coordenadas geográficas.
  static double _heuristica(String nodoActual, String nodoDestino) {
    const radioTierraMetros = 6371000.0;
    final origen = coordenadas[nodoActual]!;
    final fin = coordenadas[nodoDestino]!;

    final dLat = _gradosARadianes(fin.lat - origen.lat);
    final dLon = _gradosARadianes(fin.lon - origen.lon);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_gradosARadianes(origen.lat)) *
            math.cos(_gradosARadianes(fin.lat)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    return radioTierraMetros * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  static double _gradosARadianes(double grados) => grados * math.pi / 180.0;
}