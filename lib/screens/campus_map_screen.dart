// lib/screens/campus_map_screen.dart
//
// Mapa base de OpenStreetMap centrado en el campus, con un ícono
// isométrico en cada uno de los 17 edificios (día 3).
//
// Día 4: si se le pasa una [ruta] ya calculada por RouteEngine, además
// dibuja la línea del recorrido sobre el mapa (usando `waypointsPara` de
// `campus_data.dart` para seguir el camino real, no una línea recta) y
// encuadra la cámara sobre esa ruta en vez de sobre todo el campus.

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../data/campus_data.dart';
import '../models/chat_models.dart';
import '../utils/color_utils.dart';
import '../widgets/isometric_building_icon.dart';

class CampusMapScreen extends StatefulWidget {
  /// Ruta ya calculada para mostrar dibujada sobre el mapa. Si es `null`,
  /// se muestran los 17 edificios sin ninguna línea (vista general).
  final RouteFound? ruta;

  const CampusMapScreen({super.key, this.ruta});

  @override
  State<CampusMapScreen> createState() => _CampusMapScreenState();
}

class _CampusMapScreenState extends State<CampusMapScreen> {
  final _mapController = MapController();

  // Convertimos nuestras `Coord` (lat, lon) a `LatLng`, que es el tipo que
  // espera flutter_map. Se calcula una sola vez.
  late final Map<String, ll.LatLng> _puntos = {
    for (final entrada in coordenadas.entries)
      entrada.key: ll.LatLng(entrada.value.lat, entrada.value.lon),
  };

  // Rectángulo que envuelve los 17 edificios (vista general, sin ruta).
  late final LatLngBounds _limitesCampus = LatLngBounds.fromPoints(
    _puntos.values.toList(),
  );

  // Puntos de la línea a dibujar: edificio -> waypoints -> edificio -> ...
  // en el orden exacto del recorrido. Vacío si no hay ruta que mostrar.
  late final List<ll.LatLng> _puntosRuta = widget.ruta == null
      ? const []
      : _construirPuntosDeRuta(widget.ruta!.nodos);

  // Siglas de los edificios que forman parte de la ruta, para resaltarlos
  // con un color distinto al resto.
  late final Set<String> _nodosDestacados = widget.ruta?.nodos.toSet() ?? {};

  // Si hay ruta, se encuadra sobre ella; si no, sobre todo el campus.
  late final LatLngBounds _limitesEncuadre = _puntosRuta.isNotEmpty
      ? LatLngBounds.fromPoints(_puntosRuta)
      : _limitesCampus;

  /// Recorre la lista de nodos de la ruta y arma la lista completa de
  /// puntos a dibujar, insertando los waypoints de cada tramo en el orden
  /// correcto (ver `waypointsPara` en campus_data.dart).
  List<ll.LatLng> _construirPuntosDeRuta(List<String> nodos) {
    final puntos = <ll.LatLng>[];

    for (var i = 0; i < nodos.length; i++) {
      final actual = nodos[i];
      final coordActual = coordenadas[actual];
      if (coordActual != null) {
        puntos.add(ll.LatLng(coordActual.lat, coordActual.lon));
      }

      if (i < nodos.length - 1) {
        final siguiente = nodos[i + 1];
        for (final wp in waypointsPara(actual, siguiente)) {
          puntos.add(ll.LatLng(wp.lat, wp.lon));
        }
      }
    }
    return puntos;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ruta = widget.ruta;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Mapa del Campus'),
            if (ruta != null)
              Text(
                '${ruta.origenNombre} ➔ ${ruta.destinoNombre}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _limitesEncuadre.center,
          initialZoom: 17,
          onMapReady: () {
            _mapController.fitCamera(
              CameraFit.bounds(
                bounds: _limitesEncuadre,
                padding: const EdgeInsets.all(48),
              ),
            );
          },
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            // ⚠️ IMPORTANTE: cambia esto por el package name real de la
            // app (el mismo applicationId de Android o bundle id de iOS).
            // OpenStreetMap exige un User-Agent identificable; si se deja
            // un valor genérico, pueden bloquear las peticiones.
            userAgentPackageName: 'com.example.chatbot',
          ),
          if (_puntosRuta.isNotEmpty)
            PolylineLayer(
              polylines: [
                Polyline(
                  points: _puntosRuta,
                  color: theme.colorScheme.secondary,
                  strokeWidth: 5,
                ),
              ],
            ),
          MarkerLayer(
            markers: [
              for (final entrada in _puntos.entries)
                Marker(
                  point: entrada.value,
                  width: 40,
                  height: 46,
                  // Ancla el punto GPS en la base del ícono (como un pin),
                  // no en su centro. Si al probarlo lo ves desalineado
                  // respecto al edificio real, ajusta este valor.
                  alignment: Alignment.topCenter,
                  child: _MarcadorEdificio(
                    nombre: nombres[entrada.key] ?? entrada.key,
                    destacado: _nodosDestacados.isEmpty ||
                        _nodosDestacados.contains(entrada.key),
                  ),
                ),
            ],
          ),
          // Atribución obligatoria según la licencia de uso de OpenStreetMap.
          const RichAttributionWidget(
            attributions: [
              TextSourceAttribution('OpenStreetMap contributors'),
            ],
          ),
        ],
      ),
    );
  }
}

/// Marcador de edificio: el ícono isométrico + su nombre al tocarlo.
///
/// Cuando se está mostrando una ruta, los edificios que no forman parte
/// de ella se atenúan, para que el recorrido resalte visualmente.
class _MarcadorEdificio extends StatelessWidget {
  final String nombre;
  final bool destacado;

  const _MarcadorEdificio({required this.nombre, required this.destacado});

  @override
  Widget build(BuildContext context) {
    final colorBase = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(nombre), duration: const Duration(seconds: 2)),
        );
      },
      child: IsometricBuildingIcon(
        size: 34,
        color: destacado ? colorBase : colorBase.conOpacidad(0.35),
      ),
    );
  }
}