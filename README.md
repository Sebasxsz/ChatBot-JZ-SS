# 🧭 Chatbot ESPAM-MFL Navegación

Sistema de navegación peatonal intra-campus desarrollado para la Escuela Superior Politécnica Agropecuaria de Manabí (ESPAM MFL). Esta aplicación móvil permite a estudiantes, docentes y visitantes encontrar la ruta peatonal óptima entre los distintos edificios del campus utilizando un chatbot conversacional y mapas interactivos.

## ✨ Características Principales

*   **Enrutamiento Óptimo:** Implementación propia del algoritmo A* con heurística de Haversine para encontrar el camino más corto en un grafo estático de 17 edificios y 33 conexiones peatonales.
*   **Procesamiento de Lenguaje Natural (NLP):** Motor conversacional basado en expresiones regulares (RegEx) que reconoce sinónimos de edificios y conectores de origen/destino.
*   **Reconocimiento de Voz:** Integración de comandos por voz en español para una experiencia de usuario manos libres.
*   **Mapa Interactivo:** Visualización del campus mediante OpenStreetMap con polilíneas de ruta que siguen el trazado real de las vías peatonales.
*   **100% Offline:** Toda la lógica de negocio, NLP y cálculo de rutas funciona sin necesidad de conexión a internet (solo se requiere red para la descarga de los mosaicos del mapa).

## 🛠️ Tecnologías Utilizadas

*   **Framework:** Flutter / Dart
*   **Mapas:** `flutter_map` y `latlong2` (OpenStreetMap)
*   **Voz a Texto:** `speech_to_text`
*   **Arquitectura:** Cliente-only sin dependencias de backend.

---

## 📖 Manual de Usuario

A continuación, te explicamos cómo utilizar todas las funciones de la aplicación:

### 1. Interacción por Texto ⌨️
En la pantalla principal, encontrarás una consola de chat en la parte inferior. Puedes escribir tus consultas utilizando un lenguaje natural, tal como si estuvieras preguntando a una persona.
* Toca el **campo de texto** y escribe tu punto de origen y destino.
* El sistema es inteligente y reconoce sinónimos (ej. "vet" o "veterinaria") y conectores comunes ("desde", "hacia", "a", "hasta").
* **Ejemplos de comandos válidos:**
  * *"Ruta de veterinaria al auditorio"*
  * *"¿Cómo llego del laboratorio al hotel?"*
  * *"Quiero ir desde la biblioteca hacia el coliseo"*
* Presiona el botón de **Enviar** (ícono de flecha) para procesar tu solicitud.

### 2. Comandos de Voz 🎤
Si prefieres no escribir, puedes dictar tu ruta fácilmente utilizando el reconocimiento de voz integrado en español.
* Toca el **botón del micrófono** ubicado al lado del campo de texto en la consola inferior.
* Dicta tu consulta de forma clara (ej. *"De veterinaria a computación"*).
* La aplicación procesará tu voz, la convertirá a texto de forma automática y calculará la ruta.
* *(Nota: La primera vez que uses esta función, tu dispositivo te pedirá que otorgues permisos de micrófono a la aplicación).*

### 3. Interpretación de la Ruta (Resultados) 📋
Si el asistente comprende tu comando correctamente, te responderá con una **Tarjeta de Ruta interactiva (RouteCard)** que te mostrará:
* **Línea de tiempo de paradas:** Una secuencia paso a paso de los nodos/edificios por los que debes transitar.
* **Distancia total:** La longitud exacta del trayecto calculada en metros.
* **Tiempo estimado:** Una estimación del tiempo de caminata a una velocidad peatonal promedio (1.4 m/s).
* *Casos de error:* Si el sistema no reconoce algún edificio, te responderá indicando qué información falta o te pedirá que repitas la consulta.

### 4. Mapa Interactivo 🗺️
Una vez que el Chatbot te devuelve una ruta exitosa, puedes visualizar el trazado geográfico para guiarte mejor.
* Presiona el botón **"Ver en el mapa"** ubicado en los resultados del chat.
* Se abrirá una nueva pantalla con un mapa cartográfico interactivo basado en **OpenStreetMap**.
* En el mapa verás **íconos isométricos** que representan los edificios clave del campus.
* La ruta calculada se resaltará con una **línea de color (polilínea)** que conecta tu punto de origen con tu destino, siguiendo el trazado peatonal del campus.

---

## 🚀 Instalación y Ejecución

Para correr este proyecto en tu entorno local:

1. Clona este repositorio.
2. Asegúrate de tener instalado Flutter (versión 3.12.2 o superior).
3. Instala las dependencias ejecutando:
   ```bash
   flutter pub get