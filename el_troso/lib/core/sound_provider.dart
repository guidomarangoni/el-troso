// El Troso — provider singleton del SoundService (build 22).
//
// Singleton applicativo: gli AudioPlayer restano caldi tra una
// partita e l'altra del G1 (warmup pagato una volta sola).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'sound_service.dart';

final soundServiceProvider = Provider<SoundService>((ref) {
  final svc = SoundService();
  ref.onDispose(svc.dispose);
  return svc;
});
