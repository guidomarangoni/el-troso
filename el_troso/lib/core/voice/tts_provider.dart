// El Troso - provider Riverpod per TtsService (Fase 4.4.f).
//
// Un singolo TtsService vivo per l'app. NON usiamo autoDispose perche' il
// costo di tenere l'istanza in memoria e' trascurabile (un paio di canali
// MethodChannel) e i cambi di route ce la farebbero re-inizializzare ogni
// volta, introducendo un ritardo percettibile prima della prima parola.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'tts_service.dart';

final ttsServiceProvider = Provider<TtsService>((ref) {
  return TtsService();
});
