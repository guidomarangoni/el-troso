// El Troso - G4 Spaced Retrieval (Fase 4.5.h).
//
// Implementa l'algoritmo di Spaced Retrieval Training (SRT) come "gioco"
// di richiamo: ogni giorno la home propone UN ricordo a intervalli
// crescenti. Il calpestio (Walk) di quel ricordo costituisce la sessione
// di gioco — non c'e' una UI di gioco separata: l'azione e' "ripercorri
// questo ricordo oggi".
//
// PERCHE' QUESTO E' IL GIOCO CON LA EBM PIU' SOLIDA NEL CORPUS PROGETTO
// ────────────────────────────────────────────────────────────────────
// Lo SRT e' uno degli interventi non-farmacologici con la base empirica
// piu' consolidata per la memoria in MCI e demenza lieve. Riferimenti
// peer-reviewed citati in `docs/El Troso - Studi scientifici.md` §5b:
//
//   - Hopper T, Mahendra N, Kim E, et al. (2013).
//     "A literature review of spaced-retrieval interventions: a direct
//     memory intervention for people with dementia." PMID: 23886395.
//     Review di 34 studi: SRT insegna con successo associazioni
//     nome-volto e nome-oggetto in persone con demenza.
//
//   - "USMART" RCT (2017). Alzheimer's Research & Therapy.
//     RCT crossover su 50 pazienti MCI con programma tablet-based:
//     miglioramenti significativi su Word List Recall vs usual care.
//     → riferimento empirico piu' diretto per "SRT su tablet/smartphone
//       in MCI" che e' esattamente la categoria di El Troso.
//
//   - "Spaced Retrieval Effects on Learning Capacity in Patients With
//     Mild-to-Moderate Cognitive Impairment: A Systematic Review and
//     Meta-Analysis" (2023). European Psychologist 28(4).
//     Conferma della robustezza dell'effetto SRT.
//
//   - Camp CJ (2001). Riferimento storico-fondativo.
//
//   - "Algorithmic Spaced Retrieval Enhances Long-Term Memory in
//     Alzheimer Disease: Case-Control Pilot Study" (2024).
//     JMIR Formative Research 8:e51943.
//     SRT con AI che traccia la curva di oblio individuale → benefici
//     misurabili in AD. → giustifica la nostra scelta di un algoritmo
//     adattivo (anche se MVP usa intervalli fissi, non personalizzati).
//
// ALGORITMO MVP — INTERVALLI FISSI A SCALA CRESCENTE
// ────────────────────────────────────────────────────────────────────
// Per ogni Memory, il "next due date" dipende da quante volte e' stata
// ripercorsa (livello SRT):
//
//   livello 0 (mai ripercorsa):  1 giorno dopo createdAt
//   livello 1 (1 walk):          3 giorni dopo lastWalkAt
//   livello 2 (2 walks):         7 giorni dopo lastWalkAt
//   livello 3 (3 walks):        14 giorni dopo lastWalkAt
//   livello 4+ (consolidato):   30 giorni dopo lastWalkAt
//
// Questa progressione 1→3→7→14→30 e' la curva tipica usata negli studi
// SRT piu' citati (Hopper review riassume varianti 1d-30d). Non e' la
// curva personalizzata di JMIR Formative 2024 — quella richiederebbe
// modello di oblio per-utente, fuori scope MVP.
//
// SCELTA ETICA: NIENTE NOTIFICHE PUSH
// ────────────────────────────────────────────────────────────────────
// La feature OUT in VERTICAL_SLICE_SPEC §3 "no notifiche push" e'
// onorata: la card "Oggi" appare in home alla normale apertura della
// app. Nessun reminder esterno. SRT classico in clinica usa il
// terapista come "trigger"; qui il trigger e' la routine quotidiana di
// apertura dell'app. Coerente con: Gitlin 2012 (interventi invasivi
// peggiorano senso di sorveglianza in anziani) e con il principio del
// trittico "calpestio volontario, non imposto".
//
// EMPTY STATE
// ────────────────────────────────────────────────────────────────────
// Se nessun ricordo e' "due" oggi (es. tutti freschi o tutti stra-
// consolidati), `pickTodaysMemory` ritorna null. La home in quel caso
// nasconde la card OGGI (o mostra messaggio "il sentiero e' fresco,
// torna a calpestarlo").

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:el_troso/features/memory/memory.dart';
import 'package:el_troso/features/memory/memory_providers.dart';

/// Curva degli intervalli SRT, in giorni. L'index = livello (numero di
/// walks gia' fatte). Oltre [_kIntervalsDays.length-1], si usa l'ultimo
/// valore (consolidato).
const List<int> _kIntervalsDays = [1, 3, 7, 14, 30];

/// Calcola la data in cui un ricordo dovrebbe essere ripercorso la
/// prossima volta secondo la curva SRT.
DateTime nextDueAt(Memory m) {
  final level = m.walks.length.clamp(0, _kIntervalsDays.length - 1);
  final intervalDays = _kIntervalsDays[level];
  final reference = m.walks.isNotEmpty ? m.walks.first.walkedAt : m.createdAt;
  return reference.add(Duration(days: intervalDays));
}

/// Sceglie il ricordo da proporre oggi:
/// - solo ricordi con nextDueAt <= now (cioè "due" o overdue)
/// - tra quelli, il più "overdue" (nextDueAt più vecchio) vince
/// - se nessuno è due, ritorna null (empty state)
Memory? pickTodaysMemory(List<Memory> memories) {
  final now = DateTime.now().toUtc();
  final due = <(Memory, DateTime)>[];
  for (final m in memories) {
    final nd = nextDueAt(m);
    if (!nd.isAfter(now)) {
      due.add((m, nd));
    }
  }
  if (due.isEmpty) return null;
  // Ordina per nextDueAt ascendente (più overdue prima).
  due.sort((a, b) => a.$2.compareTo(b.$2));
  return due.first.$1;
}

/// Provider: il ricordo del giorno secondo SRT, watchato sui memories.
/// Ritorna null se non c'è nulla da ripercorrere oggi.
///
/// Si auto-aggiorna quando un Walk viene registrato (memoriesProvider
/// emette nuovo stato → questo ricomputa il pick).
final todaysMemoryProvider = Provider<Memory?>((ref) {
  final async = ref.watch(memoriesProvider);
  final list = async.valueOrNull ?? const <Memory>[];
  return pickTodaysMemory(list);
});

/// Etichetta human-readable del livello SRT corrente di un ricordo.
/// Utile per debug e per mostrare il "livello di consolidamento" in UI
/// (eventuale evoluzione v1.x).
String srtLevelLabel(Memory m) {
  final n = m.walks.length;
  if (n == 0) return 'fresco';
  if (n == 1) return 'primo richiamo';
  if (n == 2) return 'in consolidamento';
  if (n == 3) return 'ben consolidato';
  return 'maturo';
}
