// lib/screens/chat_screen.dart
//
// Pantalla principal. Su única responsabilidad es coordinar: mantener la
// lista de mensajes, delegar la interpretación del texto a [RouteEngine],
// delegar el reconocimiento de voz a [VoiceRecognitionService], y renderizar
// los widgets de `chat_widgets.dart`. Ya no contiene lógica de negocio.

import 'package:flutter/material.dart';

import '../models/chat_models.dart';
import '../services/route_engine.dart';
import '../services/voice_recognition_service.dart';
import '../utils/color_utils.dart';
import '../widgets/chat_widgets.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _voz = VoiceRecognitionService();

  final List<ChatMessage> _mensajes = [];
  bool _estaEscribiendo = false;
  bool _escuchando = false;
  String _textoDictado = '';

  static const _sugerencias = <RouteSuggestion>[
    (etiqueta: '🏫 Vet ➔ Auditorio', origen: 'VET', destino: 'AUD'),
    (etiqueta: '💼 Admin ➔ Agrícola', origen: 'ADM', destino: 'AGR'),
    (etiqueta: '💻 Comp ➔ Coliseo', origen: 'COM', destino: 'COL'),
  ];

  @override
  void initState() {
    super.initState();
    _voz.inicializar(onEscuchaFinalizada: _sincronizarEscuchaApagada);

    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        _mensajes.add(
          const ChatMessage.bot(
            '¡Hola! 🤖 Soy tu asistente de rutas.\n\n'
            'Puedes escribirme o presionar el micrófono abajo para decirme '
            'a dónde quieres ir de forma hablada.',
          ),
        );
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sincronizarEscuchaApagada() {
    if (mounted) setState(() => _escuchando = false);
  }

  Future<void> _alternarEscucha() async {
    if (_escuchando) {
      setState(() => _escuchando = false);
      await _voz.detener();
      if (_textoDictado.isNotEmpty) _enviarMensaje();
      return;
    }

    setState(() {
      _escuchando = true;
      _textoDictado = '';
    });

    await _voz.escuchar(
      onNoDisponible: () {
        debugPrint('🎙️ El micrófono no está listo o no tiene permisos.');
        setState(() => _escuchando = false);
        _voz.inicializar(onEscuchaFinalizada: _sincronizarEscuchaApagada);
      },
      onResultado: (texto, esFinal) {
        // Candado de seguridad: ignora ráfagas de resultados que lleguen
        // después de que ya se apagó la escucha manualmente.
        if (!_escuchando) return;

        setState(() {
          _textoDictado = texto;
          _controller.text = texto;
        });

        if (esFinal && texto.isNotEmpty) {
          setState(() => _escuchando = false);
          _voz.detener();
          _enviarMensaje();
        }
      },
    );
  }

  void _enviarMensaje({String? textoPredefinido}) {
    final texto = textoPredefinido ?? _controller.text.trim();
    if (texto.isEmpty) return;

    setState(() {
      _mensajes.add(ChatMessage.usuario(texto));
      _estaEscribiendo = true;
    });

    if (textoPredefinido == null) _controller.clear();
    _textoDictado = '';
    _desplazarAlFinal();

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      final resultado = RouteEngine.interpretarMensaje(texto);
      setState(() {
        _mensajes.add(ChatMessage.bot(resultado.mensaje, resultado: resultado));
        _estaEscribiendo = false;
      });
      _desplazarAlFinal();
    });
  }

  void _desplazarAlFinal() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: _buildAppBar(theme),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _buildListaMensajes()),
            if (!_escuchando)
              SuggestionsCarousel(
                sugerencias: _sugerencias,
                onSeleccionar: (s) => _enviarMensaje(
                  textoPredefinido: '${s.origen} a ${s.destino}',
                ),
              ),
            InputConsole(
              controller: _controller,
              escuchando: _escuchando,
              enviando: _estaEscribiendo,
              onMicPressed: _alternarEscucha,
              onEnviarPressed: _enviarMensaje,
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'ESPAM-MFL Navegación',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          Text(
            _escuchando ? '🎙️ Escuchando tu voz...' : 'Inteligencia de Rutas Críticas',
            style: TextStyle(
              fontSize: 11,
              color: _escuchando ? Colors.greenAccent : Colors.white.conOpacidad(0.7),
            ),
          ),
        ],
      ),
      centerTitle: true,
      backgroundColor: _escuchando ? const Color(0xff0a2540) : theme.colorScheme.primary,
      elevation: 0,
    );
  }

  Widget _buildListaMensajes() {
    final total = _mensajes.length + (_estaEscribiendo ? 1 : 0);
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      reverse: true,
      itemCount: total,
      itemBuilder: (context, index) {
        if (_estaEscribiendo && index == 0) return const TypingIndicator();

        final indiceReal = _estaEscribiendo ? index - 1 : index;
        final mensaje = _mensajes[_mensajes.length - 1 - indiceReal];

        if (mensaje.resultado case RouteFound ruta) {
          return RouteCard(ruta: ruta);
        }
        return ChatBubble(esUsuario: mensaje.esUsuario, texto: mensaje.texto);
      },
    );
  }
}