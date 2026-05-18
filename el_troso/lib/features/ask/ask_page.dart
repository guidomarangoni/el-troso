// El Troso - AskPage (Fase 4.5.e).
//
// Flusso "Fai una domanda":
//   1. Utente scrive / detta via STT una domanda.
//   2. Tap su "Chiedi" → retrieve top-3 ricordi correlati dal vector
//      store (threshold 0.40) + prompt injection in Gemma 4 E2B.
//   3. Mostra risposta generata + ricordi consultati (tappabili per
//      aprire /memory/:id). Auto-play TTS sulla risposta.
//
// Stato: enum _AskPhase per UI: idle / retrieving / thinking / answered
// / noMatch / error. Niente StateNotifier separato: la logica vive nello
// State della pagina perche' e' lineare e single-screen. Se in futuro
// servira' multi-turn lo si estrarra' in un AskController.
//
// Prompt template: mirror 1:1 di Fase 3.6 (chatRag validato su Pixel 7a),
// ma con il persona name letto dal profileProvider invece che hardcoded
// "Giorgio". Il modello risponde in prima persona, una frase breve.
//
// STT: default 3s/30s (non narrative — la domanda e' atomica, non un
// racconto lungo). Feedback memory: pauseFor long serve solo ai campi
// di racconto.
//
// TTS: auto-play sulla risposta al primo ingresso in fase answered.
// awaitSpeakCompletion=true lato TtsService: qui pero' NON aspettiamo
// la fine (fire-and-forget) perche' vogliamo che l'utente possa gia'
// tappare su un ricordo per aprirlo mentre l'audio finisce. Se lascia
// la pagina, dispose() ferma il TTS.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:el_troso/core/locale/locale_codes.dart';
import 'package:el_troso/core/version.dart';
import 'package:el_troso/core/voice/stt_provider.dart';
import 'package:el_troso/core/voice/tts_provider.dart';
import 'package:el_troso/features/memory/memory.dart';
import 'package:el_troso/features/memory/memory_providers.dart';
import 'package:el_troso/features/memory/vector_store_provider.dart';
import 'package:el_troso/features/profile/profile_providers.dart';
import 'package:el_troso/l10n/app_localizations.dart';

import 'gemma_providers.dart';
import 'rag_answer.dart';

enum _AskPhase { idle, retrieving, thinking, answered, noMatch, error }

class AskPage extends ConsumerStatefulWidget {
  const AskPage({super.key});

  @override
  ConsumerState<AskPage> createState() => _AskPageState();
}

class _AskPageState extends ConsumerState<AskPage> {
  final TextEditingController _controller = TextEditingController();
  bool _isListening = false;
  _AskPhase _phase = _AskPhase.idle;
  RagAnswer? _result;
  String? _errorMessage;

  @override
  void dispose() {
    _controller.dispose();
    // Se il TTS sta parlando la risposta e l'utente esce, interrompi.
    // Fire-and-forget: dispose e' sync.
    // ignore: discarded_futures
    ref.read(ttsServiceProvider).stop();
    super.dispose();
  }

  // ───────────────────────────────────── STT

  Future<void> _toggleMic() async {
    final stt = ref.read(sttServiceProvider);
    if (_isListening) {
      await stt.stop();
      if (!mounted) return;
      setState(() => _isListening = false);
      return;
    }
    setState(() => _isListening = true);
    // Per le domande (testo atomico) default 3s/30s basta. Se l'utente
    // pausa troppo la domanda finisce prima: accettabile per "Fai una
    // domanda" che per design non e' un racconto.
    await stt.startListening(
      localeId: sttLocaleId(Localizations.localeOf(context)),
      onResult: (text, isFinal) {
        if (!mounted) return;
        setState(() {
          _controller.text = text;
          // Mantieni il cursore alla fine per UX pulita se l'utente
          // continua a parlare.
          _controller.selection = TextSelection.fromPosition(
            TextPosition(offset: _controller.text.length),
          );
          if (isFinal) _isListening = false;
        });
      },
    );
  }

  // ───────────────────────────────────── RAG flow

  Future<void> _ask() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;

    // Se il mic era acceso, fermalo prima di partire.
    if (_isListening) {
      await ref.read(sttServiceProvider).stop();
      if (!mounted) return;
      setState(() => _isListening = false);
    }

    // 1. Retrieve.
    setState(() {
      _phase = _AskPhase.retrieving;
      _result = null;
      _errorMessage = null;
    });

    final memoriesAsync = ref.read(memoriesProvider);
    final knownMemories = memoriesAsync.valueOrNull ?? const <Memory>[];
    final vectorStore = ref.read(vectorStoreServiceProvider);

    try {
      final results = await vectorStore.search(
        query,
        knownMemories: knownMemories,
      );

      if (!mounted) return;

      if (results.isEmpty) {
        setState(() => _phase = _AskPhase.noMatch);
        debugPrintAsk('no match above threshold for "$query"');
        return;
      }

      // Mappa RetrievalResult → RagSource (Memory + similarity). Se
      // un risultato ha id che non corrisponde a nessun Memory (es.
      // drift raro), lo saltiamo silenziosamente.
      final sources = <RagSource>[];
      for (final r in results) {
        Memory? found;
        for (final m in knownMemories) {
          if (m.id == r.id) {
            found = m;
            break;
          }
        }
        if (found != null) {
          sources.add(RagSource(memory: found, similarity: r.similarity));
        }
      }

      if (sources.isEmpty) {
        // Rare case: i risultati vector store non hanno match in JSON
        // (drift grave). syncWithMemories al prossimo giro lo risolve;
        // qui trattiamolo come noMatch con log esplicito.
        debugPrintAsk(
          'WARNING: retrieved ${results.length} docs but none match '
          'knownMemories ids — treating as noMatch',
        );
        setState(() => _phase = _AskPhase.noMatch);
        return;
      }

      // 2. Costruisci prompt e genera risposta.
      setState(() => _phase = _AskPhase.thinking);

      final profile = ref.read(profileProvider);
      final speakerName =
          (profile != null && profile.name.isNotEmpty) ? profile.name : 'io';
      final ricordiBlock = sources.map((s) => '- ${s.memory.text}').join('\n');
      // Prompt v4 (Fase 4.5.e - few-shot per ancorare ausiliari IT).
      // Rispetto a v3 aggiunti 2 esempi Q/A. Scelte deliberate:
      //   - esempio 1 (viaggio di nozze): question "dove" → risposta
      //     dichiarativa semplice, niente trappole.
      //   - esempio 2 (caduta dall'altalena): question "perche'" con
      //     verbi cadere+riflessivo — lo stesso pattern che ha generato
      //     "mi sono caduto" in v3. L'esempio mostra la forma corretta
      //     "sono caduto" + "mi sono rotto" per ancorare gli ausiliari
      //     senza ricorrere a istruzioni grammaticali esplicite (che sui
      //     modelli piccoli di solito non funzionano).
      //   - format uniforme "Ricordi / Domanda / Risposta" ripetuto 3
      //     volte (2 esempi + turno reale) → il modello completa il
      //     pattern.
      //   - "---" come separatore visivo: aiuta Gemma a non confondere
      //     ricordi reali con quelli degli esempi.
      // Costo: ~150 token in piu' in input → +0.5-1 s latenza stimata.
      // Ragioneremo sul trade-off dopo la misura empirica.
      final prompt =
          'Sei $speakerName e stai raccontando a qualcuno di famiglia. '
          'Rispondi alla domanda usando SOLO i ricordi forniti: non '
          'inventare nulla, se dai ricordi non emerge la risposta di\' '
          '"non mi ricordo bene". Quando puoi, usa le stesse parole dei '
          'ricordi senza riformulare. Usa un italiano naturale e '
          'colloquiale, una o due frasi, senza elenchi.\n\n'
          'Segui lo stile di questi esempi:\n\n'
          'Esempio 1.\n'
          'Ricordi:\n'
          '- Nel 1965 sono andato in viaggio di nozze a Parigi con mia '
          'moglie.\n'
          'Domanda: dove sono andato in viaggio di nozze?\n'
          'Risposta: Sono andato in viaggio di nozze a Parigi, nel 1965, '
          'con mia moglie.\n\n'
          'Esempio 2.\n'
          'Ricordi:\n'
          '- Da bambino stavo giocando in giardino, sono caduto '
          'dall\'altalena e mi sono rotto un braccio.\n'
          'Domanda: perche\' mi sono rotto un braccio?\n'
          'Risposta: Da bambino sono caduto dall\'altalena mentre giocavo '
          'in giardino.\n\n'
          '---\n\n'
          'Ora rispondi tu.\n'
          'Ricordi:\n$ricordiBlock\n\n'
          'Domanda: $query\n'
          'Risposta:';

      debugPrintAsk('prompt len=${prompt.length} sources=${sources.length}');

      final gemma = ref.read(gemmaServiceProvider);
      final answer = await gemma.ask(prompt);

      if (!mounted) return;

      final ragAnswer = RagAnswer(answer: answer.trim(), sources: sources);
      setState(() {
        _result = ragAnswer;
        _phase = _AskPhase.answered;
      });

      // Auto-play TTS sulla risposta. Fire-and-forget: non blocchiamo
      // l'UI, l'utente puo' gia' tappare sui ricordi mentre finisce.
      // ignore: discarded_futures
      ref.read(ttsServiceProvider).speak(
            ragAnswer.answer,
            lang: ttsLanguageCode(Localizations.localeOf(context)),
          );
    } catch (e, st) {
      debugPrintAsk('ask failed: $e\n$st');
      if (!mounted) return;
      setState(() {
        _phase = _AskPhase.error;
        _errorMessage = e.toString();
      });
    }
  }

  // ───────────────────────────────────── UI

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    debugPrintAsk(
      'render phase=$_phase isListening=$_isListening '
      'textLen=${_controller.text.length}',
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.askTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        actions: const [VersionBadge()],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Input domanda + mic. Resta in cima anche dopo answered
              // cosi' l'utente puo' fare una seconda domanda (riscrive
              // e tappa Chiedi di nuovo).
              TextField(
                controller: _controller,
                maxLines: 3,
                minLines: 1,
                textInputAction: TextInputAction.done,
                enabled: _phase != _AskPhase.retrieving &&
                    _phase != _AskPhase.thinking,
                decoration: InputDecoration(
                  hintText: l10n.askPromptQ,
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
                    color: _isListening ? theme.colorScheme.primary : null,
                    tooltip: l10n.askMicTooltip,
                    onPressed: (_phase == _AskPhase.retrieving ||
                            _phase == _AskPhase.thinking)
                        ? null
                        : _toggleMic,
                  ),
                ),
                onChanged: (_) => setState(() {}), // per abilitare Chiedi
              ),
              const SizedBox(height: 12),

              FilledButton(
                onPressed: (_controller.text.trim().isEmpty ||
                        _phase == _AskPhase.retrieving ||
                        _phase == _AskPhase.thinking)
                    ? null
                    : _ask,
                child: Text(l10n.askSubmitCta),
              ),

              const SizedBox(height: 24),

              // Corpo dinamico in base alla fase.
              Expanded(child: _buildBody(theme, l10n)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(ThemeData theme, AppLocalizations l10n) {
    switch (_phase) {
      case _AskPhase.idle:
        return const SizedBox.shrink();

      case _AskPhase.retrieving:
        return _LoadingBlock(label: l10n.askRetrievingLabel);

      case _AskPhase.thinking:
        return _LoadingBlock(label: l10n.askThinkingLabel);

      case _AskPhase.noMatch:
        return _FallbackBlock(
          icon: Icons.search_off,
          body: l10n.askNoMatchBody,
          ctaLabel: l10n.walkBackHomeCta,
          onCta: () => context.go('/home'),
        );

      case _AskPhase.error:
        return _FallbackBlock(
          icon: Icons.error_outline,
          body: '${l10n.errorTechnical}\n\n${_errorMessage ?? ''}'.trim(),
          ctaLabel: l10n.walkBackHomeCta,
          onCta: () => context.go('/home'),
        );

      case _AskPhase.answered:
        final result = _result!;
        return _AnswerView(result: result, l10n: l10n);
    }
  }
}

// ───────────────────────────────────── sub-widgets

class _LoadingBlock extends StatelessWidget {
  const _LoadingBlock({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 16),
        Text(label, style: theme.textTheme.bodyLarge, textAlign: TextAlign.center),
      ],
    );
  }
}

class _FallbackBlock extends StatelessWidget {
  const _FallbackBlock({
    required this.icon,
    required this.body,
    required this.ctaLabel,
    required this.onCta,
  });

  final IconData icon;
  final String body;
  final String ctaLabel;
  final VoidCallback onCta;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // SingleChildScrollView invece di Column "nudo" perche' per le
    // eccezioni il body puo' essere lungo (stack trace serializzato) e
    // una Column fissa andava in overflow. Cosi' se sta tutto in schermo
    // resta centrato, altrimenti scrolla.
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(icon, size: 48, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              body,
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton(onPressed: onCta, child: Text(ctaLabel)),
          ],
        ),
      ),
    );
  }
}

class _AnswerView extends StatelessWidget {
  const _AnswerView({required this.result, required this.l10n});

  final RagAnswer result;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      children: [
        // Card risposta.
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              result.answer,
              style: theme.textTheme.titleMedium,
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Header sources.
        Text(
          l10n.askSourcesHeader,
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 8),

        // Lista ricordi usati. Tap → /memory/:id.
        for (final s in result.sources)
          Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              title: Text(
                _preview(s.memory.text),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Text(
                s.similarity.toStringAsFixed(2),
                style: theme.textTheme.bodySmall,
              ),
              onTap: () => context.go('/memory/${s.memory.id}'),
            ),
          ),
        const SizedBox(height: 24),

        OutlinedButton(
          onPressed: () => context.go('/home'),
          child: Text(l10n.walkBackHomeCta),
        ),
      ],
    );
  }

  String _preview(String text) {
    final trimmed = text.trim().replaceAll('\n', ' ');
    if (trimmed.length <= 120) return trimmed;
    return '${trimmed.substring(0, 120)}...';
  }
}

// Helper di logging: prefix coerente per grep nei logcat.
void debugPrintAsk(String msg) {
  debugPrint('[ask] $msg');
}
