// lib/data/campus_data.dart
//
// Datos estáticos del campus: nombres legibles, sinónimos para el
// reconocimiento de lenguaje natural, el grafo de conexiones peatonales y
// las coordenadas usadas por la heurística del algoritmo A*.
//
// Todo aquí es `const`. Al ser literales que nunca cambian en tiempo de
// ejecución, Dart los convierte en constantes de compilación únicas y
// compartidas (en vez de crear un Map/List nuevo cada vez que se importa
// o usa este archivo), lo que además ayuda al tree-shaking.

/// Una arista del grafo: nodo destino y costo (en metros) de llegar a él.
/// Reemplaza el antiguo `Map<String, dynamic>` con claves 'to'/'costo' por
/// algo tipado y sin `dynamic`.
typedef Edge = ({String to, double costo});

/// Coordenadas geográficas (grados decimales) de un nodo del campus.
typedef Coord = ({double lat, double lon});

const Map<String, String> nombres = {
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
  'ADM2': 'Edificio Administrativo',
};

const Map<String, List<String>> sinonimos = {
  'VET': [
    'veterinaria',
    'medicina veterinaria',
    'facultad de veterinaria',
    'bloque de veterinaria',
    'vet',
  ],
  'INC': ['incubadora', 'planta incubadora', 'incubacion', 'incubación', 'inc'],
  'ADM': [
    'administracion',
    'administración',
    'empresas',
    'administracion de empresas',
    'bloque de administracion',
    'adm',
  ],
  'AUD': ['auditorio', 'jacinta lopez', 'jacinta lópez', 'auditorio jacinta', 'aud'],
  'AGR': ['agricola', 'agrícola', 'ingenieria agricola', 'ingenería agrícola', 'agr'],
  'LAB': ['laboratorio', 'agropecuaria', 'laboratorio de agropecuaria', 'lab'],
  'KAA': ['kaacao', 'cacao', 'fabrica kaacao', 'fábrica kaacao', 'kaa'],
  'CAN': [
    'cancha',
    'acustica',
    'acústica',
    'cancha acustica',
    'cancha acústica',
    'concha acustica',
    'can',
  ],
  'COL': ['coliseo', 'coliseo espam', 'coliseo mfl', 'col'],
  'FMA': ['medio ambiente', 'facultad de medio ambiente', 'ambiental', 'fma'],
  'TUR': ['turismo', 'carrera de turismo', 'tur'],
  'HOT': ['hotel', 'higueron', 'higuerón', 'hotel higueron', 'hot'],
  'GAS': ['gastronomia', 'gastronomía', 'carrera de gastronomia', 'gas'],
  'COM': ['computacion', 'computación', 'carrera de computacion', 'sistemas', 'com'],
  'POS': ['posgrado', 'postgrado', 'pos'],
  'BIB': ['biblioteca', 'edificio biblioteca', 'bib'],
  'ADM2': ['edificio administrativo', 'administrativo', 'edificio admin'],
};

const Map<String, List<Edge>> grafo = {
  'VET': [(to: 'INC', costo: 70.0), (to: 'AGR', costo: 140.0)],
  'INC': [(to: 'VET', costo: 70.0), (to: 'ADM', costo: 200.0)],
  'ADM': [(to: 'INC', costo: 200.0), (to: 'AUD', costo: 40.0)],
  'AUD': [(to: 'ADM', costo: 40.0), (to: 'AGR', costo: 90.0)],
  'AGR': [
    (to: 'AUD', costo: 90.0),
    (to: 'VET', costo: 140.0),
    (to: 'LAB', costo: 1100.0),
  ],
  'LAB': [
    (to: 'AGR', costo: 1100.0),
    (to: 'KAA', costo: 70.0),
    (to: 'HOT', costo: 568.3),
  ],
  'KAA': [
    (to: 'LAB', costo: 70.0),
    (to: 'CAN', costo: 230.0),
    (to: 'FMA', costo: 252.1),
    (to: 'TUR', costo: 263.3),
  ],
  'CAN': [
    (to: 'KAA', costo: 230.0),
    (to: 'COL', costo: 216.4),
    (to: 'FMA', costo: 59.3),
    (to: 'TUR', costo: 47.8),
  ],
  'COL': [
    (to: 'CAN', costo: 216.4),
    (to: 'FMA', costo: 243.9),
    (to: 'TUR', costo: 230.5),
  ],
  'FMA': [
    (to: 'CAN', costo: 59.3),
    (to: 'COL', costo: 243.9),
    (to: 'TUR', costo: 16.4),
    (to: 'KAA', costo: 252.1),
  ],
  'TUR': [
    (to: 'CAN', costo: 47.8),
    (to: 'COL', costo: 230.5),
    (to: 'FMA', costo: 16.4),
    (to: 'KAA', costo: 263.3),
  ],
  'HOT': [
    (to: 'LAB', costo: 568.3),
    (to: 'COM', costo: 98.3),
    (to: 'BIB', costo: 148.2),
    (to: 'GAS', costo: 302.8),
  ],
  'GAS': [
    (to: 'HOT', costo: 302.8),
    (to: 'COM', costo: 216.4),
    (to: 'POS', costo: 174.5),
  ],
  'COM': [
    (to: 'HOT', costo: 98.3),
    (to: 'GAS', costo: 216.4),
    (to: 'POS', costo: 79.1),
    (to: 'ADM2', costo: 190.8),
    (to: 'BIB', costo: 71.4),
  ],
  'POS': [
    (to: 'GAS', costo: 174.5),
    (to: 'COM', costo: 79.1),
    (to: 'BIB', costo: 54.3),
  ],
  'BIB': [
    (to: 'HOT', costo: 148.2),
    (to: 'COM', costo: 71.4),
    (to: 'POS', costo: 54.3),
    (to: 'ADM2', costo: 135.4),
  ],
  'ADM2': [(to: 'COM', costo: 190.8), (to: 'BIB', costo: 135.4)],
};

const Map<String, Coord> coordenadas = {
  'VET': (lat: -0.819149, lon: -80.180859),
  'INC': (lat: -0.818524, lon: -80.180473),
  'ADM': (lat: -0.819159, lon: -80.179017),
  'AUD': (lat: -0.819396, lon: -80.178925),
  'AGR': (lat: -0.819323, lon: -80.179569),
  'LAB': (lat: -0.827551, lon: -80.187181),
  'KAA': (lat: -0.826878, lon: -80.187173),
  'CAN': (lat: -0.829740, lon: -80.184711),
  'COL': (lat: -0.830663, lon: -80.185314),
  'FMA': (lat: -0.828564, lon: -80.185462),
  'TUR': (lat: -0.828764, lon: -80.185604),
  'HOT': (lat: -0.827586, lon: -80.182257),
  'GAS': (lat: -0.825663, lon: -80.183319),
  'COM': (lat: -0.826645, lon: -80.182160),
  'POS': (lat: -0.826038, lon: -80.182198),
  'BIB': (lat: -0.826304, lon: -80.181779),
  'ADM2': (lat: -0.826315, lon: -80.180677),
};

// --- Waypoints para dibujar los caminos sobre el mapa ----------------------
//
// Esto es puramente visual: el algoritmo A* nunca lee este mapa, solo usa
// `grafo` con sus costos de siempre. `_waypoints` únicamente le dice a la
// pantalla del mapa por dónde dibujar la línea de cada conexión, para que
// siga el sendero real en vez de cortar en línea recta.
//
// Las conexiones que NO aparezcan aquí se dibujan como línea recta entre
// los dos edificios (razonable para las conexiones cortas). Se van
// agregando a medida que se levantan las coordenadas reales sobre
// OpenStreetMap (ver el plan del día 1).
//
// La clave es "ORIGEN-DESTINO"; no hace falta repetirla en ambos sentidos,
// `waypointsPara` ya busca en los dos órdenes posibles.
const Map<String, List<Coord>> _waypoints = {
  // Ejemplo de formato una vez que se levanten las coordenadas reales:
  // 'AGR-LAB': [
  //   (lat: -0.820500, lon: -80.181200),
  //   (lat: -0.822800, lon: -80.183900),
  //   (lat: -0.825100, lon: -80.186000),
  // ],

  'AGR-LAB': [
    (lat: -0.81932, lon: -80.17968),
    (lat: -0.81933, lon: -80.17969),
    (lat: -0.81933, lon: -80.17972),
    (lat: -0.81932, lon: -80.17995),
    (lat: -0.81932, lon: -80.17995),
    (lat: -0.81935, lon: -80.17997),
    (lat: -0.81938, lon: -80.18000),
    (lat: -0.81938, lon: -80.18000),
    (lat: -0.81946, lon: -80.18005),
    (lat: -0.81985, lon: -80.18024),
    (lat: -0.82024, lon: -80.18049),
    (lat: -0.82057, lon: -80.18070),
    (lat: -0.82064, lon: -80.18074),
    (lat: -0.82091, lon: -80.18086),
    (lat: -0.82125, lon: -80.18078),
    (lat: -0.82135, lon: -80.18076),
    (lat: -0.82236, lon: -80.18048),
    (lat: -0.82284, lon: -80.18030),
    (lat: -0.82290, lon: -80.18028),
    (lat: -0.82366, lon: -80.18014),
    (lat: -0.82400, lon: -80.18011),
    (lat: -0.82429, lon: -80.18027),
    (lat: -0.82449, lon: -80.18069),
    (lat: -0.82471, lon: -80.18131),
    (lat: -0.82471, lon: -80.18131),
    (lat: -0.82474, lon: -80.18144),
    (lat: -0.82644, lon: -80.18366),
    (lat: -0.82694, lon: -80.18431),
    (lat: -0.82713, lon: -80.18459),
    (lat: -0.82740, lon: -80.18508),
    (lat: -0.82757, lon: -80.18549),
    (lat: -0.82763, lon: -80.18571),
    (lat: -0.82763, lon: -80.18571),
    (lat: -0.82761, lon: -80.18574),
    (lat: -0.82760, lon: -80.18577),
    (lat: -0.82760, lon: -80.18580),
    (lat: -0.82761, lon: -80.18583),
    (lat: -0.82763, lon: -80.18587),
    (lat: -0.82766, lon: -80.18589),
    (lat: -0.82769, lon: -80.18590),
    (lat: -0.82769, lon: -80.18590),
    (lat: -0.82776, lon: -80.18600),
    (lat: -0.82811, lon: -80.18690),
    (lat: -0.82816, lon: -80.18702),
    (lat: -0.82816, lon: -80.18702),
    (lat: -0.82766, lon: -80.18721),
    (lat: -0.82766, lon: -80.18721),
  ],
  'HOT-LAB': [
  (lat: -0.82744, lon: -80.18246),
  (lat: -0.82755, lon: -80.18296),
  (lat: -0.82768, lon: -80.18320),
  (lat: -0.82772, lon: -80.18328),
  (lat: -0.82772, lon: -80.18328),
  (lat: -0.82759, lon: -80.18332),
  (lat: -0.82739, lon: -80.18354),
  (lat: -0.82726, lon: -80.18370),
  (lat: -0.82721, lon: -80.18376),
  (lat: -0.82712, lon: -80.18386),
  (lat: -0.82712, lon: -80.18386),
  (lat: -0.82759, lon: -80.18439),
  (lat: -0.82820, lon: -80.18510),
  (lat: -0.82894, lon: -80.18487),
  (lat: -0.82894, lon: -80.18487),
  (lat: -0.82916, lon: -80.18535),
  (lat: -0.82920, lon: -80.18556),
  (lat: -0.82910, lon: -80.18601),
  (lat: -0.82888, lon: -80.18618),
  (lat: -0.82789, lon: -80.18616),
  (lat: -0.82789, lon: -80.18616),
  (lat: -0.82781, lon: -80.18594),
  (lat: -0.82779, lon: -80.18588),
  (lat: -0.82779, lon: -80.18588),
  (lat: -0.82776, lon: -80.18590),
  (lat: -0.82773, lon: -80.18590),
  (lat: -0.82769, lon: -80.18590),
  (lat: -0.82769, lon: -80.18590),
  (lat: -0.82776, lon: -80.18600),
  (lat: -0.82811, lon: -80.18690),
  (lat: -0.82811, lon: -80.18690),
  (lat: -0.82762, lon: -80.18708),
  (lat: -0.82762, lon: -80.18708),
],
'GAS-HOT': [
  (lat: -0.82601, lon: -80.18310),
  (lat: -0.82644, lon: -80.18366),
  (lat: -0.82694, lon: -80.18431),
  (lat: -0.82789, lon: -80.18616),
  (lat: -0.82888, lon: -80.18618),
  (lat: -0.82910, lon: -80.18601),
  (lat: -0.82920, lon: -80.18556),
  (lat: -0.82916, lon: -80.18535),
  (lat: -0.82894, lon: -80.18487),
  (lat: -0.82820, lon: -80.18510),
  (lat: -0.82759, lon: -80.18439),
  (lat: -0.82712, lon: -80.18386),
  (lat: -0.82721, lon: -80.18376),
  (lat: -0.82726, lon: -80.18370),
  (lat: -0.82739, lon: -80.18354),
  (lat: -0.82759, lon: -80.18332),
  (lat: -0.82772, lon: -80.18328),
  (lat: -0.82768, lon: -80.18320),
  (lat: -0.82755, lon: -80.18296),
  (lat: -0.82744, lon: -80.18246),
],
'KAA-TUR': [
  (lat: -0.82702, lon: -80.18696),
  (lat: -0.82702, lon: -80.18695),
  (lat: -0.82702, lon: -80.18692),
  (lat: -0.82704, lon: -80.18689),
  (lat: -0.82741, lon: -80.18674),
  (lat: -0.82745, lon: -80.18672),
  (lat: -0.82748, lon: -80.18673),
  (lat: -0.82762, lon: -80.18708),
  (lat: -0.82811, lon: -80.18690),
  (lat: -0.82776, lon: -80.18600),
  (lat: -0.82769, lon: -80.18590),
  (lat: -0.82773, lon: -80.18590),
  (lat: -0.82776, lon: -80.18590),
  (lat: -0.82779, lon: -80.18588),
  (lat: -0.82781, lon: -80.18594),
  (lat: -0.82789, lon: -80.18616),
  (lat: -0.82888, lon: -80.18618),
  (lat: -0.82910, lon: -80.18601),
  (lat: -0.82920, lon: -80.18556),
  (lat: -0.82916, lon: -80.18535),
  (lat: -0.82903, lon: -80.18534),
],
'KAA-FMA': [
  (lat: -0.82702, lon: -80.18696),
  (lat: -0.82702, lon: -80.18695),
  (lat: -0.82702, lon: -80.18692),
  (lat: -0.82704, lon: -80.18689),
  (lat: -0.82741, lon: -80.18674),
  (lat: -0.82745, lon: -80.18672),
  (lat: -0.82748, lon: -80.18673),
  (lat: -0.82762, lon: -80.18708),
  (lat: -0.82811, lon: -80.18690),
  (lat: -0.82776, lon: -80.18600),
  (lat: -0.82769, lon: -80.18590),
  (lat: -0.82773, lon: -80.18590),
  (lat: -0.82776, lon: -80.18590),
  (lat: -0.82779, lon: -80.18588),
  (lat: -0.82781, lon: -80.18594),
  (lat: -0.82789, lon: -80.18616),
  (lat: -0.82888, lon: -80.18618),
  (lat: -0.82910, lon: -80.18601),
  (lat: -0.82920, lon: -80.18556),
  (lat: -0.82916, lon: -80.18535),
  (lat: -0.82903, lon: -80.18534),
],

};


/// Puntos intermedios para dibujar el camino entre [a] y [b], en ese orden,
/// sin importar en qué sentido se hayan guardado originalmente. Si no hay
/// waypoints registrados para esa conexión todavía, devuelve una lista
/// vacía (línea recta).
List<Coord> waypointsPara(String a, String b) {
  final directos = _waypoints['$a-$b'];
  if (directos != null) return directos;

  final inversos = _waypoints['$b-$a'];
  if (inversos != null) return inversos.reversed.toList();

  return const [];
}