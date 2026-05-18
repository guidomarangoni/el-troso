// El Troso - modello Memory (Fase 4.5.a → 4.5.f → build 20).
//
// Rappresenta un ricordo raccontato dall'utente. Evoluzione:
// - 4.5.a: id + testo + timestamp (MVP)
// - 4.5.f: aggiunta tag, walker, walks (F7 + F9 + F12)
// - build 20: rimosso `imageDescription`. La descrizione visiva di una
//   foto NON è il ricordo autobiografico vero e usarla nel prompt G3
//   portava il modello a confermare dettagli non presenti nel testo
//   del ricordo. Cleanup completo: rimossa dal modello, da
//   vector_store_service e dai JSON seed. fromJson la ignora se
//   ancora presente in storage da versioni precedenti — il prossimo
//   save la droppa naturalmente.
//
// Campi aggiunti in 4.5.f:
// - `tag` (String?): categoria del ricordo. Valori ammessi: 'family',
//   'work', 'travel', 'home', 'other'. Null se l'utente non sceglie.
//   Il valore e' la chiave interna; la UI traduce via l10n (tagFamily, etc).
// - `walker` (String?): chi sta raccontando questo ricordo. Valori ammessi:
//   'self' (utente principale), 'child', 'grandchild', 'friend'. Null se
//   non specificato (default implicito = self).
// - `walks` (List<Walk>): lista dei ripercorrimenti. Ogni Walk ha un
//   timestamp (quando) e un walker (chi). La lista cresce ad ogni
//   "Ripercorriamolo insieme" nella MemoryDetailPage. Serve per F12
//   (orme che sbiadiscono): l'opacity dell'orma e' funzione del tempo
//   trascorso dall'ultimo walk.
//
// Retrocompatibilita': fromJson tollera campi mancanti (tag/walker/walks
// assenti nel JSON pre-4.5.f → null / []) e campi obsoleti come
// imageDescription (semplicemente ignorati senza errori).

/// Un singolo ripercorrimento di un ricordo.
class Walk {
  final DateTime walkedAt;
  final String walker; // 'self', 'child', 'grandchild', 'friend'

  const Walk({required this.walkedAt, required this.walker});

  Map<String, dynamic> toJson() => {
        'walkedAt': walkedAt.toUtc().toIso8601String(),
        'walker': walker,
      };

  factory Walk.fromJson(Map<String, dynamic> json) {
    return Walk(
      walkedAt: DateTime.parse(json['walkedAt'] as String).toUtc(),
      walker: json['walker'] as String? ?? 'self',
    );
  }

  @override
  String toString() => 'Walk(walkedAt=$walkedAt, walker=$walker)';
}

class Memory {
  final String id;
  final String text;
  final DateTime createdAt;
  final String? tag;      // 'family', 'work', 'travel', 'home', 'other'
  final String? walker;   // 'self', 'child', 'grandchild', 'friend'
  final List<Walk> walks; // ripercorrimenti, ordinati dal piu' recente
  final String? imagePath;        // path relativo immagine in app docs
  final String? audioPath;        // path relativo audio WAV in app docs
  /// Lingua originale del ricordo (build 42). 'it' | 'en'. Usata per:
  ///   - bottone "Traduci" on-demand: from = originalLang, to = locale UI
  ///   - TTS: leggere il testo nella lingua giusta
  ///   - non mostrare il bottone se originalLang coincide con la locale UI
  /// Default 'it' per retro-compat: i ricordi pre-build-42 sono tutti IT
  /// (l'app è nata IT-only e il seed corpus è in italiano).
  final String originalLang;

  const Memory({
    required this.id,
    required this.text,
    required this.createdAt,
    this.tag,
    this.walker,
    this.walks = const [],
    this.imagePath,
    this.audioPath,
    this.originalLang = 'it',
  });

  Memory copyWith({
    String? id,
    String? text,
    DateTime? createdAt,
    String? tag,
    String? walker,
    List<Walk>? walks,
    String? imagePath,
    String? audioPath,
    String? originalLang,
  }) {
    return Memory(
      id: id ?? this.id,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      tag: tag ?? this.tag,
      walker: walker ?? this.walker,
      walks: walks ?? this.walks,
      imagePath: imagePath ?? this.imagePath,
      audioPath: audioPath ?? this.audioPath,
      originalLang: originalLang ?? this.originalLang,
    );
  }

  /// Ultimo ripercorrimento, o null se mai ripercorso.
  Walk? get lastWalk => walks.isNotEmpty ? walks.first : null;

  /// Giorni trascorsi dall'ultimo ripercorrimento (o dalla creazione se
  /// mai ripercorso). Usato per calcolare l'opacity delle orme (F12).
  int get daysSinceLastWalk {
    final ref = lastWalk?.walkedAt ?? createdAt;
    return DateTime.now().toUtc().difference(ref).inDays;
  }

  /// Opacity dell'orma (F12): 1.0 se fresco, 0.6 se tra 7-13 gg, 0.3 se
  /// 14+ gg senza ripercorrimento. I threshold sono coerenti con
  /// ElTrosoColors.footprintBright/Fading/Ghost.
  double get footprintOpacity {
    final days = daysSinceLastWalk;
    if (days < 7) return 1.0;
    if (days < 14) return 0.6;
    return 0.3;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'createdAt': createdAt.toUtc().toIso8601String(),
        if (tag != null) 'tag': tag,
        if (walker != null) 'walker': walker,
        if (walks.isNotEmpty)
          'walks': walks.map((w) => w.toJson()).toList(growable: false),
        if (imagePath != null) 'imagePath': imagePath,
        if (audioPath != null) 'audioPath': audioPath,
        'originalLang': originalLang,
      };

  factory Memory.fromJson(Map<String, dynamic> json) {
    return Memory(
      id: json['id'] as String,
      text: json['text'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String).toUtc(),
      tag: json['tag'] as String?,
      walker: json['walker'] as String?,
      walks: (json['walks'] as List<dynamic>?)
              ?.map((w) => Walk.fromJson(w as Map<String, dynamic>))
              .toList() ??
          const [],
      imagePath: json['imagePath'] as String?,
      audioPath: json['audioPath'] as String?,
      // Migration build 42: ricordi pre-existenti senza originalLang
      // assumono 'it' (l'app è nata IT-only).
      originalLang: json['originalLang'] as String? ?? 'it',
      // imageDescription se presente in storage da versioni precedenti
      // viene silenziosamente ignorata: il campo non esiste piu' nel
      // modello (vedi commento di intestazione, build 20).
    );
  }

  @override
  String toString() =>
      'Memory(id=$id, text="${text.length > 40 ? '${text.substring(0, 40)}...' : text}", '
      'tag=$tag, walker=$walker, walks=${walks.length})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Memory &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          text == other.text &&
          createdAt == other.createdAt &&
          tag == other.tag &&
          walker == other.walker;

  @override
  int get hashCode => Object.hash(id, text, createdAt, tag, walker);
}
