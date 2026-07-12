// lib/services/voice_recognition_service.dart
//
// Encapsula toda la interacción con el paquete `speech_to_text`, dejando a
// la UI únicamente la responsabilidad de mostrar el estado (escuchando o
// no) y reaccionar a los resultados.

import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class VoiceRecognitionService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  String _localeId = 'es-ES';

  bool get disponible => _speech.isAvailable;

  /// Debe llamarse una vez (por ejemplo en `initState`) antes de usar
  /// [escuchar]. Detecta automáticamente el mejor locale en español
  /// disponible en el dispositivo, priorizando es-EC.
  ///
  /// [onEscuchaFinalizada] se invoca cuando el motor deja de escuchar por
  /// su cuenta (fin natural, timeout o error), para que la UI pueda
  /// sincronizar su estado, por ejemplo apagando el ícono del micrófono.
  Future<void> inicializar({void Function()? onEscuchaFinalizada}) async {
    try {
      final listo = await _speech.initialize(
        onStatus: (estado) {
          if (estado == 'done' || estado == 'notListening') {
            onEscuchaFinalizada?.call();
          }
        },
        onError: (error) {
          debugPrint(
            '🎙️ Error del micrófono: ${error.errorMsg} '
            '- Permanente: ${error.permanent}',
          );
          onEscuchaFinalizada?.call();
        },
      );

      if (listo) {
        _localeId = await _detectarLocaleEspanol();
        debugPrint('🎙️ Micrófono listo. Idioma asignado: $_localeId');
      }
    } catch (e) {
      debugPrint('🎙️ Excepción al inicializar micrófono: $e');
    }
  }

  Future<String> _detectarLocaleEspanol() async {
    final locales = await _speech.locales();
    var candidato = 'es-ES'; // Plan B si no se encuentra nada mejor.

    for (final locale in locales) {
      final id = locale.localeId;
      if (id.contains('es-EC') || id.contains('es_EC')) {
        return id; // Coincidencia exacta para Ecuador: no hace falta seguir.
      }
      if (id.toLowerCase().startsWith('es')) {
        candidato = id; // Cualquier otra variante de español, como respaldo.
      }
    }
    return candidato;
  }

  /// Inicia la escucha. [onResultado] se llama con cada actualización,
  /// parcial o final, del texto reconocido. Si el motor no está
  /// disponible, se llama a [onNoDisponible] en su lugar.
  Future<void> escuchar({
    required void Function(String texto, bool esFinal) onResultado,
    void Function()? onNoDisponible,
  }) async {
    if (!_speech.isAvailable) {
      onNoDisponible?.call();
      return;
    }

    await _speech.listen(
      listenOptions: stt.SpeechListenOptions(localeId: _localeId),
      onResult: (resultado) {
        onResultado(resultado.recognizedWords, resultado.finalResult);
      },
    );
  }

  Future<void> detener() => _speech.stop();
}