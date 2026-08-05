// lib/screens/campus_map_screen.dart
//
// Mapa base de OpenStreetMap centrado en el campus, con un ícono
// isométrico en cada uno de los 17 edificios (día 3).
//
// Si se le pasa una [ruta] ya calculada por RouteEngine, además dibuja la
// línea del recorrido sobre el mapa (día 4) y distingue visualmente
// origen, destino y puntos intermedios (día 5).

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../data/campus_data.dart';
import '../models/chat_models.dart';
import '../utils/color_utils.dart';
import '../widgets/isometric_building_icon.dart';

/// A qué tipo de ícono corresponde cada sigla del campus. Las siglas no
/// listadas usan el tipo genérico por defecto.
BuildingType _tipoDeEdificio(String sigla) => switch (sigla) {
  'AUD' => BuildingType.auditorio,
  'COL' => BuildingType.coliseo,
  'LAB' => BuildingType.laboratorio,
  _ => BuildingType.generico,
};

/// Qué papel juega un edificio respecto a la ruta que se está mostrando
/// (si hay alguna). Determina tanto el color del ícono como el mensaje
/// que se muestra al tocarlo.
enum _RolMarcador { origen, destino, intermedio, fueraDeRuta, sinRutaActiva }

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

  // Si hay ruta, se encuadra sobre ella; si no, sobre todo el campus. Se
  // reutiliza tanto al abrir la pantalla como cuando el usuario toca el
  // botón de recentrar.
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

  /// Determina el rol de [sigla] respecto a la ruta activa (si hay una).
  _RolMarcador _rolDe(String sigla) {
    final ruta = widget.ruta;
    if (ruta == null) return _RolMarcador.sinRutaActiva;
    if (sigla == ruta.nodos.first) return _RolMarcador.origen;
    if (sigla == ruta.nodos.last) return _RolMarcador.destino;
    if (ruta.nodos.contains(sigla)) return _RolMarcador.intermedio;
    return _RolMarcador.fueraDeRuta;
  }

  void _encuadrarVista() {
    _mapController.fitCamera(
      CameraFit.bounds(bounds: _limitesEncuadre, padding: const EdgeInsets.all(48)),
    );
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
      floatingActionButton: FloatingActionButton.small(
        onPressed: _encuadrarVista,
        tooltip: ruta != null ? 'Centrar en la ruta' : 'Centrar en el campus',
        child: const Icon(Icons.center_focus_strong),
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _limitesEncuadre.center,
          initialZoom: 17,
          onMapReady: _encuadrarVista,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            // ⚠️ IMPORTANTE: cambia esto por el package name real de la
            // app (el mismo applicationId de Android o bundle id de iOS).
            // OpenStreetMap exige un User-Agent identificable; si se deja
            // un valor genérico, pueden bloquear las peticiones.
            userAgentPackageName: 'ec.edu.espam.chatbot_rutas',
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
                  width: 58,
                  height: 46,
                  // Ancla el punto GPS en la base del ícono (como un pin),
                  // no en su centro. Si al probarlo lo ves desalineado
                  // respecto al edificio real, ajusta este valor.
                  alignment: Alignment.topCenter,
                  child: _MarcadorEdificio(
                    nombre: nombres[entrada.key] ?? entrada.key,
                    tipo: _tipoDeEdificio(entrada.key),
                    rol: _rolDe(entrada.key),
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

/// Marcador de edificio: el ícono isométrico + información al tocarlo.
///
/// El color y el mensaje cambian según [rol]: origen y destino se
/// distinguen del resto de la ruta, y los edificios fuera del recorrido
/// se atenúan para que el camino resalte visualmente.
class _MarcadorEdificio extends StatelessWidget {
  final String nombre;
  final BuildingType tipo;
  final _RolMarcador rol;

  const _MarcadorEdificio({
    required this.nombre,
    required this.tipo,
    required this.rol,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primario = theme.colorScheme.primary;

    final (color, etiquetaRol) = switch (rol) {
      _RolMarcador.origen => (Colors.blue.shade600, 'Origen'),
      _RolMarcador.destino => (theme.colorScheme.secondary, 'Destino'),
      _RolMarcador.intermedio => (primario, 'Parte del recorrido'),
      _RolMarcador.fueraDeRuta => (primario.conOpacidad(0.35), null),
      _RolMarcador.sinRutaActiva => (primario, null),
    };

    return GestureDetector(
      onTap: () {
        final mensaje = etiquetaRol == null ? nombre : '$nombre — $etiquetaRol';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mensaje), duration: const Duration(seconds: 2)),
        );
      },
      child: IsometricBuildingIcon(size: 30, tipo: tipo, color: color),
    );
  }
}