// El Troso - dettaglio ricordo + Ripercorro TTS (Fase 4.5.c → 4.5.f).
//
// Rotta: /memory/:id. Si apre in due casi:
//   1. Tap su un ricordo dalla MemoriesList nella home.
//   2. Tap sul CTA "Ripercorro" in home (che passa l'id del ricordo piu'
//      recente).
//
// Evoluzione 4.5.f:
//   - F9: prima di avviare il TTS, chip "chi sta ripercorrendo?" per
//     registrare il walker nel Walk.
//   - F12: ogni "Ripercorriamolo insieme" registra un Walk nel metadata
//     del ricordo (timestamp + walker), aggiornando il JSON su disco.
//     La lista walks alimenta l'indicatore di orme nella home.
//
// Stati interni della pagina:
//   - idle:    ricordo caricato, CTA primario "Ripercorriamolo insieme".
//   - picking: l'utente sta scegliendo chi ripercorre (walker chip).
//   - walking: TTS sta leggendo. CTA secondario "Fermati", label a schermo.
//   - done:    TTS ha finito o e' stato interrotto. Label di chiusura
//              (walkDoneLabel) + CTA "Torna al sentiero".

import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:el_troso/core/fullscreen_photo_view.dart';
import 'package:el_troso/core/locale/locale_codes.dart';
import 'package:el_troso/core/version.dart';
import 'package:el_troso/core/voice/tts_provider.dart';
import 'package:el_troso/features/ask/gemma_providers.dart';
import 'package:el_troso/features/memory/memory.dart';
import 'package:el_troso/features/memory/memory_providers.dart';
import 'package:el_troso/features/memory/vector_store_provider.dart';
import 'package:el_troso/features/profile/profile_providers.dart';
import 'package:el_troso/l10n/app_localizations.dart';

enum _WalkPhase { idle, picking, walking, done }

class MemoryDetailPage extends ConsumerStatefulWidget {
  const MemoryDetailPage({super.key, required this.memoryId});

  final String memoryId;

  @override
  ConsumerState<MemoryDetailPage> createState() => _MemoryDetailPageState();
}

class _MemoryDetailPageState extends ConsumerState<MemoryDetailPage> {
  _WalkPhase _phase = _WalkPhase.idle;
  String _walkWalker = 'self'; // chi sta ripercorrendo
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Build 42 — traduzione on-demand. Stato locale: niente persistenza,
  // sparisce uscendo dalla pagina (coerente con A "lazy lookup").
  String? _translation;          // testo tradotto, se disponibile
  String? _translationToLang;    // lingua di destinazione (per cui è valida)
  bool _translating = false;     // spinner attivo
  String? _translationError;     // messaggio se fallita

  @override
  void dispose() {
    _audioPlayer.dispose();
    if (_phase == _WalkPhase.walking) {
      debugPrint('[memory_detail] dispose during walking → stop');
      // ignore: discarded_futures
      ref.read(ttsServiceProvider).stop();
    }
    super.dispose();
  }

  void _showWalkerPicker() {
    setState(() => _phase = _WalkPhase.picking);
  }

  Future<void> _startWalk(Memory m) async {
    setState(() => _phase = _WalkPhase.walking);
    debugPrint(
      '[memory_detail] start walk id=${m.id} walker=$_walkWalker '
      'len=${m.text.length}',
    );

    // F12: registra il walk nel metadata PRIMA di avviare il TTS, cosi'
    // anche se l'utente interrompe a meta' il calpestio e' gia' registrato.
    final walk = Walk(
      walkedAt: DateTime.now().toUtc(),
      walker: _walkWalker,
    );
    final updated = m.copyWith(walks: [walk, ...m.walks]);
    await ref.read(memoriesProvider.notifier).updateMemory(updated);
    debugPrint('[memory_detail] walk recorded (total=${updated.walks.length})');

    // Playback: se il ricordo ha audio originale, usa quello (voce vera).
    // Altrimenti fallback a TTS (voce sintetica).
    try {
      if (m.audioPath != null && await File(m.audioPath!).exists()) {
        debugPrint('[memory_detail] playing original audio: ${m.audioPath}');
        _audioPlayer.onPlayerComplete.listen((_) {
          if (!mounted) return;
          debugPrint('[memory_detail] audio playback complete');
          setState(() => _phase = _WalkPhase.done);
        });
        await _audioPlayer.play(DeviceFileSource(m.audioPath!));
        return; // onPlayerComplete gestisce il passaggio a done.
      } else {
        // Build 42: leggi nel TTS della lingua originale del ricordo
        // (non della UI). Un ricordo IT letto da un TTS EN suona
        // tragicamente sbagliato; meglio sempre rispettare la lingua
        // in cui il ricordo è stato registrato.
        await ref.read(ttsServiceProvider).speak(
              m.text,
              lang: ttsLanguageCodeFromIso(m.originalLang),
            );
      }
    } catch (e) {
      debugPrint('[memory_detail] playback error: $e');
    }
    if (!mounted) return;
    debugPrint('[memory_detail] walk complete (natural or stopped)');
    setState(() => _phase = _WalkPhase.done);
  }

  Future<void> _stopWalk() async {
    debugPrint('[memory_detail] user tapped stop');
    await ref.read(ttsServiceProvider).stop();
    await _audioPlayer.stop();
    if (!mounted) return;
    if (_phase == _WalkPhase.walking) {
      setState(() => _phase = _WalkPhase.done);
    }
  }

  /// Build 42 — traduce on-demand il testo del ricordo nella lingua UI.
  /// Niente persistenza: lo stato vive solo finché l'utente sta sulla
  /// pagina. Tornando, ritradurrà se serve.
  Future<void> _translate(Memory m) async {
    final targetLang = Localizations.localeOf(context).languageCode;
    if (targetLang == m.originalLang) return; // niente da fare
    setState(() {
      _translating = true;
      _translationError = null;
      _translation = null;
      _translationToLang = targetLang;
    });
    try {
      final out = await ref.read(gemmaServiceProvider).translate(
            m.text,
            fromLang: m.originalLang,
            toLang: targetLang,
          );
      if (!mounted) return;
      setState(() {
        _translation = out;
        _translating = false;
      });
    } catch (e, st) {
      debugPrint('[memory_detail] translate failed: $e\n$st');
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      setState(() {
        _translating = false;
        _translationError = l10n.memoryTranslateError;
      });
    }
  }

  Future<void> _deleteMemory(Memory m) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.memoryDeleteTitle),
        content: Text(l10n.memoryDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.memoryDeleteCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              l10n.memoryDeleteConfirm,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await ref.read(memoriesProvider.notifier).delete(m.id);
    debugPrint('[memory_detail] deleted ${m.id}');
    if (!mounted) return;
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final async = ref.watch(memoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.memoryDetailTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        actions: [
          // Pulsante elimina: solo se non stiamo ripercorrendo.
          if (_phase == _WalkPhase.idle || _phase == _WalkPhase.done)
            Builder(
              builder: (context) {
                final async2 = ref.watch(memoriesProvider);
                final m = async2.valueOrNull
                    ?.where((x) => x.id == widget.memoryId)
                    .firstOrNull;
                if (m == null) return const SizedBox.shrink();
                return IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: l10n.memoryDeleteTitle,
                  onPressed: () => _deleteMemory(m),
                );
              },
            ),
          const VersionBadge(),
        ],
      ),
      body: SafeArea(
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _NotFoundBody(
            message: l10n.memoriesLoadError,
            backCta: l10n.walkBackHomeCta,
          ),
          data: (list) {
            Memory? found;
            for (final x in list) {
              if (x.id == widget.memoryId) {
                found = x;
                break;
              }
            }
            if (found == null) {
              return _NotFoundBody(
                message: l10n.memoryDetailNotFound,
                backCta: l10n.walkBackHomeCta,
              );
            }
            final m = found;
            // Build 42: il bottone "Traduci" appare solo se l'originalLang
            // del ricordo è diverso dalla locale UI corrente. Se la
            // traduzione mostrata è per una lingua diversa da quella
            // attuale (es. user ha cambiato lingua dopo aver tradotto),
            // la consideriamo stale e mostriamo solo il bottone.
            final currentLang = Localizations.localeOf(context).languageCode;
            final canTranslate = m.originalLang != currentLang;
            final activeTranslation = (_translation != null &&
                    _translationToLang == currentLang)
                ? _translation
                : null;
            return _Body(
              memory: m,
              phase: _phase,
              walkWalker: _walkWalker,
              theme: theme,
              l10n: l10n,
              profileName: ref.read(profileProvider)?.name ?? '...',
              onWalkerChanged: (w) => setState(() => _walkWalker = w),
              onShowPicker: _showWalkerPicker,
              onStart: () => _startWalk(m),
              onStop: _stopWalk,
              onBackHome: () => context.go('/home'),
              canTranslate: canTranslate,
              translation: activeTranslation,
              translating: _translating,
              translationError: _translationError,
              onTranslate: () => _translate(m),
            );
          },
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.memory,
    required this.phase,
    required this.walkWalker,
    required this.theme,
    required this.l10n,
    required this.profileName,
    required this.onWalkerChanged,
    required this.onShowPicker,
    required this.onStart,
    required this.onStop,
    required this.onBackHome,
    required this.canTranslate,
    required this.translation,
    required this.translating,
    required this.translationError,
    required this.onTranslate,
  });

  final Memory memory;
  final _WalkPhase phase;
  final String walkWalker;
  final ThemeData theme;
  final AppLocalizations l10n;
  final String profileName;
  final ValueChanged<String> onWalkerChanged;
  final VoidCallback onShowPicker;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onBackHome;
  // Build 42 — traduzione on-demand.
  final bool canTranslate;       // mostrare il bottone? (lingue diverse)
  final String? translation;     // testo tradotto, null se non ancora
  final bool translating;        // spinner attivo
  final String? translationError;// errore, null se ok
  final VoidCallback onTranslate;

  @override
  Widget build(BuildContext context) {
    final absoluteDate = _formatAbsoluteDate(memory.createdAt, l10n.localeName);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Data assoluta + tag + walker originale.
          Row(
            children: [
              Text(
                absoluteDate,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (memory.tag != null) ...[
                const SizedBox(width: 8),
                Chip(
                  label: Text(
                    _tagLabel(memory.tag!, l10n),
                    style: theme.textTheme.labelSmall,
                  ),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ],
          ),
          if (memory.walks.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '${memory.walks.length}× ${l10n.walkCtaLabel.toLowerCase()}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 16),

          // Immagine allegata (se presente).
          // Nel dettaglio del ricordo la foto è IL contenuto, non una
          // miniatura: usiamo BoxFit.contain con altezza un po' più
          // generosa (260) e sfondo crema dietro, così foto verticali e
          // orizzontali si vedono per intero senza tagliare i volti.
          // Tap → fullscreen viewer con pinch-zoom.
          if (memory.imagePath != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: GestureDetector(
                onTap: () => FullscreenPhotoView.open(
                  context,
                  imagePath: memory.imagePath!,
                  heroTag: 'photo-${memory.id}',
                ),
                child: Container(
                  width: double.infinity,
                  height: 260,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Hero(
                      tag: 'photo-${memory.id}',
                      child: Image.file(
                        File(memory.imagePath!),
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Corpo del ricordo + (build 42) sezione Traduci sotto.
          // Scrollabile per ricordi lunghi e per dare spazio alla
          // traduzione quando aperta.
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SelectableText(
                    memory.text,
                    style: theme.textTheme.bodyLarge,
                  ),
                  if (canTranslate) ...[
                    const SizedBox(height: 16),
                    _TranslateSection(
                      theme: theme,
                      l10n: l10n,
                      translation: translation,
                      translating: translating,
                      error: translationError,
                      onTranslate: onTranslate,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Zona stato + CTA, variabile in base alla fase.
          if (phase == _WalkPhase.picking) ...[
            Text(
              l10n.walkerChipWalkQ,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _walkerChip('self', profileName),
                _walkerChip('child', l10n.walkerChild),
                _walkerChip('grandchild', l10n.walkerGrandchild),
                _walkerChip('friend', l10n.walkerFriend),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onStart,
              child: Text(l10n.walkCtaLabel),
            ),
          ],
          if (phase == _WalkPhase.walking)
            Text(
              l10n.walkInProgressLabel,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          if (phase == _WalkPhase.done)
            Text(
              l10n.walkDoneLabel,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          if (phase != _WalkPhase.picking) const SizedBox(height: 16),

          // CTA principale.
          if (phase == _WalkPhase.idle)
            FilledButton(
              onPressed: onShowPicker,
              child: Text(l10n.walkCtaLabel),
            ),
          if (phase == _WalkPhase.walking)
            OutlinedButton(
              onPressed: onStop,
              child: Text(l10n.walkStopCta),
            ),
          if (phase == _WalkPhase.done)
            FilledButton(
              onPressed: onBackHome,
              child: Text(l10n.walkBackHomeCta),
            ),
        ],
      ),
    );
  }

  Widget _walkerChip(String value, String label) {
    return ChoiceChip(
      label: Text(label),
      selected: walkWalker == value,
      onSelected: (sel) {
        if (sel) onWalkerChanged(value);
      },
    );
  }

  static String _tagLabel(String tag, AppLocalizations l10n) {
    switch (tag) {
      case 'family':
        return l10n.tagFamily;
      case 'work':
        return l10n.tagWork;
      case 'travel':
        return l10n.tagTravel;
      case 'home':
        return l10n.tagHome;
      default:
        return l10n.tagOther;
    }
  }

  static String _formatAbsoluteDate(DateTime createdAt, String localeName) {
    final local = createdAt.toLocal();
    final fmt = DateFormat('EEEE d MMMM y', localeName);
    return fmt.format(local);
  }
}

/// Build 42 — sezione "Traduci" sotto al testo del ricordo.
/// Tre stati visibili:
///   - inattiva: bottone outlined "Traduci" (o "Traduci di nuovo")
///   - in corso: spinner + label "Sto traducendo…"
///   - errore:  testo errore + bottone retry
///   - tradotta: card con label "Traduzione" + testo + bottone re-translate
class _TranslateSection extends StatelessWidget {
  const _TranslateSection({
    required this.theme,
    required this.l10n,
    required this.translation,
    required this.translating,
    required this.error,
    required this.onTranslate,
  });

  final ThemeData theme;
  final AppLocalizations l10n;
  final String? translation;
  final bool translating;
  final String? error;
  final VoidCallback onTranslate;

  @override
  Widget build(BuildContext context) {
    if (translating) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Text(
              l10n.memoryTranslating,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    if (error != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            error!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.translate),
            onPressed: onTranslate,
            label: Text(l10n.memoryTranslateCta),
          ),
        ],
      );
    }

    if (translation != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outlineVariant,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.translate,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  l10n.memoryTranslationLabel,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SelectableText(
              translation!,
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.4),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              icon: const Icon(Icons.refresh, size: 18),
              onPressed: onTranslate,
              label: Text(l10n.memoryTranslateRedoCta),
              style: TextButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      );
    }

    // Stato iniziale: bottone outlined.
    return Align(
      alignment: Alignment.centerLeft,
      child: OutlinedButton.icon(
        icon: const Icon(Icons.translate),
        onPressed: onTranslate,
        label: Text(l10n.memoryTranslateCta),
      ),
    );
  }
}

class _NotFoundBody extends StatelessWidget {
  const _NotFoundBody({required this.message, required this.backCta});

  final String message;
  final String backCta;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => context.go('/home'),
            child: Text(backCta),
          ),
        ],
      ),
    );
  }
}
