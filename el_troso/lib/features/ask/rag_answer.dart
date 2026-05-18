// El Troso - RagAnswer (Fase 4.5.e).
//
// Risultato di un turno RAG: la risposta generata da Gemma 4 + la lista
// dei ricordi usati come fonti (gia' risolti a Memory, non piu' a
// RetrievalResult). La AskPage usa 'sources' per mostrare sotto la
// risposta i ricordi consultati, tappabili per aprire /memory/:id.
//
// Perche' non riusare RetrievalResult (tipo flutter_gemma): quello ha
// id/content/similarity ma non il createdAt ne' l'accesso pulito al
// Memory del repo. Mappando subito a Memory abbiamo un oggetto gia'
// pronto per la UI e coerente col resto dell'app.

import '../memory/memory.dart';

class RagSource {
  const RagSource({required this.memory, required this.similarity});

  final Memory memory;

  /// Valore 0..1 dalla cosine similarity (post-threshold).
  final double similarity;
}

class RagAnswer {
  const RagAnswer({required this.answer, required this.sources});

  final String answer;
  final List<RagSource> sources;
}
