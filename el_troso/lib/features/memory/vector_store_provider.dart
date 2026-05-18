// El Troso - provider Riverpod per VectorStoreService (Fase 4.5.d).
//
// Single instance per il life dell'app: l'embedder e' caricato una volta
// sola (~170 MB) e lo stato del vector store (SQLite connection) va
// preservato. Niente autoDispose.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'vector_store_service.dart';

final vectorStoreServiceProvider = Provider<VectorStoreService>((ref) {
  return VectorStoreService();
});
