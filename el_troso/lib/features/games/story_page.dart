// El Troso - G5 "Storia continua": pagina (build 37).
//
// Flusso:
//   1. _Phase.intro      foto + incipit del ricordo a video, TTS legge
//                        l'incipit, poi prompt "...e poi cosa è successo?"
//   2. _Phase.waiting    l'utente vede il TextField + bottoni (voce/testo)
//   3. _Phase.listening  STT IT attivo
//   4. _Phase.thinking   Gemma valuta la continuazione utente vs vera
//   5. _Phase.feedback   feedback caldo + ricordo completo + CTA "Un'altra"
//   6. _Phase.empty      nessun ricordo abbastanza lungo
//   7. _Phase.error      errore tecnico
//
// EBM richiamata (vedi story_logic.dart §EBM):
//   - Cotelli M. et al. (2012) stimolazione narrativa in MCI/AD
//   - Cochrane Woods 2018 reminiscenza 1:1
//   - Bluck & Levine 1998 reminiscence as autobiographical memory
//   - Carstensen positivity effect 2012

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
import 'package:el_troso/features/games/story_logic.dart';
import 'package:el_troso/features/memory/memory.dart';
import 'package:el_troso/features/memory/memory_providers.dart';
import 'package:el_troso/features/profile/profile_providers.dart';
import 'package:el_troso/l10n/app_localizations.dart';

enum _Phase { intro, waiting, listening, thinking, feedback, empty, error }

class StoryPage extends ConsumerStatefulWidget {
  const StoryPage({super.key});

  @override
  ConsumerState<StoryPage> createState() => _StoryPageState();
}

class _StoryPageState extends ConsumerState<StoryPage> {
  Memory? _target;
  StorySegments _segments = const StorySegments(incipit: '', continuation: '');
  String _userContinuation = '';
  String _feedback = '';
  String _errorMessage = '';
  _Phase _phase = _Phase.intro;

  final TextEditingController _continuationController = TextEditingController();

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
    _continuationController.dispose();
    super.dispose();
  }

  Future<void> _newRound() async {
    final memories =
        ref.read(memoriesProvider).valueOrNull ?? const <Memory>[];
    final pick = pickStoryTarget(memories);
    if (pick == null) {
      setState(() {
        _target = null;
        _phase = _Phase.empty;
      });
      return;
    }
    final segments = segmentForStory(pick.text);
    setState(() {
      _target = pick;
      _segments = segments;
      _userContinuation = '';
      _feedback = '';
      _errorMessage = '';
      _phase = _Phase.intro;
    });
    _continuationController.clear();
    // Auto-TTS dell'incipit. Il prompt "...e poi cosa è successo?" è
    // visivo + UI: non lo facciamo ripetere via TTS per non rallentare.
    // L'incipit è testo del ricordo → leggi nella sua lingua originale.
    // ignore: discarded_futures
    ref.read(ttsServiceProvider).speak(
          segments.incipit,
          lang: ttsLanguageCodeFromIso(pick.originalLang),
        );
    // Dopo un attimo passiamo automaticamente a waiting (l'utente vede
    // i bottoni) — non aspettiamo la fine del TTS perché è bloccante.
    Future<void>.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      if (_phase == _Phase.intro) {
        setState(() => _phase = _Phase.waiting);
      }
    });
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
      _userContinuation = '';
    });
    _continuationController.clear();
    await ref.read(ttsServiceProvider).stop();
    await stt.startListening(
      localeId: sttLocaleId(Localizations.localeOf(context)),
      pauseFor: const Duration(seconds: 8),
      listenFor: const Duration(seconds: 60),
      onResult: (text, isFinal) {
        if (!mounted) return;
        setState(() => _userContinuation = text);
        _continuationController.text = text;
        _continuationController.selection = TextSelection.fromPosition(
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

  Future<void> _sendContinuation() async {
    if (_target == null || _userContinuation.trim().isEmpty) return;
    await ref.read(sttServiceProvider).stop();
    setState(() => _phase = _Phase.thinking);

    final profile = ref.read(profileProvider);
    final speakerName = (profile != null && profile.name.isNotEmpty)
        ? profile.name
        : 'la persona';
    final prompt = buildStoryFeedbackPrompt(
      memory: _target!,
      incipit: _segments.incipit,
      trueContinuation: _segments.continuation,
      userContinuation: _userContinuation.trim(),
      speakerName: speakerName,
    );
    debugPrint('[story] feedback prompt len=${prompt.length}');

    try {
      final answer = await ref.read(gemmaServiceProvider).ask(prompt);
      if (!mounted) return;
      final clean = answer.trim();

      // Walk: ogni continuazione è calpestio del ricordo.
      final walk = Walk(walkedAt: DateTime.now().toUtc(), walker: 'self');
      final updated =
          _target!.copyWith(walks: [walk, ..._target!.walks]);
      await ref.read(memoriesProvider.notifier).updateMemory(updated);

      setState(() {
        _feedback = clean;
        _phase = _Phase.feedback;
        _target = updated;
      });

      // Feedback prodotto da Gemma con prompt nella lingua UI.
      // ignore: discarded_futures
      ref.read(ttsServiceProvider).speak(
            clean,
            lang: ttsLanguageCode(Localizations.localeOf(context)),
          );
    } catch (e, st) {
      debugPrint('[story] feedback failed: $e\n$st');
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
        title: Text(l10n.gameStoryTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: l10n.gameInfoWhatTitle,
            onPressed: () =>
                GameInfoSheet.show(context, GameInfoKind.story),
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

    // SingleChildScrollView (non Expanded) per:
    //   - tastiera aperta: il body si compatta scrollabile invece di
    //     overflow giallo-nero.
    //   - incipit lungo: il TextField ha minLines/maxLines bounded e
    //     tutto cresce naturalmente nello scroll.
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (target.imagePath != null && File(target.imagePath!).existsSync())
            GestureDetector(
              onTap: () => FullscreenPhotoView.open(
                context,
                imagePath: target.imagePath!,
                heroTag: 'story-photo-${target.id}',
              ),
              child: SizedBox(
                height: 200,
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Hero(
                      tag: 'story-photo-${target.id}',
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
          if (target.imagePath != null) const SizedBox(height: 12),
          _buildPhaseArea(theme, l10n, target),
        ],
      ),
    );
  }

  Widget _buildPhaseArea(ThemeData theme, AppLocalizations l10n, Memory target) {
    switch (_phase) {
      case _Phase.intro:
      case _Phase.waiting:
      case _Phase.listening:
        final isListening = _phase == _Phase.listening;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Incipit del ricordo (in alto, a video).
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.25),
                ),
              ),
              child: Text(
                _segments.incipit,
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.4),
              ),
            ),
            const SizedBox(height: 12),
            // Prompt "...e poi?"
            Text(
              l10n.gameStoryPrompt,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.secondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            // TextField bounded (min 3 / max 6 righe). Non usiamo
            // expands:true perchè dentro SingleChildScrollView richiede
            // spazio illimitato → overflow se incipit lungo o tastiera
            // aperta.
            TextField(
              controller: _continuationController,
              minLines: 3,
              maxLines: 6,
              textInputAction: TextInputAction.newline,
              style: theme.textTheme.bodyLarge,
              decoration: InputDecoration(
                hintText: l10n.gameStoryContinueHint,
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
              onChanged: (v) => setState(() => _userContinuation = v),
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
                        : (_userContinuation.isEmpty
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
                    onPressed: _userContinuation.trim().isEmpty || isListening
                        ? null
                        : _sendContinuation,
                    label: Text(l10n.gameStorySendCta),
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
        // L'outer SingleChildScrollView (in _buildBody) gestisce gia'
        // lo scroll: non annidiamo un altro SingleChildScrollView.
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
              // Feedback caldo di Gemma.
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
              const SizedBox(height: 16),
              // Mostra il ricordo COMPLETO dopo il feedback: la persona
              // può rileggere come continua davvero. Coerente con
              // errorless: non punisce la sua continuazione, mostra la vera.
              Text(
                l10n.gameStoryFullMemoryLabel,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  target.text,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                icon: const Icon(Icons.refresh),
                onPressed: _newRound,
                label: Text(l10n.gameStoryAnotherCta),
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
              Icons.auto_stories_outlined,
              size: 48,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.gameStoryEmptyBody,
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
