// El Troso - provider Riverpod per SttService (Fase 4.4.f).
//
// Stessa filosofia di tts_provider: singola istanza senza autoDispose. Una
// SpeechToText() non consuma risorse finche' non viene chiamato listen();
// tenerla in piedi evita ri-inizializzazioni ripetute (la initialize fa un
// round-trip al servizio Android di speech recognition, ~100-300 ms).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'stt_service.dart';

final sttServiceProvider = Provider<SttService>((ref) {
  return SttService();
});
