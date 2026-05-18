// El Troso - wrapper flutter_tts (Fase 4.4.f).
//
// Scopo: nascondere la differenza tra init/setup di flutter_tts e il chiamante
// (che vuole solo "dillo a Giorgio"). Il servizio e' stateful internamente
// (tiene traccia se e' inizializzato) ma espone un'API imperativa semplice:
// speak(text) / stop().
//
// Scelte di configurazione:
// - Lingua: 'it-IT' (il profilo in 4.4.g potra' sovrascrivere per italiani
//   all'estero che vogliono risposte in EN).
// - Speech rate: 0.5. flutter_tts usa un range 0.0-1.0; il default 0.5 e'
//   gia' "moderato". Ho scelto 0.5 e non 0.4 perche' valori troppo bassi
//   producono una cadenza sillabata innaturale che suona roboticca anziche'
//   rassicurante — feedback empirico su anziani in Vite Vere Offline e in
//   letteratura TTS.
// - Pitch: 1.0 (default, niente voce "cartoon").
// - awaitSpeakCompletion(true): cosi' speak() ritorna solo quando l'audio
//   e' finito; utile per sequenze "dillo questo, poi quello".
//
// Nota su dispose: NON chiamiamo _tts.stop() in dispose perche' la voce
// dell'app potrebbe essere ancora in corso quando il provider viene
// smontato (es. cambio route). Preferiamo che finisca di parlare.

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;
  // Lingua attualmente impostata sull'engine TTS. Cambiare lingua è
  // un round-trip al servizio Android (~30-80 ms) quindi cachiamo per
  // evitare set ripetuti se diciamo più frasi nella stessa lingua.
  String _currentLang = 'it-IT';

  Future<void> _ensureInit() async {
    if (_initialized) return;
    await _tts.setLanguage(_currentLang);
    await _tts.setSpeechRate(0.5);
    await _tts.setPitch(1.0);
    await _tts.awaitSpeakCompletion(true);
    _initialized = true;
    debugPrint(
        '[tts] initialized (lang=$_currentLang, rate=0.5, pitch=1.0)');
  }

  /// Fa pronunciare [text] al TTS engine di sistema. Se non e' ancora stato
  /// inizializzato, inizializza al primo uso (lazy).
  ///
  /// [lang] (build 42): codice BCP-47 ('it-IT' / 'en-US'). Se omesso,
  /// usa la lingua corrente. Se diverso, fa setLanguage prima di speak.
  Future<void> speak(String text, {String? lang}) async {
    await _ensureInit();
    if (lang != null && lang != _currentLang) {
      debugPrint('[tts] switch lang $_currentLang → $lang');
      await _tts.setLanguage(lang);
      _currentLang = lang;
    }
    debugPrint('[tts] speak [$_currentLang]: $text');
    await _tts.speak(text);
  }

  /// Interrompe immediatamente l'eventuale parlato in corso. Idempotente.
  Future<void> stop() async {
    if (!_initialized) return;
    debugPrint('[tts] stop');
    await _tts.stop();
  }
}
