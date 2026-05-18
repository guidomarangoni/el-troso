// El Troso - provider Riverpod per GemmaService (Fase 4.5.e).
//
// Istanza singola per il life dell'app. Il modello Gemma 4 E2B pesa
// 2.58 GB e il load costa ~10 s: se usassimo autoDispose pagheremmo
// il cold start a ogni apertura della AskPage. Il costo di tenerlo
// residente in memoria dopo il primo ask e' accettabile (il device
// ha abbastanza RAM e il delegate GPU gia' alloca i buffer).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'gemma_service.dart';

final gemmaServiceProvider = Provider<GemmaService>((ref) {
  return GemmaService();
});
