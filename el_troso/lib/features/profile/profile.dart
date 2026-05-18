// El Troso - modello Profile (Fase 4.4.e).
//
// Rappresenta il profilo dell'utente principale (es. Giorgio). Viene creato
// in onboarding (S1 nome → S2 vocativo → S3 decennio opzionale), salvato
// in shared_preferences, letto dalla home per il saluto e dal prompt RAG
// per il vocativo.
//
// Scelte di design:
// - `vocative` e' gia' il DISPLAY STRING finale ("Giorgio", "Signore",
//   "Nonno", "Papa'", ...). Non un enum da risolvere a runtime, perche'
//   cio' che viene detto a Giorgio di persona e' letterale, non tokenizzato.
//   Se poi servira' un enum (es. per decidere tra "signore"/"signora") lo
//   aggiungeremo come campo separato, non come trasformazione del display.
// - `decade` e' l'anno base del decennio (1930, 1940, ..., 2000). null se
//   l'utente ha toccato "Salta" in S3 - rispettiamo che possa non volerlo
//   dire, perche' il decennio serve solo a suggerire un sidekick per i
//   ricordi di epoca, non e' obbligatorio.
// - Nessun campo id: c'e' un solo profilo per device; i "walker" (familiari,
//   amici) sono un'altra entita' gestita come metadata sui ricordi, non qui.

class Profile {
  final String name;
  final String vocative;
  final int? decade;

  const Profile({
    required this.name,
    required this.vocative,
    this.decade,
  });

  Profile copyWith({
    String? name,
    String? vocative,
    int? decade,
  }) {
    return Profile(
      name: name ?? this.name,
      vocative: vocative ?? this.vocative,
      decade: decade ?? this.decade,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'vocative': vocative,
        'decade': decade,
      };

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      name: json['name'] as String,
      vocative: json['vocative'] as String,
      // decade puo' essere int o null (non memorizzato prima di 4.4.g
      // o esplicitamente saltato). Evitiamo cast distruttivo.
      decade: json['decade'] is int ? json['decade'] as int : null,
    );
  }

  @override
  String toString() =>
      'Profile(name=$name, vocative=$vocative, decade=$decade)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Profile &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          vocative == other.vocative &&
          decade == other.decade;

  @override
  int get hashCode => Object.hash(name, vocative, decade);
}
