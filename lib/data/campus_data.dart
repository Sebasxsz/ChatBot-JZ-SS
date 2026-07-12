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
  'VET': (lat: -0.8191042309287083, lon: -80.18070584205533),
  'INC': (lat: -0.8184793400393129, lon: -80.18068170216947),
  'ADM': (lat: -0.8190613199660038, lon: -80.17890071539665),
  'AUD': (lat: -0.8193295134504462, lon: -80.17861908345724),
  'AGR': (lat: -0.8193054588772872, lon: -80.17946284266132),
  'LAB': (lat: -0.8275175347704268, lon: -80.1870480030674),
  'KAA': (lat: -0.826897170957849, lon: -80.18705667929609),
  'CAN': (lat: -0.8289493495008273, lon: -80.18582805994684),
  'COL': (lat: -0.8306550555082427, lon: -80.18489465120184),
  'FMA': (lat: -0.8285344886942664, lon: -80.18549412488781),
  'TUR': (lat: -0.828682413814722, lon: -80.18548515626249),
  'HOT': (lat: -0.8274703625918673, lon: -80.18194846667554),
  'GAS': (lat: -0.8252476162378222, lon: -80.1835522055805),
  'COM': (lat: -0.8266171478177358, lon: -80.18216960805292),
  'POS': (lat: -0.8259043539873512, lon: -80.18212996425095),
  'BIB': (lat: -0.826156455432419, lon: -80.18171422184288),
  'ADM2': (lat: -0.8262560220902032, lon: -80.18050823362339),
};