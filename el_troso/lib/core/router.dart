// El Troso - Router go_router (Fase 4.4.d).
//
// Rotte:
//   /            → SplashPage (landing con tagline + "Comincia")
//   /onboarding  → OnboardingPage (stub in 4.4.d, reale in 4.4.g)
//   /home        → HomePage (stub in 4.4.d, reale in 4.5)
//   /playground  → PlaygroundPage (UI di test pulsanti 1-9, sempre attiva)
//
// Regola fondamentale: /playground deve restare raggiungibile dall'intero
// arco 4.x cosi' puoi continuare a lanciare i test V1/V2/RAG su Pixel 7a
// senza dover fare un revert del main.dart. Quando la UI utente e' pronta
// (Fase 4.6), si decide se tenere il playground dietro un long-press o se
// rimuoverlo del tutto dalla build di produzione.
//
// In 4.4.e aggiungiamo un redirect sulla rotta "/" che in base alla presenza
// del profilo in shared_preferences manda automaticamente a /home o a
// /onboarding (oggi sta sempre sulla splash statica).

import 'package:go_router/go_router.dart';

import 'package:el_troso/features/ask/ask_page.dart';
import 'package:el_troso/features/games/guess_page.dart';
import 'package:el_troso/features/games/photo_match_page.dart';
import 'package:el_troso/features/games/recognize_page.dart';
import 'package:el_troso/features/games/story_page.dart';
import 'package:el_troso/features/loading/model_loading_page.dart';
import 'package:el_troso/features/home/home_page.dart';
import 'package:el_troso/features/memory/memory_detail_page.dart';
import 'package:el_troso/features/memory/record_page.dart';
import 'package:el_troso/features/onboarding/onboarding_carousel_page.dart';
import 'package:el_troso/features/onboarding/onboarding_page.dart';
import 'package:el_troso/features/onboarding/onboarding_seed_offer_page.dart';
import 'package:el_troso/features/playground/playground_page.dart';
import 'package:el_troso/features/splash/splash_page.dart';

/// Costante singleton - non abbiamo state globale che richieda
/// di ricreare il router (i branch di navigazione dipendono da Riverpod
/// solo in 4.4.e, dove useremo refreshListenable). Per ora e' finalissimo.
final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'splash',
      builder: (context, state) => const SplashPage(),
    ),
    GoRoute(
      path: '/welcome',
      name: 'welcome',
      builder: (context, state) => const OnboardingCarouselPage(),
    ),
    GoRoute(
      path: '/onboarding',
      name: 'onboarding',
      builder: (context, state) => const OnboardingPage(),
    ),
    // build 24 — opt-in pre-load dei 12 ricordi seed (libro Giorgio).
    // Inserita tra /onboarding (form profilo) e /home: l'utente sceglie
    // se cominciare con i seed o partire da zero.
    GoRoute(
      path: '/onboarding/seed-offer',
      name: 'onboarding-seed-offer',
      builder: (context, state) => const OnboardingSeedOfferPage(),
    ),
    GoRoute(
      path: '/home',
      name: 'home',
      builder: (context, state) => const HomePage(),
    ),
    // 4.5.a - Racconto (nuovo ricordo). Da /home → "Racconto" CTA.
    GoRoute(
      path: '/record/new',
      name: 'record-new',
      builder: (context, state) => const RecordPage(),
    ),
    // 4.5.c - Dettaglio ricordo + Ripercorro TTS. Aperta sia dal tap sulla
    // lista ricordi in home, sia dal CTA "Ripercorro" (che passa l'id del
    // ricordo piu' recente).
    GoRoute(
      path: '/memory/:id',
      name: 'memory-detail',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return MemoryDetailPage(memoryId: id);
      },
    ),
    // 4.5.e - "Fai una domanda": RAG retrieve + Gemma prompt injection.
    // Route separata dalla home per poter navigare indietro con gesto
    // system back; il context.go('/home') nei CTA finali riporta su.
    GoRoute(
      path: '/ask',
      name: 'ask',
      builder: (context, state) => const AskPage(),
    ),
    // 4.5.i — G3 "Riconosci e racconta": foto random + STT + Gemma
    // confronto con ricordo originale + feedback caldo errorless.
    GoRoute(
      path: '/game/recognize',
      name: 'game-recognize',
      builder: (context, state) => const RecognizePage(),
    ),
    // 4.5.j — G1 "Memoria delle foto": memory matching con foto del
    // proprio archivio. Serious gaming visual recognition (JMIR 2024).
    GoRoute(
      path: '/game/photo-match',
      name: 'game-photo-match',
      builder: (context, state) => const PhotoMatchPage(),
    ),
    // build 37 — G2 "Indovina insieme": Gemma genera una domanda
    // specifica sul ricordo, l'utente risponde, Gemma valuta.
    // EBM: SRT (USMART 2017) + testing effect (Roediger & Karpicke 2006).
    GoRoute(
      path: '/game/guess',
      name: 'game-guess',
      builder: (context, state) => const GuessPage(),
    ),
    // build 37 — G5 "Storia continua": app legge le prime 2-3 frasi
    // del ricordo, l'utente continua, Gemma confronta. EBM:
    // narrative continuation in MCI (Cotelli 2012) + reminiscence
    // (Cochrane Woods 2018).
    GoRoute(
      path: '/game/story',
      name: 'game-story',
      builder: (context, state) => const StoryPage(),
    ),
    GoRoute(
      path: '/playground',
      name: 'playground',
      builder: (context, state) => const PlaygroundPage(),
    ),
    // 4.5.l — schermata di prep modello con loader animato del sentiero.
    // In MVP simula la copia (6s) per dimostrare visivamente il flow.
    // In produzione: copy reale rootBundle → external dir.
    GoRoute(
      path: '/loading-model',
      name: 'loading-model',
      builder: (context, state) => const ModelLoadingPage(),
    ),
    // 4.5.l — splash standalone in modalita' preview (debug only).
    // Mostra logo + loader senza il redirect automatico, cosi' Guido
    // puo' "ammirare" il branding senza rifare onboarding.
    GoRoute(
      path: '/splash-preview',
      name: 'splash-preview',
      builder: (context, state) => const SplashPage(previewMode: true),
    ),
  ],
);
