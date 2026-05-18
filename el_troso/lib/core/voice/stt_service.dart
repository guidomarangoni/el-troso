// El Troso - wrapper speech_to_text (Fase 4.4.f).
//
// Scopo: offrire un'API imperativa minimale (init/start/stop) senza esporre
// al resto dell'app i dettagli del plugin. Lo stato reattivo del trascritto
// (parziale, finale, livello audio) lo gestisce il widget che usa il servizio
// — qui passiamo i risultati via callback.
//
// Perche' callback e non Stream: speech_to_text 7.x espone onResult come
// callback; costruire uno Stream richiederebbe un Controller extra e non
// porta vantaggi nel nostro caso (un solo listener per sessione).
//
// Permessi: speech_to_text richiede RECORD_AUDIO a runtime. Lo gestisce
// internamente il plugin (la prima initialize() triggera il system prompt).
// In AndroidManifest dobbiamo dichiarare il permesso - fatto in 4.4.f.

import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Callback per i risultati del riconoscimento.
/// [text] e' il trascritto corrente (parziale o finale).
/// [isFinal] e' true solo sull'ultimo risultato della sessione.
typedef SttResultCallback = void Function(String text, bool isFinal);

class SttService {
  final SpeechToText _stt = SpeechToText();
  bool _available = false;

  /// Inizializza il plugin e verifica disponibilita' hardware/permessi.
  /// Chiamarla presto (es. all'apertura della rotta che usa il mic) cosi'
  /// il prompt dei permessi arriva in un momento sensato, non durante il
  /// primo tap "registra".
  ///
  /// Ritorna true se il servizio e' pronto all'uso.
  Future<bool> init() async {
    if (_available) return true;
    _available = await _stt.initialize(
      onError: (err) => debugPrint('[stt] error: $err'),
      onStatus: (status) => debugPrint('[stt] status: $status'),
    );
    debugPrint('[stt] initialize done, available=$_available');
    return _available;
  }

  /// Avvia l'ascolto. Se non ancora inizializzato, chiama [init] in modo
  /// trasparente. Se il plugin non e' disponibile, ritorna senza fare nulla
  /// (niente crash, niente callback).
  Future<void> startListening({
    required SttResultCallback onResult,
    String localeId = 'it_IT',
    Duration listenFor = const Duration(seconds: 30),
    Duration pauseFor = const Duration(seconds: 3),
  }) async {
    if (!_available) {
      final ok = await init();
      if (!ok) {
        debugPrint('[stt] startListening aborted: service unavailable');
        return;
      }
    }
    debugPrint('[stt] startListening locale=$localeId');
    await _stt.listen(
      onResult: (SpeechRecognitionResult r) =>
          onResult(r.recognizedWords, r.finalResult),
      localeId: localeId,
      listenFor: listenFor,
      pauseFor: pauseFor,
      listenOptions: SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
      ),
    );
  }

  /// Ferma l'ascolto corrente. Idempotente: se non sta ascoltando non fa
  /// nulla di osservabile.
  Future<void> stop() async {
    debugPrint('[stt] stop');
    await _stt.stop();
  }

  /// True se il plugin sta attualmente catturando audio dal microfono.
  bool get isListening => _stt.isListening;
}
