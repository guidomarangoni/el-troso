// El Troso — SoundService (build 22).
//
// Tre cue audio molto brevi e delicati per il gioco G1 "Memoria delle
// foto":
//   - flip()  ~60 ms  : tap su una carta scoperta (tono neutro 880 Hz)
//   - match() ~240 ms : coppia trovata (E5 + B5 ascendente)
//   - win()   ~650 ms : partita completata (arpeggio C-E-G-C, festoso)
//
// Decisioni di design:
// - Volume basso (0.2) e fade-in/out per evitare click meccanici sui
//   bordi del WAV. La filosofia del trittico el troso è "rumore minimo":
//   i suoni servono ad aiutare l'utente a capire che il tap è andato
//   a segno, non a celebrare in modo invasivo.
// - WAV puri sine generati offline (vedi script in assets/sounds/),
//   nessuna libreria audio esterna serve, niente royalty/credit per
//   sample di terze parti.
// - audioplayers usa un AudioPlayer per cue: essere instance-per-cue
//   permette di sovrapporre flip + match senza che l'uno tagli l'altro
//   (es. tap rapido su una coppia matchata).
// - Lazy init del primo play su Android: la prima riproduzione costa
//   100-200 ms (warmup AudioFocus). I tap successivi sono <10 ms.
// - Errori inghiottiti silenziosamente: un dispositivo senza output
//   audio (cuffie staccate / muto) non deve far crashare il gioco.

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class SoundService {
  // Un AudioPlayer per cue, così cue concomitanti non si tagliano.
  final AudioPlayer _flip = AudioPlayer();
  final AudioPlayer _match = AudioPlayer();
  final AudioPlayer _win = AudioPlayer();

  Future<void> _play(AudioPlayer p, String asset) async {
    try {
      await p.stop();
      await p.play(AssetSource(asset));
    } catch (e) {
      debugPrint('[sound] $asset failed: $e');
    }
  }

  Future<void> flip() => _play(_flip, 'sounds/flip.wav');
  Future<void> match() => _play(_match, 'sounds/match.wav');
  Future<void> win() => _play(_win, 'sounds/win.wav');

  Future<void> dispose() async {
    await _flip.dispose();
    await _match.dispose();
    await _win.dispose();
  }
}
