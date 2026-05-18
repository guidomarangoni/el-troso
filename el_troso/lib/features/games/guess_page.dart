// El Troso - G2 "Indovina insieme": pagina (build 37).
//
// Flusso a phase:
//   1. _Phase.generating  Gemma sta formulando la domanda (~3s)
//   2. _Phase.waiting     domanda visibile, l'utente risponde (voce o testo)
//   3. _Phase.listening   STT IT attivo
//   4. _Phase.thinking    Gemma valuta la risposta vs ricordo
//   5. _Phase.feedback    feedback caldo + TTS auto + CTA "Un'altra"
//   6. _Phase.empty       nessun ricordo abbastanza ricco (testo <30 char)
//   7. _Phase.error       errore tecnico (Gemma down, STT init failed)
//
// EBM richiamata (vedi guess_logic.dart §EBM):
//   - SRT con stimolo verbale (USMART RCT 2017)
//   - Testing effect (Roediger & Karpicke 2006)
//   - Errorless learning (Clare PMC3381647)
//   - Reminiscence therapy 1:1 (Cochrane Woods 2018)
//
// Stato del trittico el troso:
//   - Ogni feedback positivo registra un Walk sul ricordo (walker=self).
//     Un'interrogazione riuscita è calpestio: rinforza F11/F12 + G4 SRT.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:el_troso/core/fullscreen_photo_view.dart';
import 'package:el_troso/core/game_info_sheet.dart';
import 'package:el_troso/core/locale/locale_codes.dart';
import 'package:el_troso/core/version.dart';
import 'package:el_troso/core/voice/stt_provider.dart';
import 'package:el_troso/core/voice/tts_provider.dart';
import 'package:el_troso/features/ask/gemma_providers.dart';
import 'package:el_troso/features/games/guess_logic.dart';
import 'package:el_troso/features/memory/memory.dart';
import 'package:el_troso/features/memory/memory_providers.dart';
import 'package:el_troso/features/profile/profile_providers.dart';
import 'package:el_troso/l10n/app_localizations.dart';

enum _Phase { generating, waiting, listening, thinking, feedback, empty, error }

class GuessPage extends ConsumerStatefulWidget {
  const GuessPage({super.key});

  @override
  ConsumerState<GuessPage> createState() => _GuessPageState();
}

class _GuessPageState extends ConsumerState<GuessPage> {
  Memory? _target;
  String _question = '';
  String _userAnswer = '';
  String _feedback = '';
  String _errorMessage = '';
  _Phase _phase = _Phase.generating;

  final TextEditingController _answerController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _newRound());
  }

  @override
  void dispose() {
    // ignore: discarded_futures
    ref.read(sttServiceProvider).stop();
    // ignore: discarded_futures
    ref.read(ttsServiceProvider).stop();
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _newRound() async {
    final memories =
        ref.read(memoriesProvider).valueOrNull ?? const <Memory>[];
    final pick = pickGuessTarget(memories);
    setState(() {
      _target = pick;
      _question = '';
      _userAnswer = '';
      _feedback = '';
      _errorMessage = '';
      _phase = pick == null ? _Phase.empty : _Phase.generating;
    });
    _answerController.clear();
    if (pick == null) return;
    await _generateQuestion(pick);
  }

  Future<void> _generateQuestion(Memory target) async {
    final prompt = buildGuessQuestionPrompt(memory: target);
    debugPrint('[guess] generating question for ${target.id}');
    try {
      final raw = await ref.read(gemmaServiceProvider).ask(prompt);
      if (!mounted) return;
      // Pulizia: a volte Gemma include "Domanda:" o virgolette.
      var clean = raw.trim();
      clean = clean.replaceFirst(RegExp(r'^["“”]'), '').trim();
      clean = clean.replaceFirst(RegExp(r'["“”]$'), '').trim();
      clean = clean.replaceFirst(RegExp(r'^Domanda\s*:\s*', caseSensitive: false), '').trim();
      setState(() {
        _question = clean;
        _phase = _Phase.waiting;
      });
      // Auto-TTS della domanda: la persona la sente leggere.
      // ignore: discarded_futures
      ref.read(ttsServiceProvider).speak(
            clean,
            lang: ttsLanguageCode(Localizations.localeOf(context)),
          );
    } catch (e, st) {
      debugPrint('[guess] question gen failed: $e\n$st');
      if (!mounted) return;
      setState(() {
        _phase = _Phase.error;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _toggleMic() async {
    final stt = ref.read(sttServiceProvider);
    if (_phase == _Phase.listening) {
      await stt.stop();
      if (!mounted) return;
      setState(() => _phase = _Phase.waiting);
      return;
    }
    setState(() {
      _phase = _Phase.listening;
      _userAnswer = '';
    });
    _answerController.clear();
    // Stop TTS se ancora in corso (ha appena letto la domanda).
    await ref.read(ttsServiceProvider).stop();
    await stt.startListening(
      localeId: sttLocaleId(Localizations.localeOf(context)),
      pauseFor: const Duration(seconds: 6),
      listenFor: const Duration(seconds: 30),
      onResult: (text, isFinal) {
        if (!mounted) return;
        setState(() => _userAnswer = text);
        _answerController.text = text;
        _answerController.selection = TextSelection.fromPosition(
          TextPosition(offset: text.length),
        );
        if (isFinal) {
          setState(() => _phase = _Phase.waiting);
        }
      },
    );
    if (!stt.isListening && mounted && _phase == _Phase.listening) {
      setState(() {
        _phase = _Phase.error;
        _errorMessage = AppLocalizations.of(context).errorTechnical;
      });
    }
  }

  Future<void> _sendAnswer() async {
    if (_target == null || _userAnswer.trim().isEmpty) return;
    await ref.read(sttServiceProvider).stop();
    setState(() => _phase = _Phase.thinking);

    final profile = ref.read(profileProvider);
    final speakerName = (profile != null && profile.name.isNotEmpty)
        ? profile.name
        : 'la persona';
    final prompt = buildGuessFeedbackPrompt(
      memory: _target!,
      question: _question,
      userAnswer: _userAnswer.trim(),
      speakerName: speakerName,
    );
    debugPrint('[guess] feedback prompt len=${prompt.length}');

    try {
      final answer = await ref.read(gemmaServiceProvider).ask(prompt);
      if (!mounted) return;
      final clean = answer.trim();

      // Registra Walk: ogni risposta è calpestio (anche se errata: la
      // persona ha comunque attraversato il ricordo).
      final walk = Walk(walkedAt: DateTime.now().toUtc(), walker: 'self');
      final updated =
          _target!.copyWith(walks: [walk, ..._target!.walks]);
      await ref.read(memoriesProvider.notifier).updateMemory(updated);

      setState(() {
        _feedback = clean;
        _phase = _Phase.feedback;
        _target = updated;
      });

      // ignore: discarded_futures
      ref.read(ttsServiceProvider).speak(
            clean,
            lang: ttsLanguageCode(Localizations.localeOf(context)),
          );
    } catch (e, st) {
      debugPrint('[guess] feedback failed: $e\n$st');
      if (!mounted) return;
      setState(() {
        _phase = _Phase.error;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.gameGuessTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: l10n.gameInfoWhatTitle,
            onPressed: () =>
                GameInfoSheet.show(context, GameInfoKind.guess),
          ),
          const VersionBadge(),
        ],
      ),
      body: SafeArea(child: _buildBody(theme, l10n)),
    );
  }

  Widget _buildBody(ThemeData theme, AppLocalizations l10n) {
    if (_phase == _Phase.empty) {
      return _EmptyBody(l10n: l10n);
    }
    if (_phase == _Phase.error) {
      return _ErrorBody(
        message: '${l10n.errorTechnical}\n\n$_errorMessage'.trim(),
        onBack: () => context.go('/home'),
        backLabel: l10n.walkBackHomeCta,
      );
    }
    final target = _target;
    if (target == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // SingleChildScrollView (non Expanded) per evitare overflow giallo-
    // nero quando la tastiera si apre o il contenuto cresce.
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Foto opzionale (più bassa che in G3, perché qui il focus è
          // la domanda + risposta testuale).
          if (target.imagePath != null && File(target.imagePath!).existsSync())
            GestureDetector(
              onTap: () => FullscreenPhotoView.open(
                context,
                imagePath: target.imagePath!,
                heroTag: 'guess-photo-${target.id}',
              ),
              child: SizedBox(
                height: 180,
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Hero(
                      tag: 'guess-photo-${target.id}',
                      child: Image.file(
                        File(target.imagePath!),
                        fit: BoxFit.contain,
                        width: double.infinity,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (target.imagePath != null) const SizedBox(height: 16),
          _buildPhaseArea(theme, l10n, target),
        ],
      ),
    );
  }

  Widget _buildPhaseArea(ThemeData theme, AppLocalizations l10n, Memory target) {
    switch (_phase) {
      case _Phase.generating:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 60),
          child: Column(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                l10n.gameGuessGenerating,
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );

      case _Phase.waiting:
      case _Phase.listening:
        final isListening = _phase == _Phase.listening;
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // La domanda generata da Gemma.
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                _question,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  height: 1.35,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _answerController,
              maxLines: 2,
              minLines: 1,
              textInputAction: TextInputAction.done,
              style: theme.textTheme.bodyLarge,
              decoration: InputDecoration(
                hintText: l10n.gameGuessAnswerHint,
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (v) => setState(() => _userAnswer = v),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: OutlinedButton.icon(
                    icon: Icon(isListening ? Icons.stop : Icons.mic),
                    onPressed: _toggleMic,
                    label: Text(isListening
                        ? l10n.recognizeStopCta
                        : (_userAnswer.isEmpty
                            ? l10n.gameGuessSpeakCta
                            : l10n.recognizeRetryCta)),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.send),
                    onPressed: _userAnswer.trim().isEmpty || isListening
                        ? null
                        : _sendAnswer,
                    label: Text(l10n.gameGuessSendCta),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );

      case _Phase.thinking:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 60),
          child: Column(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                l10n.askThinkingLabel,
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );

      case _Phase.feedback:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.secondary,
                  width: 1.5,
                ),
              ),
              child: Text(
                _feedback,
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.4),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const Icon(Icons.refresh),
              onPressed: _newRound,
              label: Text(l10n.gameGuessAnotherCta),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
              ),
            ),
          ],
        );

      case _Phase.empty:
      case _Phase.error:
        return const SizedBox.shrink();
    }
  }
}

class _EmptyBody extends StatelessWidget {
  const _EmptyBody({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.menu_book_outlined,
              size: 48,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.gameGuessEmptyBody,
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({
    required this.message,
    required this.onBack,
    required this.backLabel,
  });
  final String message;
  final VoidCallback onBack;
  final String backLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline,
              size: 48, color: theme.colorScheme.error),
          const SizedBox(height: 16),
          Text(message,
              style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          OutlinedButton(onPressed: onBack, child: Text(backLabel)),
        ],
      ),
    );
  }
}
